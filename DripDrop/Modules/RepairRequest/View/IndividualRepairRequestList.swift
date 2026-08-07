//
//  IndividualRepairRequestList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/27/24.
//

import SwiftUI

struct IndividualRepairRequestList: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var repairRequestVM : RepairRequestViewModel
    @StateObject var techVM = TechViewModel()
    @StateObject var companyUserVM = CompanyUserViewModel()
    
    init(dataService:any ProductionDataServiceProtocol){
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        
    }
    @State var searchTerm:String = ""
    @State var showFilters:Bool = false
    @State var showSearch:Bool = false
    @State var showAddNewRequest:Bool = false
    @State var requestList:[RepairRequest] = []
    @State var selectedStatus:[RepairRequestStatus] = RepairRequestStatus.defaultOpenCases
    @State var techIds:[String] = []
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    
    var body: some View {
        ZStack{
            list
            icons
        }
        .task {
            if let company = masterDataManager.currentCompany {
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
                    startDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
                    
                    repairRequestVM.addListenerForAllRequests(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                } catch {
                    print("Failed")
                }
            }
        }
        .onChange(of: repairRequestVM.listOfContrats, perform: { list in
            requestList = list
        })
        .onDisappear(perform: {
            repairRequestVM.removeListenerForRepairRequest()
        })
    }
}

