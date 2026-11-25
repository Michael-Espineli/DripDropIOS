//
//  CompanyPayrollAdminHomeView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//


import SwiftUI
import UniformTypeIdentifiers

struct CompanyPayrollAdminHomeView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

//    let companyId: String
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        List {
                setupSection
                payrollSection
            futureSetupSection
        }
        .navigationTitle("Payroll")
         
    }

    private var setupSection: some View {
        Section("Setup") {
            if let company = masterDataManager.currentCompany {
                if masterDataManager.isFeatureEnabled(.employeePayroll) {
                    NavigationLink {
                        EmployeePayrollPeriodsView(companyId: company.id, setup: true)
                    } label: {
                        PayrollAdminNavRow(iconName: "calendar.badge.clock", title: "Employee Pay and Automation",
                                           subtitle: "Hourly and piece-rate pay, workflow, and frequency")
                    }
                }
                NavigationLink {
                    CompanyPaySettingsView(
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "gearshape",
                        title: "Pay Settings",
                        subtitle: "Company payroll rules, hourly settings, and approval behavior"
                    )
                }
                NavigationLink {
                    CompanyWorkTypesView(
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "list.bullet.rectangle",
                        title: "Pay Types",
                        subtitle: "Group pay types by route, job, estimate, and relationship buckets"
                    )
                }
                if let user = masterDataManager.user {
                    NavigationLink {
                        TechnicianRateMatrixView(
                            currentUserId: user.id,
                            dataService: dataService
                        )
                    } label: {
                        PayrollAdminNavRow(
                            iconName: "tablecells",
                            title: "Technician Rate Matrix",
                            subtitle: "Set each technician's rate for each pay type"
                        )
                    }
                }
            }
        }
    }

    private var payrollSection: some View {
        Section("Payroll") {
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                if masterDataManager.isFeatureEnabled(.employeePayroll) {
                    NavigationLink {
                        EmployeePayrollPeriodsView(companyId: currentCompany.id, setup: false)
                    } label: {
                        PayrollAdminNavRow(iconName: "calendar", title: "Payroll Periods",
                                           subtitle: "Prepare, review, export, and record external payment")
                    }
                }
                NavigationLink {
                    CompanyPayrollReviewQueueView(
                        companyId: currentCompany.id,
                        currentUserId: user.id,
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "checklist",
                        title: "Payroll Review Queue",
                        subtitle: "Review outstanding, approved, and paid line items"
                    )
                }
                NavigationLink {
                    CompanyPayStatementsView(
                        companyId: currentCompany.id,
                        currentUserId: user.id,
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "doc.text",
                        title: "Pay Statements",
                        subtitle: "Create contractor invoices and employee pay summaries"
                    )
                }
            }
        }
    }

    private var futureSetupSection: some View {
        Section("Reports & Exports") {
            if let currentCompany = masterDataManager.currentCompany {
                NavigationLink {
                    PayrollRateHistoryView(
                        companyId: currentCompany.id,
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "clock.arrow.circlepath",
                        title: "Rate History",
                        subtitle: "Track technician pay increases over time"
                    )
                }

                if let user = masterDataManager.user {
                    NavigationLink {
                        PayrollExportsView(
                            companyId: currentCompany.id,
                            currentUserId: user.id,
                            dataService: dataService
                        )
                    } label: {
                        PayrollAdminNavRow(
                            iconName: "square.and.arrow.up",
                            title: "Payroll Exports",
                            subtitle: "CSV, QuickBooks, and payroll-provider exports"
                        )
                    }
                }
            } else {
                PayrollAdminNavRow(
                    iconName: "exclamationmark.triangle",
                    title: "Missing Company",
                    subtitle: "Select a company before viewing payroll reports."
                )
            }
        }
    }
}

struct PayrollAdminNavRow: View {
    var iconName: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PayrollComingSoonView: View {
    var title: String
    var message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hammer",
            description: Text(message)
        )
        .navigationTitle(title)
    }
}

private struct EmployeePayrollPeriodsView: View {
    struct Settings: Decodable {
        var mode: String
        var frequency: String
        var startDay: String
        var timeZone: String
        var revision: Int
        var employeeDefault: String
        var employeeOverrides: [String: String]
    }

