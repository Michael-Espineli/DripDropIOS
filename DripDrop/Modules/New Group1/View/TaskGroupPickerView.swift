    //
    //  TaskGroupPickerView.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/9/24.
    //

    import SwiftUI

    @MainActor
    final class TaskGroupPickerViewModel: ObservableObject {
        let dataService: any ProductionDataServiceProtocol

        init(dataService: any ProductionDataServiceProtocol) {
            self.dataService = dataService
        }

        @Published private(set) var taskGroupList: [JobTaskGroup] = []
        @Published private(set) var taskGroupItems: [JobTaskGroupItem] = []

        @Published var selectedTaskGroup: JobTaskGroup? = nil
        @Published var isLoadingGroups: Bool = false
        @Published var isLoadingItems: Bool = false
        @Published var didSelectGroup: Bool = false

        @Published var showAddNewTaskGroup: Bool = false

        func onload(companyId: String) {
            Task {
                do {
                    isLoadingGroups = true
                    self.taskGroupList = try await dataService.getAllTaskGroups(companyId: companyId)
                    isLoadingGroups = false
                } catch {
                    isLoadingGroups = false
                    print(error)
                }
            }
        }

        func onChangeOfTaskGroup(companyId: String) {
            guard let selectedTaskGroup else { return }

            Task {
                do {
                    isLoadingItems = true
                    self.taskGroupItems = try await dataService.getAllTaskGroupItems(
                        companyId: companyId,
                        taskGroupId: selectedTaskGroup.id
                    )
                    isLoadingItems = false
                } catch {
                    isLoadingItems = false
                    print(error)
                }
            }
        }

        func clearSelectedGroup() {
            selectedTaskGroup = nil
            taskGroupItems = []
            didSelectGroup = false
        }
    }

    struct TaskGroupPickerView: View {
        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject var masterDataManager: MasterDataManager
        @Environment(\.dismiss) private var dismiss

        @StateObject var VM: TaskGroupPickerViewModel
        @Binding var tasks: [JobTaskGroupItem]

        init(dataService: any ProductionDataServiceProtocol, tasks: Binding<[JobTaskGroupItem]>) {
            _VM = StateObject(wrappedValue: TaskGroupPickerViewModel(dataService: dataService))
            self._tasks = tasks
        }

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header

                        if VM.selectedTaskGroup != nil {
                            detail
                        } else {
                            list
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
            .task {
                reloadTaskGroups()
            }
            .onChange(of: VM.selectedTaskGroup) { _ in
                if let currentCompany = masterDataManager.currentCompany {
                    VM.onChangeOfTaskGroup(companyId: currentCompany.id)
                }
            }
            .sheet(isPresented: $VM.showAddNewTaskGroup, onDismiss: {
                reloadTaskGroups()

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }) {
                AddNewTaskGroup(dataService: dataService)
            }
        }
    }

    //#Preview {
    //    TaskGroupPickerView()
    //}

    extension TaskGroupPickerView {

        var header: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(VM.selectedTaskGroup == nil ? "Task Groups" : "Group Preview")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(VM.selectedTaskGroup == nil ? "Choose a saved task group to add to this stop." : "Review the tasks before adding this group.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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

                if VM.didSelectGroup {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")

                        Text("Task group selected")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: VM.didSelectGroup)
        }

        var list: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionHeader("Available Groups", systemImage: "square.stack.3d.up")

                    Spacer()

                    Button {
                        VM.showAddNewTaskGroup.toggle()
                    } label: {
                        Label("New", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    VM.showAddNewTaskGroup.toggle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                            .background(.thinMaterial, in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Create New Task Group")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Add a new saved group, then choose it here.")
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

                if VM.isLoadingGroups {
                    loadingState("Loading task groups...")
                } else if VM.taskGroupList.isEmpty {
                    emptyState(
                        title: "No Task Groups",
                        message: "Create a task group first, then it will show up here.",
                        systemImage: "folder.badge.questionmark"
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(VM.taskGroupList) { group in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                    VM.selectedTaskGroup = group
                                }
                            } label: {
                                taskGroupRow(group)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var detail: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            VM.clearSelectedGroup()
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        selectGroupAndDismiss()
                    } label: {
                        Label("Use Group", systemImage: "checkmark")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.accentColor.opacity(0.16), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(VM.isLoadingItems || VM.taskGroupItems.isEmpty)
                    .opacity((VM.isLoadingItems || VM.taskGroupItems.isEmpty) ? 0.45 : 1)
                }

                if let selectedTaskGroup = VM.selectedTaskGroup {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedTaskGroup.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if !selectedTaskGroup.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(selectedTaskGroup.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(selectedTaskGroup.numberOfTasks) tasks")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                    .opacity(0.45)

                sectionHeader("Tasks in Group", systemImage: "checklist")

                if VM.isLoadingItems {
                    loadingState("Loading tasks...")
                } else if VM.taskGroupItems.isEmpty {
                    emptyState(
                        title: "No Tasks Found",
                        message: "This group does not have any task items yet.",
                        systemImage: "checklist.unchecked"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(VM.taskGroupItems) { item in
                            taskItemRow(item)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        func reloadTaskGroups() {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onload(companyId: currentCompany.id)
            }
        }

        func selectGroupAndDismiss() {
            tasks = VM.taskGroupItems

            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                VM.didSelectGroup = true
            }

            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif

            dismiss()
        }

        func taskGroupRow(_ group: JobTaskGroup) -> some View {
            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !group.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(group.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("\(group.numberOfTasks) tasks")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        func taskItemRow(_ item: JobTaskGroupItem) -> some View {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }

        func loadingState(_ text: String) -> some View {
            HStack(spacing: 10) {
                ProgressView()

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }

        func emptyState(title: String, message: String, systemImage: String) -> some View {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
