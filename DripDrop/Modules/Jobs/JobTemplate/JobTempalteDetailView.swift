//
//  JobTemplateDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateDetailView: View {

    init(
        template: JobTemplate,
        dataService: any ProductionDataServiceProtocol
    ) {
        _VM = StateObject(
            wrappedValue: JobTemplateDetailViewModel(
                template: template,
                dataService: dataService
            )
        )
    }

    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject private var VM: JobTemplateDetailViewModel

    @State private var selectedTab: JobTemplateDetailTab = .overview
    @State private var showEditTemplateSheet: Bool = false
    @State private var showAddTemplateTaskSheet: Bool = false
    @State private var showAddTemplatePlannedStopSheet: Bool = false
    @State private var showAddTemplateMaterialSheet: Bool = false
    @State private var showCreateJobFromTemplateSheet: Bool = false
    
    var body: some View {
        ZStack {
         Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                    tabBar
                VStack(spacing: 14) {
                    
                    switch selectedTab {
                    case .overview:
                        overviewSection
                        
                    case .plannedStops:
                        plannedStopsSection
                        
                    case .tasks:
                        tasksSection
                        
                    case .materials:
                        materialsSection
                    }
                        //                     Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
            
         }
         .navigationTitle(VM.template.name)
         .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditTemplateSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
        .alert("Job Template", isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(VM.alertMessage)
        }
        .sheet(isPresented: $showEditTemplateSheet) {
            EditJobTemplateSheet(
                template: VM.template,
                dataService: VM.dataService,
                onSaved: { updatedTemplate in
                    VM.template = updatedTemplate
                    Task {
                        await load()
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddTemplateTaskSheet, onDismiss: {
            Task {
                await load()
            }
        }) {
            AddJobTemplateTaskSheet(
                companyId: VM.template.companyId,
                templateId: VM.template.id,
                existingTasks: VM.tasks,
                dataService: VM.dataService,
                onSaved: {
                    Task {
                        await load()
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddTemplatePlannedStopSheet, onDismiss: {
            Task {
                await load()
            }
        }) {
            AddJobTemplatePlannedStopSheet(
                companyId: VM.template.companyId,
                templateId: VM.template.id,
                existingPlannedStops: VM.plannedStops,
                templateTasks: VM.tasks,
                dataService: VM.dataService,
                onSaved: {
                    Task {
                        await load()
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddTemplateMaterialSheet, onDismiss: {
            Task {
                await load()
            }
        }) {
            AddJobTemplateMaterialSheet(
                companyId: VM.template.companyId,
                templateId: VM.template.id,
                existingItems: VM.shoppingItems,
                dataService: VM.dataService,
                onSaved: {
                    Task {
                        await load()
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCreateJobFromTemplateSheet, onDismiss: {
            Task {
                await load()
            }
        }) {
            CreateJobFromTemplateSheet(
                template: VM.template,
                dataService: VM.dataService
            )
            .presentationDetents([.large])
        }
    }
    
// MARK: tabBar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(JobTemplateDetailTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.caption.weight(.semibold))

                            Text(tab.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(
                                    selectedTab == tab
                                    ? Color.accentColor
                                    : Color.white.opacity(0.85)
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(
                            color: Color.black.opacity(selectedTab == tab ? 0.12 : 0.04),
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 58)
        .background(
            Rectangle()
                .fill(Color.listColor)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
        // MARK: overviewSection
    private var overviewSection: some View {
        VStack(spacing: 14) {
            headerCard
            templateActionsCard
            financialSnapshotCard
            workflowSnapshotCard
        }
    }
    
// MARK: headerCard
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(VM.template.name)
                        .font(.title3.weight(.semibold))

                    Text(VM.template.jobType.isEmpty ? "Job Template" : VM.template.jobType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if VM.template.locked {
                        Label("Locked", systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                Spacer()

                Image(systemName: VM.template.jobTypeImage ?? "doc.text")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(.thinMaterial, in: Circle())
            }

            if !VM.template.description.isEmpty {
                Text(VM.template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                JobTemplateDetailChip(
                    title: "Stops",
                    value: "\(VM.plannedStops.count)",
                    systemImage: "calendar"
                )

                JobTemplateDetailChip(
                    title: "Tasks",
                    value: "\(VM.tasks.count)",
                    systemImage: "checklist"
                )

                JobTemplateDetailChip(
                    title: "Materials",
                    value: "\(VM.shoppingItems.count)",
                    systemImage: "cart"
                )
            }
        }
        .jobTemplateDetailCard()
    }
    
// MARK: financialSnapshotCard
    private var financialSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            JobTemplateSectionHeader(
                title: "Financial Snapshot",
                systemImage: "dollarsign.circle"
            )

            JobTemplateDetailMoneyRow(
                title: "Default Customer Price",
                cents: VM.template.defaultRateCents
            )

            JobTemplateDetailMoneyRow(
                title: "Default Labor Cost",
                cents: VM.template.defaultLaborCostCents
            )

            JobTemplateDetailMoneyRow(
                title: "Planned Stop Labor",
                cents: VM.plannedStopLaborCents
            )
            JobTemplateDetailMoneyRow(
                title: "Planned Task Labor",
                cents: VM.plannedTaskLaborCents
            )
            JobTemplateDetailMoneyRow(
                title: "Planned Material Cost",
                cents: VM.plannedMaterialCostCents
            )

            Divider().opacity(0.18)

            JobTemplateDetailMoneyRow(
                title: "Projected Profit",
                cents: VM.projectedProfitCents,
                valueIsWarning: VM.projectedProfitCents < 0
            )
        }
        .jobTemplateDetailCard()
    }
    
// MARK: workflowSnapshotCard
    private var workflowSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            JobTemplateSectionHeader(
                title: "Reusable Plan",
                systemImage: "square.stack.3d.up"
            )

            JobTemplateDetailSummaryRow(
                title: "Created",
                value: fullDate(date: VM.template.createdAt)
            )

            JobTemplateDetailSummaryRow(
                title: "Status",
                value: VM.template.isActive ? "Active" : "Inactive"
            )

            JobTemplateDetailSummaryRow(
                title: "Planned Minutes",
                value: "\(VM.plannedMinutes) min"
            )

            Text("Templates should contain reusable planning information only. Customer, service location, assigned admin, service stops, offers, payroll, and invoices are selected or created when a new job is made from the template.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .jobTemplateDetailCard()
    }
        // MARK: templateActionsCard

    private var templateActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            JobTemplateSectionHeader(
                title: "Actions",
                systemImage: "bolt.circle"
            )

            Button {
                showCreateJobFromTemplateSheet = true
            } label: {
                JobTemplateActionRow(
                    title: "Create Job From Template",
                    subtitle: "Create a new draft job using this reusable plan.",
                    systemImage: "plus.rectangle.on.folder"
                )
            }
            .buttonStyle(.plain)

            Text("This will copy planned stops, template tasks, planned materials, default customer price, and labor snapshot into a new job.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateDetailCard()
    }
// MARK: plannedStopsSection
    private var plannedStopsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JobTemplateSectionHeader(
                    title: "Planned Service Stops",
                    systemImage: "calendar.badge.clock"
                )

                Spacer()

                Text("\(VM.plannedStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.plannedStops.isEmpty {
                JobTemplateEmptyState(
                    title: "No planned stops",
                    message: "Add expected visits like Install Visit, Startup, or Service Call.",
                    systemImage: "calendar.badge.plus"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.plannedStops.sorted(by: { $0.sortOrder < $1.sortOrder })) { stop in
                        JobTemplatePlannedStopRow(stop: stop)
                    }
                }
            }

            Button {
                showAddTemplatePlannedStopSheet = true
            } label: {
                JobTemplateActionRow(
                    title: "Add Planned Stop",
                    subtitle: "Add an expected service visit to this template.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)
        }
        .jobTemplateDetailCard()
    }
    
// MARK: tasksSection
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JobTemplateSectionHeader(
                    title: "Template Tasks",
                    systemImage: "checklist"
                )

                Spacer()

                Text("\(VM.tasks.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.tasks.isEmpty {
                JobTemplateEmptyState(
                    title: "No tasks",
                    message: "Add reusable tasks or import from a task group.",
                    systemImage: "checklist.unchecked"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.tasks.sorted(by: { $0.sortOrder < $1.sortOrder })) { task in
                        JobTemplateTaskRow(task: task)
                    }
                }
            }

            Button {
                showAddTemplateTaskSheet = true
            } label: {
                JobTemplateActionRow(
                    title: "Add Task",
                    subtitle: "Add a reusable planned task.",
                    systemImage: "checklist.badge.plus"
                )
            }
            .buttonStyle(.plain)
            
        }
        .jobTemplateDetailCard()
    }

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JobTemplateSectionHeader(
                    title: "Template Materials",
                    systemImage: "cart"
                )

                Spacer()

                Text("\(VM.shoppingItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.shoppingItems.isEmpty {
                JobTemplateEmptyState(
                    title: "No materials",
                    message: "Add reusable planned materials for this job template.",
                    systemImage: "cart.badge.plus"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.shoppingItems.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        JobTemplateShoppingItemRow(item: item)
                    }
                }
            }

            Button {
                showAddTemplateMaterialSheet = true
            } label: {
                JobTemplateActionRow(
                    title: "Add Material",
                    subtitle: "Add a planned database or custom material.",
                    systemImage: "cart.badge.plus"
                )
            }
            .buttonStyle(.plain)
        }
        .jobTemplateDetailCard()
    }

    private func load() async {
        await VM.load()
    }
}

// MARK: - ViewModel

@MainActor
final class JobTemplateDetailViewModel: ObservableObject {

    let dataService: any ProductionDataServiceProtocol

    @Published var template: JobTemplate

    @Published var plannedStops: [JobTemplatePlannedServiceStop] = []
    @Published var tasks: [JobTemplateTask] = []
    @Published var shoppingItems: [JobTemplateShoppingItem] = []

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    init(
        template: JobTemplate,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.template = template
        self.dataService = dataService
    }
    var plannedTaskLaborCents: Int {
        tasks.reduce(0) { $0 + $1.contractedRate }
    }
    var plannedStopLaborCents: Int {
        plannedStops.reduce(0) { total, stop in
            total + (stop.plannedLaborCostCents ?? 0)
        }
    }

    var plannedMaterialCostCents: Int {
        shoppingItems.reduce(0) { total, item in
            total + (item.plannedTotalCostCents ?? 0)
        }
    }

    var plannedMinutes: Int {
        plannedStops.reduce(0) { $0 + $1.estimatedMinutes } +
        tasks.reduce(0) { $0 + $1.estimatedTime }
    }

    var projectedProfitCents: Int {
        let laborCost = template.defaultLaborCostCents > 0
        ? template.defaultLaborCostCents
        : plannedStopLaborCents + plannedTaskLaborCents

        return template.defaultRateCents - laborCost - plannedMaterialCostCents
    }
    
    func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            async let templateTask = dataService.fetchJobTemplate(
                companyId: template.companyId,
                templateId: template.id
            )

            async let plannedStopsTask = dataService.fetchJobTemplatePlannedServiceStops(
                companyId: template.companyId,
                templateId: template.id
            )

            async let tasksTask = dataService.fetchJobTemplateTasks(
                companyId: template.companyId,
                templateId: template.id
            )

            async let shoppingItemsTask = dataService.fetchJobTemplateShoppingItems(
                companyId: template.companyId,
                templateId: template.id
            )

            template = try await templateTask
            plannedStops = try await plannedStopsTask
            tasks = try await tasksTask
            shoppingItems = try await shoppingItemsTask
        } catch {
            alertMessage = "Could not load template. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Edit Sheet

struct EditJobTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss

    let dataService: any ProductionDataServiceProtocol
    let onSaved: (JobTemplate) -> Void

    @State private var template: JobTemplate

    @State private var name: String
    @State private var description: String
    @State private var jobType: String
    @State private var defaultRateCents: Int
    @State private var defaultLaborCostCents: Int
    @State private var isActive: Bool
    @State private var locked: Bool
    @State private var technicianCanAdd: Bool

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        template: JobTemplate,
        dataService: any ProductionDataServiceProtocol,
        onSaved: @escaping (JobTemplate) -> Void
    ) {
        self.dataService = dataService
        self.onSaved = onSaved

        _template = State(initialValue: template)
        _name = State(initialValue: template.name)
        _description = State(initialValue: template.description)
        _jobType = State(initialValue: template.jobType)
        _defaultRateCents = State(initialValue: template.defaultRateCents)
        _defaultLaborCostCents = State(initialValue: template.defaultLaborCostCents)
        _isActive = State(initialValue: template.isActive)
        _locked = State(initialValue: template.locked)
        _technicianCanAdd = State(initialValue: template.technicianCanAdd)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        detailsCard
                        pricingCard
                        statusCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .alert("Edit Template", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Template Details",
                systemImage: "doc.text"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Template Name", text: $name)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Job Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Job Type", text: $jobType)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Description",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(4, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateDetailCard()
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Default Pricing",
                systemImage: "dollarsign.circle"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Customer Price")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $defaultRateCents)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Labor Cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $defaultLaborCostCents)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateDetailCard()
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Status",
                systemImage: "gearshape"
            )

            Toggle("Active", isOn: $isActive)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle("Locked", isOn: $locked)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle("Technicians Can Add", isOn: $technicianCanAdd)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("Locked templates can still be viewed, but should not be edited casually. You can enforce stricter locked behavior later.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateDetailCard()
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await save()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Label("Save Changes", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button {
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private func save() async {
        guard canSave else {
            alertMessage = "Please enter a template name."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            var updated = template
            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.description = description
            updated.jobType = jobType
            updated.defaultRateCents = defaultRateCents
            updated.defaultLaborCostCents = defaultLaborCostCents
            updated.isActive = isActive
            updated.locked = locked
            updated.technicianCanAdd = technicianCanAdd
            updated.updatedAt = Date()

            try await dataService.saveJobTemplate(updated)

            onSaved(updated)
            dismiss()
        } catch {
            alertMessage = "Could not save template. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Rows / Helpers

enum JobTemplateDetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case plannedStops = "Stops"
    case tasks = "Tasks"
    case materials = "Materials"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .overview:
            return "square.grid.2x2"
        case .plannedStops:
            return "calendar"
        case .tasks:
            return "checklist"
        case .materials:
            return "cart"
        }
    }
}

struct JobTemplateSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
    }
}

struct JobTemplateDetailChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct JobTemplateDetailMoneyRow: View {
    let title: String
    let cents: Int
    var valueIsWarning: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(JobTemplateDetailMoneyFormatter.money(cents))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueIsWarning ? .orange : .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct JobTemplateDetailSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.isEmpty ? "-" : value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct JobTemplatePlannedStopRow: View {
    let stop: JobTemplatePlannedServiceStop

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: stop.serviceStopTypeImage.isEmpty ? "calendar" : stop.serviceStopTypeImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.subheadline.weight(.semibold))

                Text("\(stop.serviceStopTypeName) • \(stop.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let plannedLaborCostCents = stop.plannedLaborCostCents,
                   plannedLaborCostCents > 0 {
                    Text("Planned labor: \(JobTemplateDetailMoneyFormatter.money(plannedLaborCostCents))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !stop.taskTemplateIds.isEmpty {
                    Label("\(stop.taskTemplateIds.count) linked task(s)", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobTemplateTaskRow: View {
    let task: JobTemplateTask

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline.weight(.semibold))

                Text("\(task.type.rawValue) • \(task.estimatedTime) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if task.contractedRate > 0 {
                    Text("Planned labor: \(JobTemplateDetailMoneyFormatter.money(task.contractedRate))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobTemplateShoppingItemRow: View {
    let item: JobTemplateShoppingItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cart")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))

                Text("\(item.subCategory.rawValue) • Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let plannedTotalCostCents = item.plannedTotalCostCents {
                    Text("Cost: \(JobTemplateDetailMoneyFormatter.money(plannedTotalCostCents))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let plannedTotalPriceCents = item.plannedTotalPriceCents {
                    Text("Billable: \(JobTemplateDetailMoneyFormatter.money(plannedTotalPriceCents))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobTemplateActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobTemplateEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

enum JobTemplateDetailMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

private extension View {
    func jobTemplateDetailCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
