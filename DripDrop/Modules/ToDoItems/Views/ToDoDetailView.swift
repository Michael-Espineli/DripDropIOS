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
    
    init(dataService:any ProductionDataServiceProtocol){
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeleteConfirmation:Bool = false
    @State var status:toDoStatus = .toDo
    @State var description:String = ""
    @State var title:String = ""

    
    var body: some View {
        ScrollView{
            if let toDo = masterDataManager.selectedToDo{
                
                Text("\(toDo.id)")
                VStack{
                    HStack{
                        TextField(
                            "Title",
                            text: $title
                        )
                        .padding(5)
                        .background(Color.gray)
                        .foregroundColor(Color.black)
                        .cornerRadius(5)
               
                    }
                    Text("\(fullDate(date:toDo.dateCreated))")
                    TextField(
                        "Description",
                        text: $description
                    )
                    .padding(5)
                    .background(Color.gray)
                    .foregroundColor(Color.black)
                    .cornerRadius(5)

                    HStack{
                        Picker("", selection: $status) {
                            Text("Pick WorkSheet")
                            ForEach(toDoStatus.allCases,id: \.self) { status in
                                    Text(status.title()).tag(status)
                                        .foregroundColor(status.color())
                            }
                         
                        }
                        
                    }
                }
            }
        }

        .task {
            if let toDo = masterDataManager.selectedToDo {
                status = toDo.status
                title = toDo.title
                description = toDo.description
            }
        }
        .onChange(of: status, perform: { status in
            Task{
                if let company = masterDataManager.currentCompany, let toDo = masterDataManager.selectedToDo {
                    do {
                        try await toDoVM.updateToDoWithValidation(companyId: company.id,
                                                                  title: toDo.title,
                                                                  status: status,
                                                                  description: toDo.description,
                                                                  dateFinished: Date(),
                                                                  linkedCustomerId: toDo.linkedCustomerId,
                                                                  linkedJobId: toDo.linkedJobId,
                                                                  assignedTechId: toDo.assignedTechId,
                                                                  toDo: toDo)
                    } catch {
                        print(error)
                    }
                    
                }
            }
        })
        .onChange(of: title, perform: { title in
            Task{
                if let company = masterDataManager.currentCompany, let toDo = masterDataManager.selectedToDo {
                    do {
                        try await toDoVM.updateToDoWithValidation(companyId: company.id,
                                                                  title: title,
                                                                  status: toDo.status,
                                                                  description: toDo.description,
                                                                  dateFinished: Date(),
                                                                  linkedCustomerId: toDo.linkedCustomerId,
                                                                  linkedJobId: toDo.linkedJobId,
                                                                  assignedTechId: toDo.assignedTechId,
                                                                  toDo: toDo)
                    } catch {
                        print(error)
                    }
                    
                }
            }
        })
        .onChange(of: description, perform: { description in
            Task{
                if let company = masterDataManager.currentCompany, let toDo = masterDataManager.selectedToDo {
                    do {
                        try await toDoVM.updateToDoWithValidation(companyId: company.id,
                                                                  title: toDo.title,
                                                                  status: toDo.status,
                                                                  description: description,
                                                                  dateFinished: Date(),
                                                                  linkedCustomerId: toDo.linkedCustomerId,
                                                                  linkedJobId: toDo.linkedJobId,
                                                                  assignedTechId: toDo.assignedTechId,
                                                                  toDo: toDo)
                    } catch {
                        print(error)
                    }
                    
                }
            }
        })
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
   
                    Task{
                        print("Deleting...")
                        if let company = masterDataManager.currentCompany, let toDo = masterDataManager.selectedToDo {
                            do {
                                try await toDoVM.deleteToDoItem(companyId: company.id, toDoId: toDo.id)
                                dismiss()
                            } catch {
                                print(error)
                            }
                        } else {
                            print("Not Selected Propperly Company or Shopping List item")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar{
            Button(action: {
                showDeleteConfirmation = true
            }, label: {
                Text("Delete")
            })
        }
    }
}

struct ToDoDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ToDoDetailView(dataService: dataService)
    }
}
