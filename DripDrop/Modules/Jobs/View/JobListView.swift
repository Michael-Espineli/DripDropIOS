//
//  JobListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//
//



import SwiftUI
import Contacts

struct JobListView: View{
//    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject private var jobVM : JobViewModel
    @StateObject var companyUserVM = CompanyUserViewModel()

    init(dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
    }


    @State var selectedDocumentUrl:URL? = nil

//    @State private var selected = Set<Customer.ID>()
//    @State private var selection: Customer.ID? = nil
//    @State private var selectedCustomer: Customer? = nil
    
    
    @State private var jobs:[Job] = []
//    @State private var sortOrder = [KeyPathComparator(\Customer.lastName, order: .forward)]
    
    @State private var isPresented: Bool = false
    @State private var editing: Bool = false
    @State private var isLoading: Bool = false
    @State var searchTerm:String = ""
    @State private var nav: Bool = false
    @State var showActive:Bool = true
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showCustomerPicker:Bool = false
    
    @State var showSearch:Bool = false
    @State var showAddNew:Bool = false
    @State private var pickerType:NewCustomerPickerType? = nil
    @State private var selectedPickerType:NewCustomerPickerType? = nil
    @State var showConfirmationSheet:Bool = false

    @State var selectedContact:CNContact? = nil
    @State var showFilters:Bool = false
    @State var showCustomerUploadScreen:Bool = false
    @State var recievdJobId:String? = nil
    
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()

    @State var selectedStatus:[JobOperationStatus] = [.scheduled,.unscheduled,.estimatePending,.inProgress]
    @State var techIds:[String] = []
    var body: some View{
            ZStack{
                Color.listColor.ignoresSafeArea()
                   list
                icons
            }
            .navigationTitle("Job - \(jobs.count)")
        .task {
            if let company = masterDataManager.selectedCompany {
                
                do {
                    techIds = []
                    
                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    for companyUser in companyUserVM.companyUsers {
                        techIds.append(companyUser.userId)
                    }
                    
                } catch {
                    print("Error Getting Users By status")
                }
            
                do {
                    startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
                    try await jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                    
                } catch {
                    alertMessage = "Unable to get Jobs"
                    showAlert = true
                }
            }
        }
        .onChange(of: jobVM.workOrders, perform: { list in
            print("Change in WorkOrders")
            jobs = list
        })
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                            try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: selectedId)
                            masterDataManager.selectedWorkOrder = jobVM.workOrder
                            print("Successfully Get Customer")
                        }
                    } catch {
                        print("Failed to Get Customer")
                    }
                }
            }
        })
        .alert(isPresented:$showAlert) {
            Alert(
                title: Text("\(alertMessage)"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }

        .onChange(of: selectedDocumentUrl, perform: { doc in
            showCustomerUploadScreen = true
        })
        .onChange(of: searchTerm){ term in
       print(" Add Search Function")
        }
    }
    
}

extension JobListView {
    var list: some View {
        VStack{
            if jobs.count == 0 {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("3") {
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            Text("Add New Job")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                        })
                        .sheet(isPresented: $showAddNew, content: {
                            VStack{
                   
                                AddNewJobView(dataService: dataService)
                            }
                        })
                    }}
            } else {
                List(selection:$masterDataManager.selectedID){

                ForEach(jobs){ job in
                    NavigationLink(value: Route.job(job: job,dataService:dataService), label: {
                        JobCardView(job: job)
                    })
                    /*
                    NavigationLink(destination: {
                        CustomerDetailView(customer: customer)
                    }, label: {
                        CustomerCardViewSmall(customer: customer)
                    })
                     */
                }
            }
        }
        }
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        showFilters.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color.white)
                            )
                        }
                    })
                    .padding(10)
                    .sheet(isPresented: $showFilters,onDismiss: {
                        Task{
                            if let company = masterDataManager.selectedCompany {
                                do {
                                    jobVM.removeListenerForJob()
                                    jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)

                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, content: {
                        VStack(alignment: .leading){
                            HStack{
                                Text("Start Date: ")
                                DatePicker(selection: $startDate, displayedComponents: .date) {
                                }
                            }
                            HStack{
                                Text("End Date: ")
                                
                                DatePicker(selection: $endDate, displayedComponents: .date) {
                                }
                            }
                            HStack{
                                Text("Status: ")
                                Spacer()
                                Menu("Status  - \(selectedStatus.count)") {
                                    Button(action: {
                                        print("All Selected")
                                        selectedStatus = []
                                        for status in JobOperationStatus.allCases {
                                            selectedStatus.append(status)
                                        }

                                    }, label: {
                                        Text("All \(selectedStatus == JobOperationStatus.allCases ? "✓" : "")")
                                    })
                                    
                                    ForEach(JobOperationStatus.allCases,id:\.self) { status in
                                        Button(action: {
                                            if selectedStatus.contains(status) {
                                                selectedStatus.removeAll(where: {$0 == status})
                                                print("Removed \(status.rawValue)")
                                            } else {
                                                print("Added \(status.rawValue)")

                                                selectedStatus.append(status)
                                            }
                                        }, label: {
                                            Text("\(status.rawValue) \(selectedStatus.contains(status) ? "✓" : "")")
                                        })
                                    }
                                    Button(action: {
                                        selectedStatus = []
                                    }, label: {
                                        Text("Clear \(selectedStatus == [] ? "✓" : "")")
                                    })
                                }
                                Spacer()
                            }
                            HStack{
                                Text("Techs: ")
                                Spacer()
                                Menu("Techs \(techIds.count)") {
                                    Button(action: {
                                        print("All Selected")
                                        techIds = []
                                        for tech in companyUserVM.companyUsers {
                                            techIds.append(tech.userId)
                                        }

                                    }, label: {
                                        Text("All \(techIds.count == companyUserVM.companyUsers.count ? "✓" : "")")
                                    })
                                    
                                    ForEach(companyUserVM.companyUsers) { tech in
                                        Button(action: {
                                            if techIds.contains(tech.userId) {
                                                techIds.removeAll(where: {$0 == tech.userId})
                                                print("Removed \(tech.userName)")
                                            } else {
                                                print("Added \(tech.userName)")

                                                techIds.append(tech.userId)
                                            }
                                        }, label: {
                                            Text("\(tech.userName) \(techIds.contains(tech.userId) ? "✓" : "")")
                                        })
                                    }
                                    Button(action: {
                                        techIds = []
                                    }, label: {
                                        Text("Clear \(techIds == [] ? "✓" : "")")
                                    })
                                }
                            }
                            Spacer()

                        }
                 
                    })
                    if let role = masterDataManager.role {
                        if role.permissionIdList.contains("3") {
                            Button(action: {
                                showCustomerPicker.toggle()
                            }, label: {
                                ZStack{
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.green)
                                }
                            })
                            .padding(10)
                            .sheet(isPresented: $showCustomerPicker, content: {
                                VStack{
                        
                                    AddNewJobView(dataService: dataService)
                                }
                            })
                        }
                    }
                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                        }
                    })
                    .padding(10)
                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
                        text: $searchTerm
                    )
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                }
            }
            
        }
    }
}