    struct Employee: Decodable, Identifiable { let id: String; let name: String }
    struct Period: Decodable, Identifiable {
        let id: String
        let startDay: String
        let endDay: String
        let mode: String
        let status: String
        let totalCents: Int
        let workerCount: Int
        let problems: [String]
        let fingerprint: String?
        let paymentReference: String?
        let paidDay: String?
        let timeZone: String
        let exportedAt: Int64?
        let exportState: String?
        let workers: [Worker]?
        var title: String { "\(startDay) to \(endDay)" }
        var statusLabel: String {
            switch status {
            case "reviewRequired": "Ready for review"
            case "needsReview": "Needs attention"
            case "readyForExport": "Ready for export"
            case "recordingPayment": "Recording external payment"
            case "paidExternally": "Paid externally"
            default: status
            }
        }
    }

    struct Worker: Decodable, Identifiable {
        let id: String
        let name: String
        let workerType: String
        let totalCents: Int
        let excludedCents: Int
        let timeMs: Double
        let reviewCount: Int
        let daily: [Day]
    }

    struct Day: Decodable, Identifiable {
        var id: String { day }
        let day: String
        let workedMs: Double
        let paidBreakMs: Double
        let unpaidBreakMs: Double
        let hourlyCents: Int
        let pieceCents: Int
        let otherCents: Int
    }

