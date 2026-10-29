//
//  RepairRequestListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct RepairRequestListView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var repairRequestVM : RepairRequestViewModel
    @StateObject var techVM = TechViewModel()
    @StateObject var companyUserVM = CompanyUserViewModel()
    let submittedByUserId: String?

    init(dataService:any ProductionDataServiceProtocol, submittedByUserId: String? = nil){
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        self.submittedByUserId = submittedByUserId
        
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
    @State var useDateFilter = false

    private var filteredRequests: [RepairRequest] {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return repairRequestVM.listOfContrats.filter { request in
            let matchesStatus = selectedStatus.isEmpty || selectedStatus.contains(request.status.selectableValue)
            let matchesTech = techIds.isEmpty || techIds.contains(request.requesterId)
            let matchesDate = !useDateFilter || request.date == .distantPast || (request.date >= startDate.startOfDay() && request.date <= endDate.endOfDay())
            let matchesSearch = term.isEmpty || [request.customerName, request.requesterName, request.description, request.status.displayName, request.id].joined(separator: " ").lowercased().contains(term)
            return matchesStatus && matchesTech && matchesDate && matchesSearch
        }.sorted { $0.date == $1.date ? $0.queueId < $1.queueId : $0.date > $1.date }
    }

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            icons
        }
        .navigationTitle(submittedByUserId == nil ? "Repair Requests" : "My Repair Requests")
        .task(id: masterDataManager.currentCompany?.id) {
            if let company = masterDataManager.currentCompany {
                repairRequestVM.startQueue(companyId: company.id, submittedByUserId: submittedByUserId)
                do {
                    techIds = []

                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    startDate = defaultRepairRequestStartDate
                    
                } catch {
                    print("[RepairRequestListView][task] Error: \(error)")
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

extension RepairRequestListView{
    var list: some View{
        VStack{
            Text("\(filteredRequests.count) requests").font(.caption).foregroundStyle(.secondary)
            if repairRequestVM.queueLoading {
                ProgressView("Loading repair requests…")
            } else if let error = repairRequestVM.queueError {
                Text(error).font(.caption).foregroundStyle(.red)
            } else if filteredRequests.isEmpty {
                Button(action: {
                    showAddNewRequest.toggle()
                }, label: {
                    Text("Add Repair Request")
                        .modifier(AddButtonModifier())
                })
            } else {
                ScrollView{
                    ForEach(filteredRequests, id: \.queueId){ repair in
                        if repair.sourcePath == "homeowner", let url = homeownerRequestURL(repair) {
                            Link(destination: url) {
                                RepairRequestCardView(repairRequest: repair)
                            }
                        } else if UIDevice.isIPhone {
                            NavigationLink(value: Route.repairRequest(repairRequest: repair,dataService:dataService), label: {
                                RepairRequestCardView(repairRequest: repair)

                            })
                        } else {
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
        .padding(8)
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
                    Image(systemName: "slider.horizontal.3")
                        .modifier(FilterIconModifer())
                })
                .padding(10)
                .sheet(isPresented: $showFilters, content: {
                    repairRequestFilterSheet
                  
                })
                Button(action: {
                    showAddNewRequest.toggle()
                }, label: {
                    Image(systemName: "plus")
                        .modifier(PlusIconModifer())
                })
                .padding(8)
                .sheet(isPresented: $showAddNewRequest, content: {
                    AddNewRepairRequest(dataService: dataService,isPresented: $showAddNewRequest, customer: nil)
                        .presentationDetents([.large,.medium])
                })
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

private extension RepairRequestListView {
    func homeownerRequestURL(_ request: RepairRequest) -> URL? {
        var url = URLComponents(string: "https://dripdrop-poolapp.com/company/repair-requests/detail/")
        url?.path += request.id
        url?.queryItems = [URLQueryItem(name: "sourcePath", value: "homeowner")]
        return url?.url
    }

    var repairRequestFilterSheet: some View {
        DripDropFilterSheet(
            title: "Repair Request Filters",
            isPresented: $showFilters,
            isResetDisabled: repairRequestActiveFilterCount == 0,
            onReset: resetRepairRequestFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(filteredRequests.count) requests showing",
                subtitle: "\(repairStatusMenuTitle) • \(repairTechMenuTitle)",
                systemImage: "wrench.and.screwdriver.fill",
                tint: .orange
            )

            DripDropFilterSection(
                title: "Date Range",
                systemImage: "calendar",
                tint: .poolBlue
            ) {
                Toggle("Filter by date", isOn: $useDateFilter)
                DripDropFilterRow(
                    title: "Start",
                    subtitle: shortDate(date: startDate),
                    systemImage: "calendar.badge.minus",
                    tint: .poolBlue
                ) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!useDateFilter)
                }

                DripDropFilterRow(
                    title: "End",
                    subtitle: shortDate(date: endDate),
                    systemImage: "calendar.badge.plus",
                    tint: .poolBlue
                ) {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!useDateFilter)
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
                            Label("Clear status filters", systemImage: selectedStatus.isEmpty ? "checkmark" : "xmark")
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
                            techIds = []
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
                            Label("Clear tech filters", systemImage: techIds.isEmpty ? "checkmark" : "xmark")
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

        if useDateFilter { count += 1 }
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
        techIds.isEmpty
    }

    var repairStatusMenuTitle: String {
        if selectedStatus.isEmpty { return "All statuses" }
        if allRepairStatusesSelected { return "All statuses" }
        if selectedStatus.count == 1 { return selectedStatus.first?.displayName ?? "1 status" }
        return "\(selectedStatus.count) selected"
    }

    var repairTechMenuTitle: String {
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
        techIds = []
        useDateFilter = false
    }
}
