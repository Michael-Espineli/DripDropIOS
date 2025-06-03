//
//  ToDoListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//

import SwiftUI

struct ToDoListView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var toDoVM : ToDoViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }
    @State var showAddToDo:Bool = false
    var body: some View {
        ScrollView{
            Text("To Do List")
                .font(.headline)
            Divider()
            ForEach(toDoVM.toDoList){ toDo in
                    NavigationLink(value: Route.toDoDetail(dataService: dataService), label: {

                    ToDoCardView(toDo: toDo)
                })
                Divider()
            }
        }
        .toolbar{
            Button(action: {
                showAddToDo.toggle()
            }, label: {
                Image(systemName: "plus.square.fill")
            })
            .sheet(isPresented: $showAddToDo, content: {
                AddToDoItem(dataService: dataService)
            })
        }
        .task {
            if let company = masterDataManager.currentCompany, let tech = masterDataManager.user {
                do {
                    try await toDoVM.readToDoTechList(companyId: company.id, techId: tech.id)
                } catch {
                    print("Error")
                }
            }
        }
    }
}

struct ToDoListView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ToDoListView(dataService: dataService)
    }
}
