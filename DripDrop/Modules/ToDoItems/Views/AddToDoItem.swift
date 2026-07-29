//
//  AddToDoItem.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/28/24.
//

import SwiftUI

private enum ToDoPriorityOption: String, CaseIterable, Identifiable {
    case low
    case normal
    case high
    case urgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        }
    }

    var systemImage: String {
        switch self {
        case .low:
            return "arrow.down.circle"
        case .normal:
            return "minus.circle"
        case .high:
            return "arrow.up.circle"
        case .urgent:
            return "exclamationmark.octagon"
        }
    }

    var tint: Color {
        switch self {
        case .low:
            return .secondary
        case .normal:
            return .accentColor
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
}

private enum ToDoAssignmentMode: String, CaseIterable, Identifiable {
    case team
    case person

    var id: String { rawValue }

    var title: String {
        switch self {
        case .team:
            return "Team"
        case .person:
            return "Person"
        }
    }
}

struct AddToDoItem: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject private var toDoVM: ToDoViewModel
    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var status: toDoStatus = .toDo
    @State private var priority: ToDoPriorityOption = .normal
    @State private var assignmentMode: ToDoAssignmentMode = .team
    @State private var dueAt: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var reminderEnabled: Bool = false
    @State private var reminderAt: Date = Date()
    @State private var showSelectCustomer: Bool = false
    @State private var showSelectJob: Bool = false
    @State private var showSelectTech: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isSaving: Bool = false

    @State private var customerEntity: Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )

    @State private var jobEntity: Job = Job(
        id: "",
        internalId: "",
        type: "",
        dateCreated: Date(),
        description: "",
        operationStatus: .estimatePending,
        billingStatus: .draft,
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceStopIds: [],
        laborContractIds: [],
        adminId: "",
        adminName: "",
        rate: 0,
        laborCost: 0,
        otherCompany: false,
        receivedLaborContractId: "",
        receiverId: "",
        senderId : "",
        dateEstimateAccepted: nil,
        estimateAcceptedById: nil,
        estimateAcceptType: nil,
        estimateAcceptedNotes: nil,
        invoiceDate: nil,
        invoiceRef: nil,
        invoiceType: nil,
        invoiceNotes: nil
    )

    @State private var tech: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor
    )

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        headerSection
                        detailsSection
                        planningSection
                        assignmentSection
                        scheduleSection
                        linksSection

                        Color.clear.frame(height: 12)
                    }
                    .padding(16)
                }

                footer
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showSelectCustomer) {
            NavigationStack {
                CustomerPickerScreen(dataService: dataService, customer: $customerEntity)
            }
        }
        .sheet(isPresented: $showSelectJob) {
            NavigationStack {
                JobPickerScreen(dataService: dataService, job: $jobEntity)
            }
        }
        .sheet(isPresented: $showSelectTech) {
            NavigationStack {
                TechPickerScreen(tech: $tech)
            }
        }
    }
}

