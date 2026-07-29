    //
    //  AddNewTaskGroup.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/8/24.
    //

    import SwiftUI

    @MainActor
    final class AddNewTaskGroupViewModel: ObservableObject {
        let dataService: any ProductionDataServiceProtocol

        init(dataService: any ProductionDataServiceProtocol) {
            self.dataService = dataService
        }

        @Published var showNewTaskGroup: Bool = false
        @Published private(set) var typeList: [String] = []

        @Published var name: String = ""
        @Published var description: String = ""

        @Published var taskItemList: [JobTaskGroupItem] = []
        @Published var addNewItem: Bool = false

        @Published var itemName: String = ""
        @Published var itemType: JobTaskType = .basic
        @Published var itemDescription: String = ""
        @Published var itemRate: String = "0"
        @Published var itemEstimatedTime: String = "0"

        @Published var isSubmitting: Bool = false
        @Published var showError: Bool = false
        @Published var errorMessage: String = ""
        @Published var showSuccess: Bool = false

        var canAddItem: Bool {
            !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            Double(itemRate) != nil &&
            Int(itemEstimatedTime) != nil
        }

        var canSubmit: Bool {
            !isSubmitting &&
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !taskItemList.isEmpty
        }

        func onLoad(companyId: String) {
            Task {
                self.typeList = JobTaskType.allCases.map(\.rawValue)
            }
        }

        func validateRate() {
            guard !itemRate.isEmpty else { return }

            if Double(itemRate) == nil {
                itemRate = String(itemRate.dropLast())
            }
        }

        func validateEstimatedTime() {
            guard !itemEstimatedTime.isEmpty else { return }

            if Int(itemEstimatedTime) == nil {
                itemEstimatedTime = String(itemEstimatedTime.dropLast())
            }
        }

        func clearNewItem() {
            addNewItem = false
            itemEstimatedTime = "0"
            itemRate = "0"
            itemName = ""
            itemType = .basic
            itemDescription = ""
        }

        func addItemToList() {
            let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedName.isEmpty else {
                errorMessage = "Task name is required."
                showError = true
                return
            }

            guard let time = Int(itemEstimatedTime) else {
                errorMessage = "Estimated time must be a whole number."
                showError = true
                return
            }

            guard let rate = Double(itemRate) else {
                errorMessage = "Rate must be a valid number."
                showError = true
                return
            }

            let item = JobTaskGroupItem(
                id: UUID().uuidString,
                name: trimmedName,
                type: itemType,
                description: trimmedDescription,
                contractedRate: Int((rate * 100).rounded()),
                estimatedTime: time
            )

            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                taskItemList.append(item)
                showError = false
                errorMessage = ""
                clearNewItem()
            }

            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }

        func removeItem(_ item: JobTaskGroupItem) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                taskItemList.removeAll { $0.id == item.id }
            }
        }

        func submitNewTaskGroup(companyId: String, onSuccess: @escaping () -> Void) {
            Task {
                do {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !trimmedName.isEmpty else {
                        errorMessage = "Task group name is required."
                        showError = true
                        return
                    }

                    guard !taskItemList.isEmpty else {
                        errorMessage = "Add at least one task before submitting."
                        showError = true
                        return
                    }

                    isSubmitting = true
                    showError = false
                    errorMessage = ""

                    let taskGroupId = UUID().uuidString

                    #warning("Please update Job Task Group")
                    let taskGroup = JobTaskGroup(
                        id: taskGroupId,
                        name: trimmedName,
                        description: trimmedDescription,
                        defaultServiceStopTypeId: "",
                        defaultServiceStopTypeName: "",
                        numberOfTasks: taskItemList.count,
                        estimatedMinutes: 0,
                        estimatedLaborCents: 0,
                        isActive: true,
                        createdAt: Date(),
                        createdByUserId: ""
                    )

                    try await dataService.uploadNewTaskGroup(
                        companyId: companyId,
                        taskGroup: taskGroup
                    )

                    for item in taskItemList {
                        try await dataService.uploadNewTaskGroupItem(
                            companyId: companyId,
                            taskGroupId: taskGroupId,
                            taskGroupItem: item
                        )
                    }

                    print("Successfully Uploaded Task")
                    print(taskGroup)
                    print(taskItemList)

                    name = ""
                    description = ""
                    taskItemList = []
                    showSuccess = true
                    isSubmitting = false

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    onSuccess()
                } catch {
                    isSubmitting = false
                    showError = true
                    errorMessage = error.localizedDescription

                    print(error)

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }
    }

    struct AddNewTaskGroup: View {
        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject var masterDataManager: MasterDataManager
        @Environment(\.dismiss) private var dismiss

        @StateObject var VM: AddNewTaskGroupViewModel

        init(dataService: any ProductionDataServiceProtocol) {
            _VM = StateObject(wrappedValue: AddNewTaskGroupViewModel(dataService: dataService))
        }

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        detailsCard
                        tasksCard

                        if VM.showError {
                            errorCard
                        }

                        if VM.showSuccess {
                            successCard
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 96)
                }

                VStack {
                    Spacer()
                    bottomActionBar
                }
            }
            .task {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.onLoad(companyId: currentCompany.id)
                }
            }
            .onChange(of: VM.itemRate) { _ in
                VM.validateRate()
            }
            .onChange(of: VM.itemEstimatedTime) { _ in
                VM.validateEstimatedTime()
            }
        }
    }

    #Preview {
        AddNewTaskGroup(dataService: MockDataService())
    }

    // MARK: - Main Sections

    extension AddNewTaskGroup {

        var headerCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("New Task Group")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Create a reusable group of tasks that can be added to recurring service stops.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    Label("\(VM.taskItemList.count) Tasks", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())

                    Spacer()
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var detailsCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Details", systemImage: "folder")

                textInputRow(
                    title: "Name",
                    systemImage: "text.cursor",
                    placeholder: "Task group name",
                    text: $VM.name
                )

                descriptionInputRow(
                    title: "Description",
                    systemImage: "text.alignleft",
                    placeholder: "Optional description",
                    text: $VM.description,
                    minHeight: 80
                )
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var tasksCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Tasks", systemImage: "checklist")

                    Spacer()

                    if !VM.addNewItem {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                VM.addNewItem = true
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.accentColor.opacity(0.14), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if VM.taskItemList.isEmpty && !VM.addNewItem {
                    emptyTaskState
                }

                if !VM.taskItemList.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(VM.taskItemList) { item in
                            taskItemRow(item)
                        }
                    }
                }

                newItemSection
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: VM.addNewItem)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: VM.taskItemList)
        }

        var newItemSection: some View {
            VStack(spacing: 12) {
                if VM.addNewItem {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("New Task", systemImage: "plus.circle")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Spacer()

                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                    VM.clearNewItem()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(.thinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        textInputRow(
                            title: "Task Name",
                            systemImage: "text.cursor",
                            placeholder: "Task name",
                            text: $VM.itemName
                        )

                        pickerRow

                        descriptionInputRow(
                            title: "Description",
                            systemImage: "text.alignleft",
                            placeholder: "Optional task notes",
                            text: $VM.itemDescription,
                            minHeight: 80
                        )

                        HStack(spacing: 12) {
                            moneyInputRow
                            timeInputRow
                        }

                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                    VM.clearNewItem()
                                }
                            } label: {
                                Label("Clear", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                VM.addItemToList()
                            } label: {
                                Label("Add Task", systemImage: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(!VM.canAddItem)
                            .opacity(VM.canAddItem ? 1 : 0.45)
                        }
                    }
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            VM.addNewItem = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 30, height: 30)
                                .background(.thinMaterial, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Add New Task")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("Build the list of tasks for this group.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Feedback

    extension AddNewTaskGroup {

        var errorCard: some View {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Could not continue")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(VM.errorMessage.isEmpty ? "Please check the task group details." : VM.errorMessage)
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

        var successCard: some View {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Task group created")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("This group is ready to use.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Bottom Bar

    extension AddNewTaskGroup {

        var bottomActionBar: some View {
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.35)

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.submitNewTaskGroup(companyId: currentCompany.id) {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if VM.isSubmitting {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark")
                            }

                            Text(VM.isSubmitting ? "Saving" : "Create")
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!VM.canSubmit)
                    .opacity(VM.canSubmit ? 1 : 0.45)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }
    }

    // MARK: - Rows + Helpers

    extension AddNewTaskGroup {

        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }

        func textInputRow(
            title: String,
            systemImage: String,
            placeholder: String,
            text: Binding<String>
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

        func descriptionInputRow(
            title: String,
            systemImage: String,
            placeholder: String,
            text: Binding<String>,
            minHeight: CGFloat
        ) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextEditor(text: text)
                    .font(.subheadline)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(placeholder)
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }

        var pickerRow: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label("Type", systemImage: "tag")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Type", selection: $VM.itemType) {
                    ForEach(JobTaskType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }

        var moneyInputRow: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label("Rate", systemImage: "dollarsign.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("$")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("0", text: $VM.itemRate)
                        .font(.subheadline)
                        .keyboardType(.decimalPad)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }

        var timeInputRow: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label("Time", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    TextField("0", text: $VM.itemEstimatedTime)
                        .font(.subheadline)
                        .keyboardType(.numberPad)

                    Text("min")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }

        func taskItemRow(_ item: JobTaskGroupItem) -> some View {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 10) {
                        Label("\(item.estimatedTime) min", systemImage: "clock")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(Double(item.contractedRate) / 100, format: .currency(code: "USD"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    VM.removeItem(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var emptyTaskState: some View {
            VStack(spacing: 8) {
                Image(systemName: "checklist.unchecked")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("No tasks added yet.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Add at least one task before creating this group.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
