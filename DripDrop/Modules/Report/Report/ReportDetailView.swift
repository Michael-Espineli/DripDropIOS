import SwiftUI
import Charts

// Retained for legacy ReportViewModel callers.
enum oneReportType: String, CaseIterable { case detail = "Detail", summary = "Summary" }
enum induvidualReportDisplay: String, CaseIterable { case customer = "Customer", company = "Company", user = "User" }

struct ReportDetailView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var model = BooksViewModel()
    @State private var controls = BooksControls()
    @State private var showSaved = false
    @State private var showSave = false
    @State private var savedId: String?
    @State private var savedTitle = ""
    @State private var savedSubtitle = ""
    @State private var expandedSections = Set<Int>()
    @State private var copyPerformanceNotesToCustomers = false
    @State private var pendingDelete: BooksSavedReport?
    init(dataService: any ProductionDataServiceProtocol) {}

    private var selectedReport: ReportType { masterDataManager.selectedReport ?? .readings }
    private var regional: Bool { masterDataManager.featureFlagsLoaded && (masterDataManager.featureFlags["feature_flag_014"]?.enabled == true) }
    private var sessionKey: String { "\(masterDataManager.currentCompany?.id ?? ""):\(masterDataManager.user?.id ?? ""):\(masterDataManager.currentCompany?.ownerId ?? "")" }
    private var allowedReports: [ReportType] { ReportType.allCases.filter { !$0.requiresPayroll || model.can("420") } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkspaceIdentityHeader(title: "Reports", eyebrow: "BOOKS", subtitle: "Operations, marketing, performance and finance reporting.")
                if !model.ready {
                    if let error = model.error { Text(error).foregroundStyle(.red) }
                    else { ProgressView("Loading report access…") }
                } else if !model.can("870") {
                    Text("Report information permission (870) is required.").foregroundStyle(.secondary)
                } else {
                    reportControls
                    if let error = model.error {
                        Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red).accessibilityLabel("Report error: \(error)")
                    }
                    if let notice = model.notice { Text(notice).foregroundStyle(.green) }
                    if model.loading { ProgressView("Generating report…").frame(maxWidth: .infinity) }
                    if let report = model.report { results(report) }
                    else if !model.loading { Text("Choose the controls, then generate a report.").foregroundStyle(.secondary).padding(.vertical) }
                }
            }.padding(16)
        }
        .background(Color.listColor)
        .navigationTitle(selectedReport.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: sessionKey) {
            guard let company = masterDataManager.currentCompany, let user = masterDataManager.user else { model.stop(); return }
            model.start(companyId: company.id, userId: user.id, owner: company.ownerId == user.id)
        }
        .task(id: model.accessRevision) {
            await model.loadControls(type: selectedReport, regional: regional)
            applyTemplateDefaults()
        }
        .onChange(of: selectedReport) { _, report in
            if savedId == nil || controls.reportType != report.webKey {
                controls.reportType = report.webKey; savedId = nil; savedTitle = ""
            }
            model.invalidate()
            Task { await model.loadControls(type: report, regional: regional); applyTemplateDefaults() }
        }
        .onChange(of: controls) { _, _ in model.invalidate(); expandedSections = [] }
        .onChange(of: regional) { _, _ in model.invalidate(); Task { await model.loadControls(type: selectedReport, regional: regional) } }
        .onChange(of: model.accessRevision) { _, _ in
            controls.selectedCustomerTags = []; savedId = nil
            if selectedReport.requiresPayroll && !model.can("420") { masterDataManager.selectedReport = .readings }
        }
        .onAppear { controls.reportType = selectedReport.webKey }
        .onDisappear { model.stop() }
        .sheet(isPresented: $showSaved) { savedSheet }
        .sheet(isPresented: $showSave) { saveSheet }
        .confirmationDialog("Delete this saved report?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
            Button("Delete Saved Report", role: .destructive) { if let pendingDelete { Task { await model.delete(pendingDelete) } }; pendingDelete = nil }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
    }

    private var reportControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Report", selection: Binding(get: { selectedReport }, set: { masterDataManager.selectedReport = $0 })) {
                ForEach(allowedReports) { Text($0.title).tag($0) }
            }.pickerStyle(.menu)
            Text(selectedReport.source).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if !savedTitle.isEmpty { Label(savedTitle, systemImage: "bookmark.fill").font(.subheadline.bold()) }
            Picker("Output", selection: $controls.mode) { Text("Summary").tag("summary"); Text("Detail").tag("detail") }.pickerStyle(.segmented)
            if !selectedReport.hasFixedGrouping {
                Picker("Group By", selection: $controls.groupBy) {
                    Text("Company").tag("company"); Text("User").tag("user"); Text("Customer").tag("customer")
                }.pickerStyle(.menu)
            }
            Picker("Date Range", selection: Binding(get: { controls.quickDateRange }, set: { key in
                controls.quickDateRange = key; if key != "custom" { controls.dateRange = .preset(key) }
            })) {
                Text("Custom").tag("custom"); Text("This Month").tag("thisMonth"); Text("Last Month").tag("lastMonth")
                Text("Last 7 Days").tag("last7Days"); Text("Last 30 Days").tag("last30Days")
                Text("This Week").tag("thisWeek"); Text("Last Week").tag("lastWeek")
            }
            DatePicker("Start Date", selection: dateBinding(start: true), displayedComponents: .date)
            DatePicker("End Date", selection: dateBinding(start: false), displayedComponents: .date)
            if !model.customerTags.isEmpty {
                Menu {
                    Button("All permitted customers") { controls.selectedCustomerTags = [] }
                    ForEach(model.customerTags, id: \.self) { tag in
                        Button { if controls.selectedCustomerTags.contains(tag) { controls.selectedCustomerTags.removeAll { $0 == tag } }
                            else { controls.selectedCustomerTags.append(tag) }
                        } label: { Label(tag, systemImage: controls.selectedCustomerTags.contains(tag) ? "checkmark.circle.fill" : "circle") }
                    }
                } label: { Label(controls.selectedCustomerTags.isEmpty ? "Customer Tags: All permitted" : controls.selectedCustomerTags.joined(separator: ", "), systemImage: "tag") }
            }
            if selectedReport == .readingHealth { readingRule($controls.readingHealthFilters) }
            if selectedReport == .readingPerformance {
                Picker("Performance By", selection: $controls.readingPerformanceView) { Text("User").tag("users"); Text("Customer").tag("customers") }.pickerStyle(.segmented)
                Text("Good standing standards").font(.headline)
                ForEach($controls.readingPerformanceStandards) { $rule in
                    VStack(alignment: .leading, spacing: 8) {
                        readingRule($rule)
                        Button("Remove Standard", role: .destructive) { controls.readingPerformanceStandards.removeAll { $0.id == rule.id } }
                    }.padding(10).background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
                Button("Add Standard", systemImage: "plus") {
                    var rule = BooksReadingRule(); rule.templateId = model.templates.first?["id"] as? String ?? ""; controls.readingPerformanceStandards.append(rule)
                }
            }
            Button { Task { await model.generate(controls: controls, regional: regional) } } label: {
                Label(model.loading ? "Generating…" : "Generate Report", systemImage: "play.fill").frame(maxWidth: .infinity)
            }.buttonStyle(WorkspaceOutlinedButtonStyle(tone: .emerald)).disabled(model.loading || !model.can("870") || !masterDataManager.featureFlagsLoaded)
            HStack {
                Button("Saved Reports", systemImage: "bookmark") { showSaved = true; Task { await model.loadSaved() } }
                Spacer()
                if model.can(savedId == nil ? "872" : "874") { Button("Save Controls", systemImage: "square.and.arrow.down") { showSave = true } }
            }.font(.subheadline)
        }.padding(14).background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
    private func dateBinding(start: Bool) -> Binding<Date> {
        Binding(get: { BooksDateRange.date(start ? controls.dateRange.start : controls.dateRange.end) }, set: { date in
            controls.quickDateRange = "custom"
            if start { controls.dateRange.start = BooksDateRange.string(date) } else { controls.dateRange.end = BooksDateRange.string(date) }
        })
    }
    private func readingRule(_ rule: Binding<BooksReadingRule>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Reading", selection: rule.templateId) {
                Text("Select Reading").tag("")
                ForEach(model.templates.indices, id: \.self) { index in
                    let template = model.templates[index]
                    Text([template["name"] as? String ?? template["chemType"] as? String ?? "Reading", template["UOM"] as? String ?? ""].filter { !$0.isEmpty }.joined(separator: " "))
                        .tag(template["id"] as? String ?? "")
                }
            }
            Picker("Comparison", selection: rule.operator) {
                Text("Over").tag("gt"); Text("At or over").tag("gte"); Text("Below").tag("lt"); Text("At or below").tag("lte"); Text("Equal to").tag("eq")
            }
            TextField("Numeric threshold", text: rule.threshold).keyboardType(.numbersAndPunctuation).textFieldStyle(.roundedBorder)
        }
    }
    private func applyTemplateDefaults() {
        guard let template = model.templates.first else { return }
        let id = template["id"] as? String ?? ""
        if !model.templates.contains(where: { $0["id"] as? String == controls.readingHealthFilters.templateId }) {
            var rule = BooksReadingRule(); rule.templateId = id
            if let value = template["highWarning"] { rule.threshold = String(describing: value) }
            else if let value = template["lowWarning"] { rule.operator = "lt"; rule.threshold = String(describing: value) }
            controls.readingHealthFilters = rule
        }
        if controls.readingPerformanceStandards.isEmpty { controls.readingPerformanceStandards = [controls.readingHealthFilters] }
    }
    private func results(_ report: BooksReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(report.title).font(.title2.bold())
            Text(report.description).font(.subheadline).foregroundStyle(.secondary)
            ForEach(report.warnings, id: \.self) { warning in Label(warning, systemImage: "exclamationmark.triangle").font(.subheadline).foregroundStyle(.orange) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], alignment: .leading, spacing: 10) {
                ForEach(Array(report.stats.enumerated()), id: \.offset) { _, metric in metricCard(metric) }
                if let total = report.total { metricCard(total) }
            }
            HStack {
                Menu("Export", systemImage: "square.and.arrow.up") {
                    Button("CSV") { model.export("csv") }; Button("Excel") { model.export("xlsx") }; Button("PDF") { model.export("pdf") }
                }
                if let url = model.exportURL { ShareLink(item: url) { Label("Share File", systemImage: "square.and.arrow.up") } }
                Spacer()
                Button(expandedSections.isEmpty ? "Expand All" : "Collapse All") { expandedSections = expandedSections.isEmpty ? Set(report.sections.indices) : [] }
            }.font(.subheadline)
            if !report.individualUsers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Individual Users").font(.headline)
                    if model.can("274") && masterDataManager.isFeatureEnabled(.managementTechnicianPerformanceHistory) {
                        Toggle("Copy referenced customers to Customer Notes", isOn: $copyPerformanceNotesToCustomers).disabled(!model.can("12") || model.savingPerformanceNote)
                    }
                    ForEach(report.individualUsers) { user in
                        HStack(alignment: .top) {
                            Text(user.name).font(.subheadline.bold()); Spacer()
                            Menu("Export") {
                                Button("CSV") { model.export("csv", groupId: user.id) }
                                Button("Excel") { model.export("xlsx", groupId: user.id) }
                                Button("PDF") { model.export("pdf", groupId: user.id) }
                            }
                            if model.can("274") && masterDataManager.isFeatureEnabled(.managementTechnicianPerformanceHistory) && !user.companyUserId.isEmpty {
                                Button("Attach to History") {
                                    Task { await model.createPerformanceNote(user: user, copyToCustomers: copyPerformanceNotesToCustomers && model.can("12"),
                                        actorId: masterDataManager.user?.id ?? "", actorName: [masterDataManager.user?.firstName ?? "", masterDataManager.user?.lastName ?? ""].filter { !$0.isEmpty }.joined(separator: " ")) }
                                }.disabled(model.savingPerformanceNote)
                            }
                        }.font(.subheadline)
                    }
                }.padding(12).background(.background, in: RoundedRectangle(cornerRadius: 8))
            }
            ForEach(Array(report.chartSections.enumerated()), id: \.offset) { _, section in
                if !section.items.isEmpty {
                    Text(section.title).font(.headline)
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        if !item.chartPoints.isEmpty {
                            VStack(alignment: .leading) {
                                Text([item.name, item.unit ?? ""].joined(separator: " ")).font(.subheadline.bold())
                                Chart(Array(item.chartPoints.enumerated()), id: \.offset) { _, point in
                                    LineMark(x: .value("Date", BooksDateRange.date(String(point.date.prefix(10)))), y: .value("Average", point.average))
                                }.frame(height: 180).accessibilityLabel("Daily average for \(item.name)")
                            }.padding(12).background(.background, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            if report.sections.isEmpty { Text("No records match these dates and filters.").foregroundStyle(.secondary) }
            ForEach(report.sections.indices, id: \.self) { index in
                let section = report.sections[index]
                DisclosureGroup(isExpanded: Binding(get: { expandedSections.contains(index) }, set: { if $0 { expandedSections.insert(index) } else { expandedSections.remove(index) } })) {
                    if section.rows.isEmpty { Text("No rows in this group.").foregroundStyle(.secondary) }
                    ForEach(section.rows.indices, id: \.self) { rowIndex in
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(section.columns.indices, id: \.self) { columnIndex in
                                HStack(alignment: .top) {
                                    Text(section.columns[columnIndex].label).foregroundStyle(.secondary)
                                    Spacer(minLength: 12)
                                    Text(section.rows[rowIndex].indices.contains(columnIndex) ? section.rows[rowIndex][columnIndex] : "").multilineTextAlignment(.trailing).textSelection(.enabled)
                                }.font(.subheadline)
                            }
                        }.padding(.vertical, 10)
                        Divider()
                    }
                } label: { Text("\(section.title) (\(section.rows.count))").font(.headline) }
                .padding(12).background(.background, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    private func metricCard(_ metric: BooksReport.Metric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.label).font(.caption).foregroundStyle(.secondary)
            Text(metric.value).font(.headline).textSelection(.enabled)
            if let subtitle = metric.subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
    private var savedSheet: some View {
        NavigationStack {
            List {
                if let error = model.error { Text(error).foregroundStyle(.red) }
                if model.saved.isEmpty { Text("No saved reports.").foregroundStyle(.secondary) }
                ForEach(model.saved) { saved in
                    Button { loadSaved(saved) } label: {
                        VStack(alignment: .leading, spacing: 4) { Text(saved.title).font(.headline); Text(saved.subtitle).font(.caption).foregroundStyle(.secondary) }
                    }.swipeActions {
                        if model.can("876") { Button("Delete", role: .destructive) { pendingDelete = saved }.disabled(model.busySaving) }
                    }
                }
            }.navigationTitle("Saved Reports")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showSaved = false } } }
        }
    }
    private func loadSaved(_ saved: BooksSavedReport) {
        do {
            var data = try JSONSerialization.jsonObject(with: JSONEncoder().encode(BooksControls())) as! [String: Any]
            data.merge(saved.controls) { _, new in new }
            if var rules = data["readingPerformanceStandards"] as? [[String: Any]] {
                for index in rules.indices where rules[index]["id"] == nil { rules[index]["id"] = UUID().uuidString }
                data["readingPerformanceStandards"] = rules
            }
            if var rule = data["readingHealthFilters"] as? [String: Any] { rule["id"] = rule["id"] ?? UUID().uuidString; data["readingHealthFilters"] = rule }
            var decoded = try JSONDecoder().decode(BooksControls.self, from: JSONSerialization.data(withJSONObject: data))
            guard let report = ReportType.allCases.first(where: { $0.webKey == decoded.reportType }), !report.requiresPayroll || model.can("420") else { return }
            if decoded.quickDateRange != "custom" { decoded.dateRange = .preset(decoded.quickDateRange) }
            controls = decoded; savedId = saved.id; savedTitle = saved.title; savedSubtitle = saved.subtitle
            masterDataManager.selectedReport = report
            showSaved = false
        } catch { model.error = error.localizedDescription }
    }
    private var saveSheet: some View {
        NavigationStack {
            Form {
                TextField("Report title", text: $savedTitle)
                TextField("Description", text: $savedSubtitle, axis: .vertical)
                Text("Saves the current controls. Relative date ranges update when opened.").font(.caption).foregroundStyle(.secondary)
                if let error = model.error { Text(error).foregroundStyle(.red) }
            }.navigationTitle(savedId == nil ? "Save Report" : "Update Saved Report")
                .interactiveDismissDisabled(model.busySaving)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showSave = false }.disabled(model.busySaving) }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(model.busySaving ? "Saving…" : "Save") {
                            Task { if await model.save(controls: controls, title: savedTitle, subtitle: savedSubtitle, existingId: savedId, userId: masterDataManager.user?.id ?? "") { savedId = model.lastSavedReportId; showSave = false } }
                        }.disabled(model.busySaving || savedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}
