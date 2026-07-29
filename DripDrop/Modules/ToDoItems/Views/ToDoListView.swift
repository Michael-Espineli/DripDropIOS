//
//  ToDoListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//

import SwiftUI

private enum ToDoListFilter: String, CaseIterable, Identifiable {
    case open
    case mine
    case attention
    case done
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open:
            return "Open"
        case .mine:
            return "Mine"
        case .attention:
            return "Attention"
        case .done:
            return "Done"
        case .all:
            return "All"
        }
    }
}

struct ToDoListView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var toDoVM : ToDoViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }

    @State private var showAddToDo: Bool = false
    @State private var selectedFilter: ToDoListFilter = .open

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                summaryCard
                filterPicker

                if toDoVM.isLoading && toDoVM.toDoList.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if let errorMessage = toDoVM.errorMessage {
                    emptyState(
                        title: "Todos unavailable",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle"
                    )
                } else if filteredTodos.isEmpty {
                    emptyState(
                        title: "No todos here",
                        message: "Items from the web todo board will show in this view.",
                        systemImage: "checkmark.circle"
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredTodos) { toDo in
                            NavigationLink(value: Route.todoItemDetail(todoId: toDo.id, dataService: dataService)) {
                                ToDoCardView(toDo: toDo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.listColor.ignoresSafeArea())
        .navigationTitle("Todos")
        .toolbar{
            Button(action: {
                showAddToDo.toggle()
            }, label: {
                Image(systemName: "plus.square.fill")
            })
            .sheet(isPresented: $showAddToDo, onDismiss: {
                Task {
                    await loadTodos()
                }
            }, content: {
                AddToDoItem(dataService: dataService)
            })
        }
        .refreshable {
            await loadTodos()
        }
        .task(id: masterDataManager.currentCompany?.id) {
            await loadTodos()
        }
    }
}

private extension ToDoListView {
    var currentUserId: String {
        masterDataManager.user?.id ?? masterDataManager.companyUser?.userId ?? ""
    }

    var openTodos: [ToDo] {
        toDoVM.toDoList.filter { $0.isOpen }.sorted(by: ToDo.sortByUrgency)
    }

    var mineTodos: [ToDo] {
        openTodos.filter { currentUserId.isEmpty ? false : $0.isAssigned(to: currentUserId) }
    }

    var attentionTodos: [ToDo] {
        openTodos.filter { $0.needsAttention }
    }

    var doneTodos: [ToDo] {
        toDoVM.toDoList.filter { !$0.isOpen && !$0.isArchived }
    }

    var filteredTodos: [ToDo] {
        switch selectedFilter {
        case .open:
            return openTodos
        case .mine:
            return mineTodos
        case .attention:
            return attentionTodos
        case .done:
            return doneTodos
        case .all:
            return toDoVM.toDoList.filter { !$0.isArchived }.sorted(by: ToDo.sortByUrgency)
        }
    }

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Todo Snapshot")
                        .font(.headline)
                    Text("\(openTodos.count) open, \(attentionTodos.count) need attention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "checklist")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.poolBlue)
            }

            HStack(spacing: 8) {
                metric(title: "Open", value: "\(openTodos.count)", tint: .poolBlue)
                metric(title: "Mine", value: "\(mineTodos.count)", tint: .poolGreen)
                metric(title: "Done", value: "\(doneTodos.count)", tint: .gray)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var filterPicker: some View {
        Picker("Todo Filter", selection: $selectedFilter) {
            ForEach(ToDoListFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    func metric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func loadTodos() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            toDoVM.errorMessage = nil
            try await toDoVM.readToDoCompanyList(companyId: company.id)
        } catch {
            toDoVM.errorMessage = error.localizedDescription
        }
    }
}

struct ToDoListView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ToDoListView(dataService: dataService)
    }
}