extension IndividualRepairRequestList{
    var list: some View{
        VStack{
            if repairRequestVM.listOfContrats.count == 0 {
                Button(action: {
                    showAddNewRequest.toggle()
                }, label: {
                    Text("Add First Request")
                })
                .foregroundColor(Color.basicFontText)
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                
            } else {
                if UIDevice.isIPhone {
                        LazyVStack{
                            ScrollView{
                            ForEach(repairRequestVM.listOfContrats){ repair in
                                    NavigationLink(value: Route.repairRequest(repairRequest: repair,dataService:dataService), label: {
                                        RepairRequestCardView(repairRequest: repair)
                                        
                                    })
                                Divider()
                            }
                        }
                    }
                } else {
                    List(selection:$masterDataManager.selectedID){
                        
                        ForEach(repairRequestVM.listOfContrats){ repair in
                         
                                Button(action: {
                                    masterDataManager.selectedRepairRequest = repair
                                    navigationManager.routes.append(Route.repairRequest(repairRequest: repair,dataService:dataService))
                                }, label: {
                                    RepairRequestCardView(repairRequest: repair)
                                })
                            
                        }
                    }
                }
            }
        }
    }
    var icons: some View{
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
                    .sheet(isPresented: $showFilters, onDismiss: {
                        if let company = masterDataManager.currentCompany {
                            repairRequestVM.removeListenerForRepairRequest()
                            repairRequestVM.addListenerForAllRequests(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                        }
                    },content: {
                        repairRequestFilterSheet
                    })
                    Button(action: {
                        showAddNewRequest.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.green)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "plus")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color.white)
                                )
                        }
                    })
                    .padding(10)
                    .sheet(isPresented: $showAddNewRequest, content: {
                        AddNewRepairRequest(dataService: dataService,isPresented: $showAddNewRequest, customer: nil)
                    })
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
                    Button(action: {
                        searchTerm = ""
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

private extension IndividualRepairRequestList {
    var repairRequestFilterSheet: some View {
        DripDropFilterSheet(
            title: "Repair Request Filters",
            isPresented: $showFilters,
            isResetDisabled: repairRequestActiveFilterCount == 0,
            onReset: resetRepairRequestFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(repairRequestVM.listOfContrats.count) requests showing",
                subtitle: "\(selectedStatus.count) status\(selectedStatus.count == 1 ? "" : "es") and \(techIds.count) tech\(techIds.count == 1 ? "" : "s") selected.",
                systemImage: "wrench.and.screwdriver.fill",
                tint: .orange
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
                title: "Request",
                systemImage: "line.3.horizontal.decrease.circle",
                tint: .orange
            ) {
                DripDropFilterRow(
                    title: "Status",
                    subtitle: repairStatusMenuTitle,
                    systemImage: "checklist",
                    tint: .orange
                ) {
                    Menu {
                        Button {
                            selectedStatus = RepairRequestStatus.allCases
                        } label: {
                            Label("All statuses", systemImage: allRepairStatusesSelected ? "checkmark" : "circle")
                        }

                        ForEach(RepairRequestStatus.allCases, id: \.self) { status in
                            Button {
                                toggleRepairStatus(status)
                            } label: {
                                Label(status.displayName, systemImage: selectedStatus.contains(status) ? "checkmark" : "circle")
                            }
                        }

                        Button(role: .destructive) {
                            selectedStatus = []
                        } label: {
                            Label("Clear statuses", systemImage: selectedStatus.isEmpty ? "checkmark" : "xmark")
                        }
                    } label: {
                        DripDropFilterMenuLabel(title: repairStatusMenuTitle, tint: .orange)
                    }
                }

                DripDropFilterRow(
                    title: "Techs",
                    subtitle: repairTechMenuTitle,
                    systemImage: "person.2",
                    tint: .poolGreen
                ) {
                    Menu {
                        Button {
                            techIds = companyUserVM.companyUsers.map(\.userId)
                        } label: {
                            Label("All techs", systemImage: allRepairTechsSelected ? "checkmark" : "circle")
                        }

                        ForEach(companyUserVM.companyUsers) { tech in
                            Button {
                                toggleRepairTech(tech.userId)
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
                        DripDropFilterMenuLabel(title: repairTechMenuTitle, tint: .poolGreen)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    var defaultRepairRequestStatuses: [RepairRequestStatus] {
        RepairRequestStatus.defaultOpenCases
    }

    var defaultRepairRequestStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
    }

    var repairRequestActiveFilterCount: Int {
        var count = 0

        if !Calendar.current.isDate(startDate, inSameDayAs: defaultRepairRequestStartDate) { count += 1 }
        if !Calendar.current.isDate(endDate, inSameDayAs: Date()) { count += 1 }
        if !usesDefaultRepairStatuses { count += 1 }
        if !allRepairTechsSelected { count += 1 }

        return count
    }

    var usesDefaultRepairStatuses: Bool {
        selectedStatus.count == defaultRepairRequestStatuses.count &&
        defaultRepairRequestStatuses.allSatisfy { selectedStatus.contains($0) }
    }

    var allRepairStatusesSelected: Bool {
        selectedStatus.count == RepairRequestStatus.allCases.count &&
        RepairRequestStatus.allCases.allSatisfy { selectedStatus.contains($0) }
    }

    var allRepairTechsSelected: Bool {
        let allTechIds = companyUserVM.companyUsers.map(\.userId)

        guard !allTechIds.isEmpty else {
            return techIds.isEmpty
        }

        return techIds.count == allTechIds.count && allTechIds.allSatisfy { techIds.contains($0) }
    }

    var repairStatusMenuTitle: String {
        if selectedStatus.isEmpty { return "None selected" }
        if allRepairStatusesSelected { return "All statuses" }
        if selectedStatus.count == 1 { return selectedStatus.first?.displayName ?? "1 status" }
        return "\(selectedStatus.count) selected"
    }

    var repairTechMenuTitle: String {
        if techIds.isEmpty { return "None selected" }
        if allRepairTechsSelected { return "All techs" }
        if techIds.count == 1 {
            guard let firstTechId = techIds.first else { return "1 tech" }

            let techName = companyUserVM.companyUsers.first(where: { $0.userId == firstTechId })?.userName
            return techName ?? "1 tech"
        }
        return "\(techIds.count) selected"
    }

    func toggleRepairStatus(_ status: RepairRequestStatus) {
        if selectedStatus.contains(status) {
            selectedStatus.removeAll(where: { $0 == status })
        } else {
            selectedStatus.append(status)
        }
    }

    func toggleRepairTech(_ userId: String) {
        if techIds.contains(userId) {
            techIds.removeAll(where: { $0 == userId })
        } else {
            techIds.append(userId)
        }
    }

    func resetRepairRequestFilters() {
        startDate = defaultRepairRequestStartDate
        endDate = Date()
        selectedStatus = defaultRepairRequestStatuses
        techIds = companyUserVM.companyUsers.map(\.userId)
    }
}