private extension AddToDoItem {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 48, height: 48)

                    Image(systemName: "checklist")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Todo")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("TODO")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.background, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .addTodoCard()
    }

    var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Details", systemImage: "text.alignleft")

            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("What needs to happen?", text: $title)
                    .font(.headline)
                    .textInputAutocapitalization(.sentences)
                    .padding(12)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(titleBorderColor, lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextEditor(text: $description)
                    .font(.subheadline)
                    .frame(minHeight: 116)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Add notes...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .addTodoCard()
    }

    var planningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Planning", systemImage: "slider.horizontal.3")

            Picker("Status", selection: $status) {
                ForEach(toDoStatus.allCases, id: \.self) { status in
                    Text(status.title()).tag(status)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ToDoPriorityOption.allCases) { option in
                        Button {
                            priority = option
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: option.systemImage)
                                    .font(.subheadline.weight(.semibold))

                                Text(option.title)
                                    .font(.subheadline.weight(.semibold))

                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(priority == option ? option.tint : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(priorityBackground(option), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(priority == option ? option.tint.opacity(0.32) : Color.primary.opacity(0.06), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .addTodoCard()
    }

    var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Assignment", systemImage: "person.crop.circle.badge.checkmark")

            Picker("Assignment", selection: $assignmentMode) {
                ForEach(ToDoAssignmentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: assignmentMode) { mode in
                if mode == .team {
                    tech = emptyTech
                }
            }

            if assignmentMode == .person {
                selectionRow(
                    title: tech.userName.isEmpty ? "Choose assignee" : tech.userName,
                    subtitle: tech.userName.isEmpty ? "No one selected" : tech.roleName,
                    systemImage: "person.crop.circle",
                    tint: tech.userName.isEmpty ? .secondary : .accentColor,
                    isSelected: !tech.userId.isEmpty,
                    clearAction: tech.userId.isEmpty ? nil : {
                        tech = emptyTech
                    },
                    action: {
                        showSelectTech = true
                    }
                )
            } else {
                passiveRow(
                    title: "Team task",
                    subtitle: "Visible to the company todo board.",
                    systemImage: "person.2"
                )
            }
        }
        .addTodoCard()
    }

    var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Schedule", systemImage: "calendar")

            Toggle(isOn: $hasDueDate) {
                Label("Due date", systemImage: "calendar.badge.clock")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(.accentColor)

            if hasDueDate {
                DatePicker("Due", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)

                Toggle(isOn: $reminderEnabled) {
                    Label("Reminder", systemImage: "bell")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(.accentColor)

                if reminderEnabled {
                    DatePicker("Remind", selection: $reminderAt, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
        }
        .addTodoCard()
    }

    var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Links", systemImage: "link")

            selectionRow(
                title: customerEntity.id.isEmpty ? "Customer" : customerDisplayName(customerEntity),
                subtitle: customerEntity.id.isEmpty ? "Not linked" : customerEntity.billingAddress.streetAddress,
                systemImage: "person.crop.circle",
                tint: customerEntity.id.isEmpty ? .secondary : .accentColor,
                isSelected: !customerEntity.id.isEmpty,
                clearAction: customerEntity.id.isEmpty ? nil : {
                    customerEntity = emptyCustomer
                },
                action: {
                    showSelectCustomer = true
                }
            )

            selectionRow(
                title: jobEntity.id.isEmpty ? "Job" : jobDisplayName(jobEntity),
                subtitle: jobEntity.id.isEmpty ? "Not linked" : jobEntity.customerName,
                systemImage: "briefcase",
                tint: jobEntity.id.isEmpty ? .secondary : .accentColor,
                isSelected: !jobEntity.id.isEmpty,
                clearAction: jobEntity.id.isEmpty ? nil : {
                    jobEntity = emptyJob
                },
                action: {
                    showSelectJob = true
                }
            )
        }
        .addTodoCard()
    }

    var footer: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                Task {
                    await createTodo()
                }
            } label: {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }

                    Text(isSaving ? "Creating..." : "Create Todo")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(createButtonColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canCreate || isSaving)
            .padding(16)
            .background(.regularMaterial)
        }
    }
}

