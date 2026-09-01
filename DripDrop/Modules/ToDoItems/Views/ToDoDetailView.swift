//
//  ToDoDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/28/24.
//

import SwiftUI

struct ToDoDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    @Environment(\.dismiss) private var dismiss

    @StateObject var toDoVM : ToDoViewModel
    private let todoId: String?
    
    init(dataService:any ProductionDataServiceProtocol, todoId: String? = nil){
        self.todoId = todoId
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }
    
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var status: toDoStatus = .toDo
    @State private var description: String = ""
    @State private var title: String = ""
    @State private var isSaving: Bool = false
    @State private var isAddingCustomerNote: Bool = false
    @State private var customerNoteMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if toDoVM.isLoading && currentTodo == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 44)
                } else if let toDo = currentTodo {
                    headerCard(toDo)
                    editorCard(toDo)
                    if linkedCustomerId(for: toDo) != nil {
                        customerNoteActionCard(toDo)
                    }
                    metadataCard(toDo)
                } else {
                    emptyState
                }
            }
            .padding(16)
        }
        .background(Color.listColor.ignoresSafeArea())
        .navigationTitle("Issue Details")
        .task(id: loadIdentity) {
            await loadTodo()
        }
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Delete todo?"),
                message: Text("This removes the todo item from the shared board."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        await deleteTodo()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task {
                        await saveTodo()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                .disabled(currentTodo == nil || isSaving)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(currentTodo == nil || isSaving)
            }
        }
    }
}

private extension ToDoDetailView {
    var currentTodo: ToDo? {
        toDoVM.selectedToDo ?? masterDataManager.selectedToDo
    }

    var loadIdentity: String {
        "\(masterDataManager.currentCompany?.id ?? "no-company")-\(todoId ?? masterDataManager.selectedToDo?.id ?? "no-todo")"
    }