    struct PayrollCSV: FileDocument {
        static var readableContentTypes: [UTType] { [.commaSeparatedText] }
        var text: String
        init(text: String) { self.text = text }
        init(configuration: ReadConfiguration) throws {
            text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
        }
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            FileWrapper(regularFileWithContents: Data(text.utf8))
        }
    }

    private struct Loaded: Decodable {
        let settings: Settings
        let employees: [Employee]
        let runs: [Period]
        let today: String
        let nextPeriodCursor: String?
    }

    private struct OlderPeriods: Decodable {
        let runs: [Period]
        let nextPeriodCursor: String?
    }

    let companyId: String
    let setup: Bool
    @State private var settings: Settings?
    @State private var employees: [Employee] = []
    @State private var periods: [Period] = []
    @State private var nextPeriodCursor: String?
    @State private var today = ""
    @State private var start = ""
    @State private var end = ""
    @State private var detail: Period?
    @State private var reference = ""
    @State private var paidDay = ""
    @State private var busy = false
    @State private var error = ""
    @State private var notice = ""
    @State private var csv: PayrollCSV?
    @State private var filename = ""
    @State private var exporting = false

    var body: some View {
        Form {
            if let settings {
                if setup { settingsSections(settings) }
                else { periodSections(settings) }
            } else if busy {
                ProgressView("Loading payroll")
            } else {
                Button("Load payroll") { perform(load) }
            }
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            if !notice.isEmpty { Text(notice).foregroundStyle(.secondary) }
        }
        .navigationTitle(setup ? "Employee Pay" : "Payroll Periods")
        .task(id: companyId) { perform(load) }
        .fileExporter(isPresented: $exporting, document: csv, contentType: .commaSeparatedText, defaultFilename: filename) { result in
            if case .failure(let failure) = result { error = failure.userFacingMessage }
            csv = nil
        }
    }

    @ViewBuilder private func settingsSections(_ current: Settings) -> some View {
        Section("Employee pay") {
            Picker("Default pay basis", selection: binding(\.employeeDefault, current)) {
                Text("Existing pay rules").tag("legacy")
                Text("Hourly").tag("hourly")
                Text("Piece rate").tag("pieceRate")
            }
            Text("Hourly employees are paid from the time clock. Piece-rate employees earn per completed visit and also record work time.")
                .font(.footnote).foregroundStyle(.secondary)
            if !employees.isEmpty {
                DisclosureGroup("Individual employee pay") {
                    ForEach(employees) { employee in
                        Picker(employee.name, selection: Binding(
                            get: { settings?.employeeOverrides[employee.id] ?? "companyDefault" },
                            set: { settings?.employeeOverrides[employee.id] = $0 }
                        )) {
                            Text("Use company default").tag("companyDefault")
                            Text("Hourly").tag("hourly")
                            Text("Piece rate").tag("pieceRate")
                        }
                    }
                }
            }
        }.disabled(busy)
        Section("Payroll workflow") {
            Picker("Workflow", selection: binding(\.mode, current)) {
                Text("Manual").tag("manual")
                Text("Scheduled review").tag("scheduledReview")
                Text("Automatic export").tag("automatic")
            }
            if current.mode != "manual" {
                Picker("Frequency", selection: binding(\.frequency, current)) {
                    Text("Weekly").tag("weekly")
                    Text("Every two weeks").tag("biweekly")
                    Text("Monthly").tag("monthly")
                }
                DatePicker("First period starts", selection: calendarBinding(binding(\.startDay, current), timeZone: current.timeZone), displayedComponents: .date)
                    .environment(\.timeZone, TimeZone(identifier: current.timeZone) ?? .gmt)
                Text("Preparation starts at 6 a.m. in \(current.timeZone) after each period closes.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if current.mode == "automatic" {
                Text("Drip Drop prepares the report and export. Pay through your external process and record the reference here.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Button("Save payroll workflow") { perform(saveSettings) }
        }.disabled(busy)
    }

    @ViewBuilder private func periodSections(_ current: Settings) -> some View {
        if current.mode == "manual" {
            Section("Prepare payroll") {
                DatePicker("Period starts", selection: calendarBinding($start, timeZone: current.timeZone), displayedComponents: .date)
                DatePicker("Next period starts", selection: calendarBinding($end, timeZone: current.timeZone), displayedComponents: .date)
                Button("Prepare payroll") { perform(prepare) }
            }.environment(\.timeZone, TimeZone(identifier: current.timeZone) ?? .gmt).disabled(busy)
        }
        Section("Recent periods") {
            if periods.isEmpty { Text("No payroll periods yet.").foregroundStyle(.secondary) }
            ForEach(periods) { period in
                Button {
                    perform { try await open(period.id) }
                } label: {
                    VStack(alignment: .leading) {
                        Text(period.title).fontWeight(.medium)
                        Text("\(period.statusLabel) · \(money(period.totalCents)) gross")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            Button("Reload periods") { perform(load) }
            if let nextPeriodCursor {
                Button("Load older periods") {
                    perform {
                        let older: OlderPeriods = try decode(await command("olderPeriods", ["before": nextPeriodCursor]))
                        periods.append(contentsOf: older.runs)
                        self.nextPeriodCursor = older.nextPeriodCursor
                    }
                }
            }
        }.disabled(busy)
        if let detail { reportSection(detail).disabled(busy) }
    }

    private func reportSection(_ period: Period) -> some View {
        Section("Payroll report") {
            Text(period.title)
            Text("\(period.statusLabel) · \(money(period.totalCents)) gross")
            Text("Use the recorded time and gross earnings in your external payroll process for overtime, wage adjustments, and withholding.")
                .font(.footnote).foregroundStyle(.secondary)
            ForEach(period.problems, id: \.self) { Text($0).foregroundStyle(.orange) }
            ForEach(period.workers ?? []) { worker in
                DisclosureGroup(worker.name) {
                    Text("\(hours(worker.timeMs)) tracked hours · \(money(worker.totalCents)) gross")
                    if worker.reviewCount > 0 { Text("Needs review").foregroundStyle(.orange) }
                    if worker.excludedCents != 0 { Text("\(money(worker.excludedCents)) already paid or assigned to a statement or export.") }
                    ForEach(worker.daily) { day in
                        Text("\(day.day) · \(hours(day.workedMs)) worked · \(hours(day.paidBreakMs)) paid break · \(hours(day.unpaidBreakMs)) unpaid break · \(money(day.hourlyCents + day.pieceCents + day.otherCents))")
                    }
                }
            }
            if period.exportedAt == nil && period.exportState == nil && period.status != "paidExternally" {
                Button("Refresh from payroll records") { perform { try await update("refresh", period: period) } }
            }
            if period.status == "reviewRequired" {
                Button("Approve for export") { perform { try await update("approve", period: period, data: ["fingerprint": period.fingerprint ?? ""]) } }
            }
            if ["readyForExport", "paidExternally"].contains(period.status) {
                Button("Export payroll CSV") { perform { try await export(period) } }
            }
            if period.status == "readyForExport" && period.exportedAt != nil || period.status == "recordingPayment" {
                TextField("Confirmed external payment reference", text: $reference)
                    .disabled(period.status == "recordingPayment")
                DatePicker("Payment date", selection: calendarBinding($paidDay, timeZone: period.timeZone), displayedComponents: .date)
                    .environment(\.timeZone, TimeZone(identifier: period.timeZone) ?? .gmt)
                    .disabled(period.status == "recordingPayment")
                Button(period.status == "recordingPayment" ? "Resume recording" : "Record external payment") {
                    perform { try await update("recordPayment", period: period, data: ["reference": reference, "paidDay": paidDay]) }
                }
                    .disabled(reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let paymentReference = period.paymentReference {
                Text("External payment reference \(paymentReference) · \(period.paidDay ?? "")")
            }
        }
    }

    private func perform(_ task: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }
        busy = true
        error = ""
        notice = ""
        Task {
            defer { busy = false }
            do { try await task() }
            catch { self.error = error.userFacingMessage }
        }
    }

    private func command(_ action: String, _ input: [String: Any] = [:]) async throws -> [String: Any] {
        let payload = input.merging(["action": action, "companyId": companyId]) { _, required in required }
        return try await FunctionsManager.shared.technicianWorkflow("manageCompanyPayroll", payload: payload)
    }

    private func decode<T: Decodable>(_ value: Any) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: value))
    }

    private func load() async throws {
        let result: Loaded = try decode(await command("load"))
        settings = result.settings
        if settings?.startDay.isEmpty == true { settings?.startDay = result.today }
        employees = result.employees
        periods = result.runs
        nextPeriodCursor = result.nextPeriodCursor
        today = result.today
        if end.isEmpty { end = result.today }
        if start.isEmpty { start = result.today }
    }

    private func saveSettings() async throws {
        guard let settings else { return }
        let overrides = Dictionary(uniqueKeysWithValues: employees.map { ($0.id, settings.employeeOverrides[$0.id] ?? "companyDefault") })
        let result = try await command("save", ["mode": settings.mode, "frequency": settings.frequency, "startDay": settings.startDay,
                                                "employeeDefault": settings.employeeDefault, "employeeOverrides": overrides, "revision": settings.revision])
        self.settings = try decode(result["settings"] ?? [:])
        if self.settings?.startDay.isEmpty == true { self.settings?.startDay = today }
        if let day = result["effectiveDay"] as? String { notice = "Saved. Employee pay changes take effect on \(day)." }
    }

    private func open(_ id: String) async throws {
        let result = try await command("view", ["runId": id])
        let selected: Period = try decode(result["run"] ?? [:])
        detail = selected
        reference = selected.paymentReference ?? ""
        paidDay = selected.paidDay ?? today
    }

    private func prepare() async throws {
        let result = try await command("prepare", ["startDay": start, "endDay": end])
        let prepared: Period = try decode(result["run"] ?? [:])
        try await open(prepared.id)
        try await load()
    }

    private func update(_ action: String, period: Period, data: [String: Any] = [:]) async throws {
        _ = try await command(action, data.merging(["runId": period.id]) { _, id in id })
        try await open(period.id)
        try await load()
    }

    private func export(_ period: Period) async throws {
        let result = try await command("export", ["runId": period.id])
        guard let text = result["csv"] as? String else { throw FireBaseRead.unableToRead }
        csv = PayrollCSV(text: text)
        filename = (result["filename"] as? String ?? "payroll.csv").replacingOccurrences(of: ".csv", with: "")
        exporting = true
        try await open(period.id)
        try await load()
    }

    private func binding(_ key: WritableKeyPath<Settings, String>, _ current: Settings) -> Binding<String> {
        Binding(get: { settings?[keyPath: key] ?? current[keyPath: key] },
                set: { settings?[keyPath: key] = $0 })
    }

    private func calendarBinding(_ text: Binding<String>, timeZone: String) -> Binding<Date> {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timeZone) ?? .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        return Binding(get: { formatter.date(from: text.wrappedValue) ?? formatter.date(from: today) ?? Date() },
                       set: { text.wrappedValue = formatter.string(from: $0) })
    }

    private func hours(_ milliseconds: Double) -> String { (milliseconds / 3_600_000).formatted(.number.precision(.fractionLength(2))) }
    private func money(_ cents: Int) -> String { (Double(cents) / 100).formatted(.currency(code: "USD")) }
}