private extension AddToDoItem {
    var canCreate: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAssigneeIfNeeded = assignmentMode == .team || !tech.userId.isEmpty
        return hasTitle && hasAssigneeIfNeeded
    }

    var createButtonColor: Color {
        canCreate ? .accentColor : .secondary.opacity(0.36)
    }

    var titleBorderColor: Color {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Color.primary.opacity(0.06)
            : Color.accentColor.opacity(0.26)
    }

    var emptyCustomer: Customer {
        Customer(
            id: "",
            firstName: "",
            lastName: "",
            email: "",
            billingAddress: Address(
                streetAddress: "",
                city: "",
                state: "",
                zip: "",
                latitude: 0,
                longitude: 0
            ),
            active: true,
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        )
    }

    var emptyJob: Job {
        Job(
            id: "",
            internalId: "",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "",
            serviceLocationId: "",
            serviceStopIds: [],
            laborContractIds: [],
            adminId: "",
            adminName: "",
            rate: 0,
            laborCost: 0,
            otherCompany: false,
            receivedLaborContractId: "",
            receiverId: "",
            senderId : "",
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: nil,
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
    }

    var emptyTech: CompanyUser {
        CompanyUser(
            id: "",
            userId: "",
            userName: "",
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .contractor
        )
    }

    var createdByName: String {
        if let user = masterDataManager.user {
            let fullName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            return fullName.isEmpty ? user.email : fullName
        }

        return masterDataManager.companyUser?.userName ?? ""
    }

    var relatedEntity: ToDoRelatedEntity? {
        if !jobEntity.id.isEmpty {
            return ToDoRelatedEntity(
                type: "job",
                id: jobEntity.id,
                label: jobDisplayName(jobEntity)
            )
        }

        if !customerEntity.id.isEmpty {
            return ToDoRelatedEntity(
                type: "customer",
                id: customerEntity.id,
                label: customerDisplayName(customerEntity)
            )
        }

        return nil
    }

    var effectiveDueDate: Date? {
        hasDueDate ? dueAt : nil
    }

    var effectiveReminderDate: Date? {
        hasDueDate && reminderEnabled ? reminderAt : nil
    }

    func createTodo() async {
        guard let company = masterDataManager.currentCompany else {
            alertMessage = "Missing company."
            showAlert = true
            return
        }

        guard let user = masterDataManager.user else {
            alertMessage = "Missing user."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let isTeamTask = assignmentMode == .team

            try await toDoVM.createToDoWithValidation(
                companyId: company.id,
                title: title,
                status: status,
                description: description,
                dateCreated: Date(),
                dateFinished: nil,
                linkedCustomerId: customerEntity.id,
                linkedJobId: jobEntity.id,
                assignedTechId: isTeamTask ? "" : tech.userId,
                creatorId: user.id,
                assignedToCompanyUserDocId: isTeamTask ? "" : tech.id,
                assignedToName: isTeamTask ? "Team task" : tech.userName,
                createdByName: createdByName,
                priority: priority.rawValue,
                dueAt: effectiveDueDate,
                reminderAt: effectiveReminderDate,
                reminderEnabled: hasDueDate && reminderEnabled,
                relatedEntity: relatedEntity,
                boardName: "Mobile",
                scope: isTeamTask ? "team" : "specific",
                assignmentType: isTeamTask ? "team" : "specific"
            )

            dismiss()
        } catch ToDoError.invalidTechId {
            alertMessage = ToDoError.invalidTechId.errorDescription()
            showAlert = true
        } catch ToDoError.invalidTitle {
            alertMessage = ToDoError.invalidTitle.errorDescription()
            showAlert = true
        } catch {
            alertMessage = "Could not create todo."
            showAlert = true
            print("[AddToDoItem][createTodo] \(error)")
        }
    }

    func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func selectionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        isSelected: Bool,
        clearAction: (() -> Void)?,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(tint)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(isSelected ? 0.12 : 0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(subtitle.isEmpty ? "Selected" : subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if let clearAction {
                Button(action: clearAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? tint.opacity(0.22) : Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    func passiveRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    func priorityBackground(_ option: ToDoPriorityOption) -> Color {
        priority == option ? option.tint.opacity(0.11) : Color.primary.opacity(0.035)
    }

    func customerDisplayName(_ customer: Customer) -> String {
        if customer.displayAsCompany {
            return customer.company ?? "\(customer.firstName) \(customer.lastName)"
        }

        return "\(customer.firstName) \(customer.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func jobDisplayName(_ job: Job) -> String {
        if !job.internalId.isEmpty {
            return job.internalId
        }

        if !job.type.isEmpty {
            return job.type
        }

        return job.id
    }
}

private struct AddTodoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
    }
}

private extension View {
    func addTodoCard() -> some View {
        modifier(AddTodoCardModifier())
    }
}

struct AddToDoItem_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        AddToDoItem(dataService: dataService)
    }
}
