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
    
    init(dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var jobVM : JobViewModel
    @StateObject var companyUserVM = CompanyUserViewModel()

    @State var selectedDocumentUrl:URL? = nil
    @State private var jobs:[Job] = []
    //    @State private var sortOrder = [KeyPathComparator(\Customer.lastName, order: .forward)]
    
    @State private var isPresented: Bool = false
    @State private var editing: Bool = false
    @State private var isLoading: Bool = false

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
    
    @State var selectedStatus:[JobOperationStatus] = [.scheduled, .unscheduled, .estimatePending, .inProgress]
    @State var techIds:[String] = []
    @State private var showCreateJobOptions: Bool = false
    @State private var showCreateBlankJob: Bool = false
    @State private var showCreateFromTemplate: Bool = false
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            icons
        }
        .navigationTitle("Job List")
        .task {
            if let company = masterDataManager.currentCompany {
                
                do {
                    techIds = []
                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    for companyUser in companyUserVM.companyUsers {
                        techIds.append(companyUser.userId)
                    }
                    startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date())!
                    jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                    
                } catch {
                    print("Error - [JobListView]")
                    print(error)
                }
                
            }
        }
        .onDisappear(perform: {
            jobVM.removeListenerForJob()
        })
//        .onChange(of: jobVM.workOrders, perform: { list in
//            print("Change in WorkOrders")
//            jobs = list
//        })
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: selectedId)
                            masterDataManager.selectedJob = jobVM.workOrder
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
        .onChange(of: jobVM.searchTerm){ term in
            print("Searching")
            jobVM.filterWorkOrderList()
        }
    }
    
}

extension JobListView {
    var list: some View {
        VStack{
            if jobVM.workOrders.count == 0 {
                if let role = masterDataManager.role {
                    if role.canCreateAnyJob {
                        Button(action: {
                            showCreateJobOptions = true
                        }, label: {
                            Text("Add First Job")
                                .modifier(AddButtonModifier())
                            
                        })
                        .sheet(isPresented: $showCreateJobOptions) {
                            createJobOptionsSheet
                                .presentationDetents([.medium])
                        }
                        .sheet(isPresented: $showCreateBlankJob,onDismiss: {
                            Task{
                                if let company = masterDataManager.currentCompany {
                                    
                                    do {
                                        techIds = []
                                        
                                        try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                                        for companyUser in companyUserVM.companyUsers {
                                            techIds.append(companyUser.userId)
                                        }
                                        
                                        startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date())!
                                        jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                                        
                                    } catch {
                                        print("Error Getting Users By status")
                                    }
                                    
                                }
                            }
                        }) {
                            AddNewJobView(
                                dataService: dataService,
                                customerId: nil,
                                canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                            )
                        }
                        .sheet(isPresented: $showCreateFromTemplate, onDismiss: {
                            reloadJobs()
                        }) {
                            if let company = masterDataManager.currentCompany {
                                JobTemplatePickerCreateJobSheet(
                                    companyId: company.id,
                                    dataService: dataService,
                                    canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                                )
                                .presentationDetents([.large])
                            } else {
                                Text("Missing company.")
                                    .presentationDetents([.medium])
                            }
                        }
                    }}
            } else {
                ScrollView{
                    if jobVM.searchTerm == "" {
                        ForEach(jobVM.workOrders){ job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job,dataService:dataService), label: {
                                    JobCardView(job: job)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedJob = job
                                }, label: {
                                    JobCardView(job: job)
                                })
                            }
                        }
                    } else {
                        ForEach(jobVM.filteredWorkOrders){ job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job,dataService:dataService), label: {
                                    JobCardView(job: job)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedJob = job
                                }, label: {
                                    JobCardView(job: job)
                                })
                            }
                        }
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
                        Image(systemName: "slider.horizontal.3")
                            .modifier(FilterIconModifer())
                    })
                    .padding(10)
                    .sheet(isPresented: $showFilters,onDismiss: {
                        Task{
                            if let company = masterDataManager.currentCompany {
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
                                .modifier(ListButtonModifier())
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
                        .padding(8)
                        .presentationDetents([.fraction(0.4)])
                    })
                    if let role = masterDataManager.role {
                        if role.canCreateAnyJob {
                            Button(action: {
                                showCreateJobOptions = true
                            }, label: {
                                Image(systemName: "plus")
                                    .modifier(PlusIconModifer())
                            })
                            .padding(10)
                            .sheet(isPresented: $showCreateJobOptions) {
                                createJobOptionsSheet
                                    .presentationDetents([.medium])
                            }
                            .sheet(isPresented: $showCreateBlankJob, onDismiss: {
                                reloadJobs()
                            }) {
                                AddNewJobView(
                                    dataService: dataService,
                                    customerId: nil,
                                    canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                                )
                            }
                            .sheet(isPresented: $showCreateFromTemplate, onDismiss: {
                                reloadJobs()
                            }) {
                                if let company = masterDataManager.currentCompany {
                                    JobTemplatePickerCreateJobSheet(
                                        companyId: company.id,
                                        dataService: dataService,
                                        canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                                    )
                                    .presentationDetents([.large])
                                } else {
                                    Text("Missing company.")
                                        .presentationDetents([.medium])
                                }
                            }
                        }
                    }
                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .modifier(SearchIconModifer())
                    })
                    .padding(10)
                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
                        text: $jobVM.searchTerm
                    )
                    Button(action: {
                        jobVM.searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(SearchTextFieldModifier())
                .padding(8)
            }
            
        }
    }
    // MARK: createJobOptionsSheet
    var createJobOptionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Create Job")
                                    .font(.title3.weight(.semibold))

                                Text(masterDataManager.role?.canCreateBlankJob == true ? "Start blank or use a reusable template." : "Use a reusable job template.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())
                        }
                    }
                    .jobCreateOptionCard()

                    if masterDataManager.role?.canCreateBlankJob == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateBlankJob = true
                            }
                        } label: {
                            jobCreateOptionRow(
                                title: "Blank Job",
                                subtitle: "Build a job manually from scratch.",
                                systemImage: "doc.badge.plus"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if masterDataManager.role?.canCreateJobFromTemplate == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateFromTemplate = true
                            }
                        } label: {
                            jobCreateOptionRow(
                                title: "From Template",
                                subtitle: "Create a job using planned stops, tasks, materials, and pricing.",
                                systemImage: "square.stack.3d.up"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(14)
            }
            .navigationTitle("New Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreateJobOptions = false
                    }
                }
            }
        }
    }
        // MARK: jobCreateOptionRow

    func jobCreateOptionRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func reloadJobs() {
        Task {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                techIds = []

                try await companyUserVM.getAllCompanyUsersByStatus(
                    companyId: company.id,
                    status: "Active"
                )

                for companyUser in companyUserVM.companyUsers {
                    techIds.append(companyUser.userId)
                }

                startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date()) ?? Date()

                jobVM.removeListenerForJob()
                jobVM.addListenerForAllJobsOperations(
                    companyId: company.id,
                    status: selectedStatus,
                    requesterIds: techIds,
                    startDate: startDate,
                    endDate: endDate
                )
            } catch {
                print("[][JobListView reloadJobs] Error \(error)")
            }
        }
    }
}

//MARK: Extension View
private extension View {
    func jobCreateOptionCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