    func loadTodo() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            if let todoId {
                try await toDoVM.readToDo(companyId: company.id, toDoId: todoId)
                applyFormValues(from: toDoVM.selectedToDo)
            } else {
                applyFormValues(from: masterDataManager.selectedToDo)
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func applyFormValues(from toDo: ToDo?) {
        guard let toDo else { return }
        status = toDo.status
        title = toDo.title
        description = toDo.description
    }

    func saveTodo() async {
        guard let company = masterDataManager.currentCompany, let toDo = currentTodo else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await toDoVM.updateToDoWithValidation(
                companyId: company.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                status: status,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                dateFinished: status == .finished ? Date() : nil,
                linkedCustomerId: toDo.linkedCustomerId,
                linkedJobId: toDo.linkedJobId,
                assignedTechId: toDo.assignedToUserId,
                toDo: toDo
            )

            if let todoId = todoId ?? currentTodo?.id {
                try await toDoVM.readToDo(companyId: company.id, toDoId: todoId)
                applyFormValues(from: toDoVM.selectedToDo)
            }

            alertMessage = "Todo updated."
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func deleteTodo() async {
        guard let company = masterDataManager.currentCompany, let toDo = currentTodo else { return }

        do {
            try await toDoVM.deleteToDoItem(companyId: company.id, toDoId: toDo.id)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func headerCard(_ toDo: ToDo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(toDo.issueKey) | \(toDo.boardName.isEmpty ? "No board" : toDo.boardName)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.poolBlue)
                        .textCase(.uppercase)

                    Text(toDo.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "checklist")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.poolBlue)
            }

            HStack(spacing: 7) {
                pill(text: toDo.statusLabel, color: statusColor(toDo))
                pill(text: toDo.priorityLabel, color: priorityColor(toDo.priority))
                pill(text: toDo.dueLabel, color: dueColor(toDo))
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func editorCard(_ toDo: ToDo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Title", text: $title, axis: .vertical)
                    .font(.body.weight(.semibold))
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Status")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Status", selection: $status) {
                    ForEach(toDoStatus.allCases,id: \.self) { status in
                        Text(status.title()).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func metadataCard(_ toDo: ToDo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            metadataRow("Assignee", toDo.assignmentLabel, systemImage: "person")
            metadataRow("Board", toDo.boardName.isEmpty ? "No board" : toDo.boardName, systemImage: "rectangle.3.group")
            metadataRow("Created", shortDateAndTime(date: toDo.dateCreated), systemImage: "calendar")
            metadataRow("Updated", shortDateAndTime(date: toDo.updatedAt), systemImage: "clock")

            if toDo.reminderEnabled {
                metadataRow("Alert", shortDateAndTime(date: toDo.reminderAt ?? toDo.dueAt), systemImage: "bell")
            }

            if let relatedEntity = toDo.relatedEntity {
                metadataRow(
                    "Linked record",
                    "\(relatedEntity.type): \(relatedEntity.label.isEmpty ? relatedEntity.id : relatedEntity.label)",
                    systemImage: "link"
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func customerNoteActionCard(_ toDo: ToDo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Customer Notes")
                        .font(.headline)

                    Text(linkedCustomerName(for: toDo) ?? "Linked customer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            if let customerNoteMessage {
                Text(customerNoteMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(customerNoteMessage == "Added to customer notes." ? Color.poolGreen : Color.poolRed)
                    .lineLimit(2)
            }

            Button {
                Task {
                    await addTodoToCustomerNotes(toDo)
                }
            } label: {
                if isAddingCustomerNote {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    Label("Add to Customer Notes", systemImage: "plus.message.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAddingCustomerNote)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func metadataRow(_ title: String, _ value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "None" : value)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }

    func linkedCustomerId(for toDo: ToDo) -> String? {
        if let linkedCustomerId = toDo.linkedCustomerId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !linkedCustomerId.isEmpty {
            return linkedCustomerId
        }

        guard let relatedEntity = toDo.relatedEntity else {
            return nil
        }

        let relatedType = relatedEntity.type
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard relatedType == "customer" || relatedType == "customers" else {
            return nil
        }

        let relatedId = relatedEntity.id.trimmingCharacters(in: .whitespacesAndNewlines)
        return relatedId.isEmpty ? nil : relatedId
    }

    func linkedCustomerName(for toDo: ToDo) -> String? {
        guard let relatedEntity = toDo.relatedEntity else {
            return nil
        }

        let relatedType = relatedEntity.type
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard relatedType == "customer" || relatedType == "customers" else {
            return nil
        }

        let label = relatedEntity.label.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? nil : label
    }

    var currentUserDisplayName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        if !fullName.isEmpty {
            return fullName
        }

        return masterDataManager.user?.email ?? "Company user"
    }

    func customerNoteText(for toDo: ToDo) -> String {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? toDo.title.trimmingCharacters(in: .whitespacesAndNewlines)
            : title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? toDo.description.trimmingCharacters(in: .whitespacesAndNewlines)
            : description.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines = [
            "Todo \(toDo.issueKey): \(cleanTitle)",
            "Status: \(status.title())",
            "Priority: \(toDo.priorityLabel)"
        ]

        if !cleanDescription.isEmpty {
            lines.append("")
            lines.append(cleanDescription)
        }

        return lines.joined(separator: "\n")
    }

    @MainActor
    func addTodoToCustomerNotes(_ toDo: ToDo) async {
        guard let company = masterDataManager.currentCompany else {
            customerNoteMessage = "Missing company."
            return
        }

        guard let customerId = linkedCustomerId(for: toDo) else {
            customerNoteMessage = "Todo is not linked to a customer."
            return
        }

        isAddingCustomerNote = true
        defer { isAddingCustomerNote = false }

        let userId = masterDataManager.user?.id ?? toDo.createdByUserId
        let authorName = currentUserDisplayName
        let now = Date()
        let noteText = customerNoteText(for: toDo)
        let note = CustomerNote(
            storedId: "comp_cus_note_\(UUID().uuidString)",
            companyId: company.id,
            customerId: customerId,
            customerName: linkedCustomerName(for: toDo),
            userId: userId,
            userName: authorName,
            authorId: userId,
            authorName: authorName,
            note: noteText,
            comment: noteText,
            audience: .all,
            visibility: CustomerNoteAudience.all.rawValue,
            resolved: false,
            date: now,
            createdAt: now,
            updatedAt: now
        )

        do {
            try await toDoVM.dataService.uploadCustomerNote(
                companyId: company.id,
                customerId: customerId,
                note: note
            )
            customerNoteMessage = "Added to customer notes."
        } catch {
            customerNoteMessage = "Could not add customer note."
            print("[ToDoDetailView][addTodoToCustomerNotes] \(error)")
        }
    }

    var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Select a todo")
                .font(.subheadline.weight(.semibold))
            Text("Tap a todo from the snapshot or todo list to view details.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    func statusColor(_ toDo: ToDo) -> Color {
        if toDo.needsAttention {
            return .orange
        }

        switch toDo.statusKey {
        case "inprogress":
            return .poolBlue
        case "done", "finished", "complete", "completed":
            return .poolGreen
        default:
            return .gray
        }
    }

    func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent":
            return .poolRed
        case "high":
            return .orange
        case "low":
            return .poolGreen
        default:
            return .secondary
        }
    }

    func dueColor(_ toDo: ToDo) -> Color {
        switch toDo.dueState {
        case .overdue:
            return .poolRed
        case .today:
            return .orange
        case .upcoming:
            return .poolBlue
        case .complete:
            return .poolGreen
        case .none:
            return .gray
        }
    }
}

struct ToDoDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ToDoDetailView(dataService: dataService, todoId: "todo_12345")
    }
}
