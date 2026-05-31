    //
    //  RecurringServiceStopDetailView.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/8/24.
    //

    import SwiftUI

    @MainActor
    final class RecurringServiceStopDetailViewModel: ObservableObject {
        let dataService: any ProductionDataServiceProtocol

        init(dataService: any ProductionDataServiceProtocol) {
            self.dataService = dataService
        }

        @Published var taskItems: [JobTaskGroupItem] = []
        @Published private(set) var RSSTasks: [RecurringServiceStopTask] = []

        @Published var showAddTask: Bool = false
        @Published var isLoading: Bool = false

        @Published var showAddTaskGroup: Bool = false
        @Published var isEdit: Bool = false

        @Published var editTech: String = ""
        @Published var editFrequency: LaborContractFrequency = .weekly
        @Published var editDay: DaysOfWeek = .monday
        @Published var editNoEndDate: Bool = true
        @Published var editEndDate: Date = Date()
        @Published var editDescription: String = ""

        @Published var showSavedFeedback: Bool = false
        @Published var showSaveError: Bool = false
        @Published var saveErrorMessage: String = ""

        func onLoad(companyId: String, recurringServiceStop: RecurringServiceStop) {
            Task {
                do {
                    self.RSSTasks = try await dataService.getRecurringServiceStopTasks(
                        companyId: companyId,
                        recurringServiceStopId: recurringServiceStop.id
                    )
                } catch {
                    print(error)
                }
            }
        }

        func beginEditing(_ rss: RecurringServiceStop) {
            editTech = rss.tech
            editFrequency = rss.frequency
            editDay = rss.day
            editNoEndDate = rss.noEndDate
            editEndDate = rss.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            editDescription = rss.description

            showSavedFeedback = false
            showSaveError = false
            saveErrorMessage = ""
        }

        func cancelEditing() {
            showSavedFeedback = false
            showSaveError = false
            saveErrorMessage = ""
            isEdit = false
        }

        func updatedRSS(from rss: RecurringServiceStop) -> RecurringServiceStop {
            RecurringServiceStop(
                id: rss.id,
                internalId: rss.internalId,
                type: rss.type,
                typeId: rss.typeId,
                typeImage: rss.typeImage,
                customerName: rss.customerName,
                customerId: rss.customerId,
                address: rss.address,
                tech: editTech.trimmingCharacters(in: .whitespacesAndNewlines),
                techId: rss.techId,
                dateCreated: rss.dateCreated,
                startDate: rss.startDate,
                endDate: editNoEndDate ? nil : editEndDate,
                noEndDate: editNoEndDate,
                frequency: editFrequency,
                day: editDay,
                description: editDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                lastCreated: rss.lastCreated,
                serviceLocationId: rss.serviceLocationId,
                estimatedTime: rss.estimatedTime,
                otherCompany: rss.otherCompany,
                laborContractId: rss.laborContractId,
                contractedCompanyId: rss.contractedCompanyId,
                mainCompanyId: rss.mainCompanyId
            )
        }

        func saveRSS(
            companyId: String,
            currentRSS: RecurringServiceStop,
            onSuccess: @escaping (RecurringServiceStop) -> Void
        ) {
            Task {
                do {
                    isLoading = true
                    showSaveError = false
                    saveErrorMessage = ""

                    let updatedRSS = updatedRSS(from: currentRSS)

                    try await FunctionsManager.shared.updateRecurringServiceStop(
                        companyId: companyId,
                        recurringServiceStop: updatedRSS
                    )

                    onSuccess(updatedRSS)

                    showSavedFeedback = true
                    isEdit = false
                    isLoading = false

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        showSavedFeedback = false
                    }
                } catch {
                    isLoading = false
                    showSaveError = true
                    saveErrorMessage = error.localizedDescription

                    print(error)

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }

        func addNewTasks(companyId: String, recurringServiceStopId: String) {
            Task {
                do {
                    for task in taskItems {
                        let recurringTask = RecurringServiceStopTask(
                            name: task.name,
                            description: task.description,
                            type: task.type,
                            contractedRate: task.contractedRate,
                            estimatedTime: task.estimatedTime,
                            status: .unassigned,
                            isTaskGroup: false,
                            taskGroupId: "",
                            taskGroupTaskId: ""
                        )

                        RSSTasks.append(recurringTask)

                        try await dataService.uploadRecurringServiceStopTask(
                            companyId: companyId,
                            recurringServiceStopId: recurringServiceStopId,
                            task: recurringTask
                        )
                    }

                    self.taskItems = []
                } catch {
                    print(error)
                }
            }
        }

        func deleteTask(companyId: String, recurringServiceStopId: String, taskId: String) {
            Task {
                do {
                    try await dataService.deleteRecurringServiceStopTask(
                        companyId: companyId,
                        recurringServiceStopId: recurringServiceStopId,
                        taskId: taskId
                    )
                } catch {
                    print(error)
                }
            }
        }
        func deleteRecurringServiceStop(
            companyId: String,
            stopId: String,
            onSuccess: @escaping () -> Void
        ) {
            Task {
                do {
                    isLoading = true
                    showSaveError = false
                    saveErrorMessage = ""

                    try await FunctionsManager.shared.deleteRecurringServiceStop(
                        companyId: companyId,
                        stopId: stopId
                    )

                    isLoading = false

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    onSuccess()
                } catch {
                    isLoading = false
                    showSaveError = true
                    saveErrorMessage = error.localizedDescription

                    print(error)

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }
    }

    struct RecurringServiceStopDetailView: View {
        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject var masterDataManager: MasterDataManager

        @StateObject var VM: RecurringServiceStopDetailViewModel
        @State var RSS: RecurringServiceStop
        @Environment(\.dismiss) private var dismiss
        init(dataService: any ProductionDataServiceProtocol, RSS: RecurringServiceStop) {
            _RSS = State(wrappedValue: RSS)
            _VM = StateObject(wrappedValue: RecurringServiceStopDetailViewModel(dataService: dataService))
        }

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard

                        if VM.showSavedFeedback {
                            savedFeedbackCard
                        }

                        if VM.showSaveError {
                            errorFeedbackCard
                        }

                        details

                        if RSS.otherCompany {
                            otherCompanyDetails
                        }

                        taskItems
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
            .task {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.onLoad(companyId: currentCompany.id, recurringServiceStop: RSS)
                }
            }
        }
    }

    //#Preview {
    //    RecurringServiceStopDetailView()
    //}

    extension RecurringServiceStopDetailView {

        var headerCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(RSS.customerName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(RSS.address.streetAddress)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            if VM.isEdit {
                                VM.cancelEditing()
                            } else {
                                VM.beginEditing(RSS)
                                VM.isEdit = true
                            }
                        }
                    } label: {
                        Label(VM.isEdit ? "Cancel" : "Edit", systemImage: VM.isEdit ? "xmark" : "pencil")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if VM.isEdit {
                    HStack(spacing: 10) {
                        Button {
                            if let currentCompany = masterDataManager.currentCompany {
                                VM.saveRSS(companyId: currentCompany.id, currentRSS: RSS) { updatedRSS in
                                    RSS = updatedRSS
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if VM.isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "checkmark")
                                }

                                Text(VM.isLoading ? "Saving" : "Save")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.poolBlue.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSaveRSS)
                        .opacity(canSaveRSS ? 1 : 0.45)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Button(role: .destructive) {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.deleteRecurringServiceStop(
                                companyId: currentCompany.id,
                                stopId: RSS.id
                            ) {
                                dismiss()
                            }
                        }
                    } label: {
                        Label("Delete Recurring Stop", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(VM.isLoading)
                    .opacity(VM.isLoading ? 0.45 : 1)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: VM.isEdit)
        }

        var canSaveRSS: Bool {
            !VM.isLoading &&
            !VM.editTech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var savedFeedbackCard: some View {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring stop updated")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Your changes were saved successfully.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        var errorFeedbackCard: some View {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Could not save changes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(VM.saveErrorMessage.isEmpty ? "Please try again." : VM.saveErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        var details: some View {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Details", systemImage: "calendar.badge.clock")

                if VM.isEdit {
                    editDetails
                } else {
                    readOnlyDetails
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: VM.isEdit)
        }

        var readOnlyDetails: some View {
            VStack(alignment: .leading, spacing: 12) {
                detailRow("Technician", RSS.tech, systemImage: "person.crop.circle")
                detailRow("Created", fullDate(date: RSS.dateCreated), systemImage: "calendar")
                detailRow("Start Date", fullDate(date: RSS.startDate), systemImage: "play.circle")

                if RSS.noEndDate {
                    detailRow("End Date", "No end date", systemImage: "infinity")
                } else if let endDate = RSS.endDate {
                    detailRow("End Date", fullDate(date: endDate), systemImage: "calendar.badge.checkmark")
                }

                detailRow("Frequency", RSS.frequency.rawValue, systemImage: "repeat")
                detailRow("Day", RSS.day.rawValue, systemImage: "calendar.day.timeline.left")
                detailRow("Last Created", fullDate(date: RSS.lastCreated), systemImage: "clock.arrow.circlepath")
                detailRow("Estimated Time", displayMinAsMinAndHour(min: RSS.estimatedTime), systemImage: "timer")

                if !RSS.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(RSS.description)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 4)
                }
            }
        }

        var editDetails: some View {
            VStack(alignment: .leading, spacing: 14) {
                editTextField(
                    title: "Technician",
                    systemImage: "person.crop.circle",
                    text: $VM.editTech,
                    placeholder: "Technician name"
                )

                editPicker(
                    title: "Frequency",
                    systemImage: "repeat",
                    selection: $VM.editFrequency,
                    options: LaborContractFrequency.allCases
                )

                editPicker(
                    title: "Day",
                    systemImage: "calendar.day.timeline.left",
                    selection: $VM.editDay,
                    options: DaysOfWeek.allCases
                )

                Toggle(isOn: $VM.editNoEndDate.animation(.spring(response: 0.28, dampingFraction: 0.9))) {
                    Label("No End Date", systemImage: "infinity")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                if !VM.editNoEndDate {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("End Date", systemImage: "calendar.badge.checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "End Date",
                            selection: $VM.editEndDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Description", systemImage: "text.alignleft")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextEditor(text: $VM.editDescription)
                        .font(.subheadline)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }

        var otherCompanyDetails: some View {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Contract Details", systemImage: "building.2")

                if let laborContractId = RSS.laborContractId {
                    detailRow("Labor Contract", laborContractId, systemImage: "doc.text")
                }

                if let contractedCompanyId = RSS.contractedCompanyId {
                    detailRow("Contracted Company", contractedCompanyId, systemImage: "building")
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var taskItems: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Task Items", systemImage: "checklist")

                    Spacer()

                    Text("\(VM.RSSTasks.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                if VM.isEdit {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Button {
                                VM.showAddTask.toggle()
                            } label: {
                                actionButtonLabel("Add Task", systemImage: "plus")
                            }
                            .sheet(isPresented: $VM.showAddTask) {
                                AddRecurringServiceStopTask(dataService: dataService, tasks: $VM.taskItems)
                            }

                            Button {
                                VM.showAddTaskGroup.toggle()
                            } label: {
                                actionButtonLabel("Add Group", systemImage: "square.stack.3d.up")
                            }
                            .disabled(!VM.taskItems.isEmpty)
                            .opacity(VM.taskItems.isEmpty ? 1 : 0.45)
                            .sheet(isPresented: $VM.showAddTaskGroup, onDismiss: {
                                if let currentCompany = masterDataManager.currentCompany {
                                    VM.addNewTasks(companyId: currentCompany.id, recurringServiceStopId: RSS.id)
                                }
                            }) {
                                TaskGroupPickerView(dataService: dataService, tasks: $VM.taskItems)
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if VM.RSSTasks.isEmpty {
                    emptyTaskState
                } else {
                    VStack(spacing: 8) {
                        ForEach(VM.RSSTasks) { task in
                            taskRow(task)
                        }
                    }
                }

                if !VM.taskItems.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()

                        Text("Adding tasks...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: VM.isEdit)
        }

        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }

        func detailRow(_ title: String, _ value: String, systemImage: String) -> some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
        }

        func editTextField(
            title: String,
            systemImage: String,
            text: Binding<String>,
            placeholder: String
        ) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: text)
                    .font(.subheadline)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }

        func editPicker<T>(
            title: String,
            systemImage: String,
            selection: Binding<T>,
            options: [T]
        ) -> some View where T: Hashable, T: RawRepresentable, T.RawValue == String {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker(title, selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }

        func actionButtonLabel(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        func taskRow(_ task: RecurringServiceStopTask) -> some View {
            HStack(spacing: 12) {
                Image(systemName: task.isTaskGroup ? "square.stack.3d.up" : "checkmark.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if !task.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if VM.isEdit {
                    Image(systemName: "line.3.horizontal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .transition(.opacity)
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var emptyTaskState: some View {
            VStack(spacing: 8) {
                Image(systemName: "checklist.unchecked")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(VM.isEdit ? "Add tasks to this recurring stop." : "No tasks added yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
