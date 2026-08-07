//
//  BillingJobList.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI
import Contacts

struct BillingJobList: View{
    
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
    
    @State var selectedStatus:[JobBillingStatus] = [.draft,.estimate,.accepted,.inProgress]
    
    @State var techIds:[String] = []
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            icons
        }
        .navigationTitle("Billable Jobs")
        .task {
            if let company = masterDataManager.currentCompany {
                
                do {
                    techIds = []
                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    for companyUser in companyUserVM.companyUsers {
                        techIds.append(companyUser.userId)
                    }
                    startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date())!
                    jobVM.addListenerForAllJobsBillings(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                    
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

extension BillingJobList {
    var list: some View {
        VStack{
            if jobVM.workOrders.count == 0 {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("412") {
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            Text("Add First Job")
                                .modifier(AddButtonModifier())
                            
                        })
                        .sheet(isPresented: $showAddNew,onDismiss: {
                            Task{
                                if let company = masterDataManager.currentCompany {
                                    
                                    do {
                                        techIds = []
                                        
                                        try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                                        for companyUser in companyUserVM.companyUsers {
                                            techIds.append(companyUser.userId)
                                        }
                                        
                                        startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date())!
                                        jobVM.addListenerForAllJobsBillings(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                                        
                                    } catch {
                                        print("Error Getting Users By status")
                                    }
                                    
                                }
                            }
                        }, content: {
                            VStack{
                                AddNewJobView(dataService: dataService, customerId: nil)
                            }
                        })
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
                                    jobVM.addListenerForAllJobsBillings(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                                    
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, content: {
                        billingJobFilterSheet
                    })
                    if let role = masterDataManager.role {
                        if role.permissionIdList.contains("412") {
                            Button(action: {
                                showCustomerPicker.toggle()
                            }, label: {
                                Image(systemName: "plus")
                                    .modifier(PlusIconModifer())
                            })
                            .padding(10)
                            .sheet(isPresented: $showCustomerPicker, content: {
                                VStack{
                                    
                                    AddNewJobView(dataService: dataService, customerId: nil)
                                }
                            })
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
}

private extension BillingJobList {
    var billingJobFilterSheet: some View {
        DripDropFilterSheet(
            title: "Billing Job Filters",
            isPresented: $showFilters,
            isResetDisabled: billingJobActiveFilterCount == 0,
            onReset: resetBillingJobFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(jobVM.workOrders.count) billable jobs",
                subtitle: "\(selectedStatus.count) billing status\(selectedStatus.count == 1 ? "" : "es") and \(techIds.count) tech\(techIds.count == 1 ? "" : "s") selected.",
                systemImage: "doc.text.fill",
                tint: .poolBlue
            )

            DripDropFilterSection(
                title: "Date Range",
                systemImage: "calendar",
                tint: .poolBlue
            ) {
                DripDropFilterRow(
                    title: "Start",
                    subtitle: shortDate(date: startDate),
                    systemImage: "calendar.badge.minus",
                    tint: .poolBlue
                ) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }

                DripDropFilterRow(
                    title: "End",
                    subtitle: shortDate(date: endDate),
                    systemImage: "calendar.badge.plus",
                    tint: .poolBlue
                ) {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            DripDropFilterSection(
                title: "Billing",
                systemImage: "line.3.horizontal.decrease.circle",
                tint: .orange
            ) {
                DripDropFilterRow(
                    title: "Status",
                    subtitle: billingStatusMenuTitle,
                    systemImage: "checklist",
                    tint: .orange
                ) {
                    Menu {
                        Button {
                            selectedStatus = JobBillingStatus.allCases
                        } label: {
                            Label("All statuses", systemImage: allBillingStatusesSelected ? "checkmark" : "circle")
                        }

                        ForEach(JobBillingStatus.allCases, id: \.self) { status in
                            Button {
                                toggleBillingStatus(status)
                            } label: {
                                Label(status.rawValue, systemImage: selectedStatus.contains(status) ? "checkmark" : "circle")
                            }
                        }

                        Button(role: .destructive) {
                            selectedStatus = []
                        } label: {
                            Label("Clear statuses", systemImage: selectedStatus.isEmpty ? "checkmark" : "xmark")
                        }
                    } label: {
                        DripDropFilterMenuLabel(title: billingStatusMenuTitle, tint: .orange)
                    }
                }

                DripDropFilterRow(
                    title: "Techs",
                    subtitle: billingTechMenuTitle,
                    systemImage: "person.2",
                    tint: .poolGreen
                ) {
                    Menu {
                        Button {
                            techIds = companyUserVM.companyUsers.map(\.userId)
                        } label: {
                            Label("All techs", systemImage: allBillingTechsSelected ? "checkmark" : "circle")
                        }

                        ForEach(companyUserVM.companyUsers) { tech in
                            Button {
                                toggleBillingTech(tech.userId)
                            } label: {
                                Label(tech.userName, systemImage: techIds.contains(tech.userId) ? "checkmark" : "circle")
                            }
                        }

                        Button(role: .destructive) {
                            techIds = []
                        } label: {
                            Label("Clear techs", systemImage: techIds.isEmpty ? "checkmark" : "xmark")
                        }
                    } label: {
                        DripDropFilterMenuLabel(title: billingTechMenuTitle, tint: .poolGreen)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    var defaultBillingJobStatuses: [JobBillingStatus] {
        [.draft, .estimate, .accepted, .inProgress]
    }

    var defaultBillingJobStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -300, to: Date()) ?? Date()
    }

    var billingJobActiveFilterCount: Int {
        var count = 0

        if !Calendar.current.isDate(startDate, inSameDayAs: defaultBillingJobStartDate) { count += 1 }
        if !Calendar.current.isDate(endDate, inSameDayAs: Date()) { count += 1 }
        if !usesDefaultBillingStatuses { count += 1 }
        if !allBillingTechsSelected { count += 1 }

        return count
    }

    var usesDefaultBillingStatuses: Bool {
        selectedStatus.count == defaultBillingJobStatuses.count &&
        defaultBillingJobStatuses.allSatisfy { selectedStatus.contains($0) }
    }

    var allBillingStatusesSelected: Bool {
        selectedStatus.count == JobBillingStatus.allCases.count &&
        JobBillingStatus.allCases.allSatisfy { selectedStatus.contains($0) }
    }

    var allBillingTechsSelected: Bool {
        let allTechIds = companyUserVM.companyUsers.map(\.userId)

        guard !allTechIds.isEmpty else {
            return techIds.isEmpty
        }

        return techIds.count == allTechIds.count && allTechIds.allSatisfy { techIds.contains($0) }
    }

    var billingStatusMenuTitle: String {
        if selectedStatus.isEmpty { return "None selected" }
        if allBillingStatusesSelected { return "All statuses" }
        if selectedStatus.count == 1 { return selectedStatus.first?.rawValue ?? "1 status" }
        return "\(selectedStatus.count) selected"
    }

    var billingTechMenuTitle: String {
        if techIds.isEmpty { return "None selected" }
        if allBillingTechsSelected { return "All techs" }
        if techIds.count == 1 {
            guard let firstTechId = techIds.first else { return "1 tech" }

            let techName = companyUserVM.companyUsers.first(where: { $0.userId == firstTechId })?.userName
            return techName ?? "1 tech"
        }
        return "\(techIds.count) selected"
    }

    func toggleBillingStatus(_ status: JobBillingStatus) {
        if selectedStatus.contains(status) {
            selectedStatus.removeAll(where: { $0 == status })
        } else {
            selectedStatus.append(status)
        }
    }

    func toggleBillingTech(_ userId: String) {
        if techIds.contains(userId) {
            techIds.removeAll(where: { $0 == userId })
        } else {
            techIds.append(userId)
        }
    }

    func resetBillingJobFilters() {
        startDate = defaultBillingJobStartDate
        endDate = Date()
        selectedStatus = defaultBillingJobStatuses
        techIds = companyUserVM.companyUsers.map(\.userId)
    }
}
