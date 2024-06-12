//
//  AddToDoItem.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/28/24.
//

import SwiftUI

struct AddToDoItem: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var toDoVM : ToDoViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }
    //Strings
    @State var title:String = ""
    @State var description:String = ""
    @State var linkedCustomerId:String = ""
    @State var customerName:String = ""
    @State var linkedJobId:String = ""
    @State var job:String = ""
    @State var assignedTechId:String = ""
    @State var techName:String = ""
    @State var alertMessage:String = ""

    //Bools
    @State var showSelectCustomer:Bool = false
    @State var showSelectJob:Bool = false
    @State var showSelectTech:Bool = false
    @State var showAlert:Bool = false
    
    //Dates
    @State var dateCreated:Date = Date()

    //Ints
    //Custom
    @State var status:toDoStatus = .toDo
    @State var customerEntity:Customer = Customer(id: "",
                                                  firstName: "",
                                                  lastName: "",
                                                  email: "",
                                                  billingAddress: Address(streetAddress: "",
                                                                          city: "",
                                                                          state: "",
                                                                          zip: "",
                                                                          latitude: 0,
                                                                          longitude: 0),
                                                  active: true,
                                                  displayAsCompany: false,
                                                  hireDate: Date(),
                                                  billingNotes: "")

    @State var jobEntity:Job = Job(id: "",
                                         type: "",
                                         dateCreated: Date(),
                                         description: "",
                                   operationStatus: .estimatePending,
                                   billingStatus: .draft,
                                         customerId: "",
                                         customerName: "",
                                         serviceLocationId: "",
                                         serviceStopIds: [],
                                         adminId: "",
                                         adminName: "",
                                         jobTemplateId: "",
                                         installationParts: [],
                                         pvcParts: [],
                                         electricalParts: [],
                                         chemicals: [],
                                         miscParts: [],
                                         rate: 0,
                                         laborCost: 0)
    
    @State var tech:CompanyUser = CompanyUser(id: "",
                                              userId: "",
                                              userName: "",
                                              roleId: "",
                                              roleName: "",
                                              dateCreated: Date(),
                                              status: .active)

    var body: some View {
        VStack{
            form
            button
        }
        .padding(10)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct AddToDoItem_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        AddToDoItem(dataService: dataService)
    }
}
extension AddToDoItem{
    var form: some View {
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
            Picker("Status", selection: $status, content: {
                ForEach(toDoStatus.allCases,id:\.self){ status in
                    Text(status.title()).tag(status)
                }
            })
            HStack{
                TextField(
                    "Description",
                    text: $description
                )
                .padding(5)
                .background(Color.gray)
                .foregroundColor(Color.black)
                .cornerRadius(5)
            }
            HStack{
                Text("Date Created : \(fullDate(date:Date()))")
                Spacer()
            }
            HStack{
                if customerEntity.id == "" {
                    Button(action: {
                        showSelectCustomer.toggle()
                    }, label: {
                        Text("Add Customer")
                    })
                    .foregroundColor(Color.black)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                } else {
                    Text("Customer Name: \(customerEntity.firstName) \(customerEntity.lastName)")
                    Button(action: {
                        showSelectCustomer.toggle()
                    }, label: {
                        Image(systemName: "gobackward")
                        .foregroundColor(Color.black)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                    })
                }
                Spacer()
            }
            .sheet(isPresented: $showSelectCustomer, content: {
                CustomerPickerScreen(dataService: dataService,customer: $customerEntity)
            })

            HStack{
                if jobEntity.id == "" {
                    Button(action: {
                        showSelectJob.toggle()
                    }, label: {
                        Text("Add Job")
                    })
                    .foregroundColor(Color.black)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                } else {
                    Text("Job: \(jobEntity.id)")
                    Button(action: {
                        showSelectJob.toggle()
                    }, label: {
                        Image(systemName: "gobackward")
                        .foregroundColor(Color.black)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                    })
                }
                Spacer()
            }
            .sheet(isPresented: $showSelectJob, content: {
                JobPickerScreen(dataService: dataService, job: $jobEntity)
            })
            HStack{
                if customerEntity.id == "" {
                    Button(action: {
                        showSelectTech.toggle()
                    }, label: {
                        Text("Assign Tech")
                    })
                    .foregroundColor(Color.black)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                } else {
                    Text("Tech Name: \(tech.userName)")
                    Button(action: {
                        showSelectTech.toggle()
                    }, label: {
                        Image(systemName: "gobackward")
                        .foregroundColor(Color.black)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                    })
                }
                Spacer()
            }
            .sheet(isPresented: $showSelectTech, content: {
                TechPickerScreen(tech: $tech)
            })
            
        }
    }
    var button: some View {
        HStack{
            Spacer()
            Button(action: {
                Task{
                    if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                        do {
                            try await toDoVM.createToDoWithValidation(companyId: company.id,
                                                                      title: title,
                                                                      status: status,
                                                                      description: description,
                                                                      dateCreated: Date(),
                                                                      dateFinished: nil,
                                                                      linkedCustomerId: customerEntity.id,
                                                                      linkedJobId: jobEntity.id,
                                                                      assignedTechId: tech.userId,
                                                                      creatorId: user.id)
                            alertMessage = "Successfully Added"
                            print(alertMessage)
                            showAlert = true
                        } catch ToDoError.invalidTechId{
                            alertMessage = ToDoError.invalidTechId.errorDescription()
                            print(alertMessage)
                            showAlert = true
                        } catch ToDoError.invalidTitle {
                            alertMessage = ToDoError.invalidTitle.errorDescription()
                            print(alertMessage)
                            showAlert = true
                        } catch {
                            print(error)
                        }
                    }
                }
            }, label: {
                Text("Save")
                    .foregroundColor(Color.black)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
            })
        }
        .padding(5)
    }
}
