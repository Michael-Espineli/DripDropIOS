//
//  ThreeColumnMenuView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct ThreeColumnMenuView: View {
    init(dataService:any ProductionDataServiceProtocol,layoutExperience:Binding<LayoutExperienceSetting>) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        self._layoutExperience = layoutExperience
    }
    @EnvironmentObject private var routerManager: NavigationRouter
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var userAccessVM = UserAccessViewModel()

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var roleVM = RoleViewModel()
    @StateObject var accessVM = UserAccessViewModel()
    @StateObject private var VM : AuthenticationViewModel

    @State var columnVisibility: NavigationSplitViewVisibility = .automatic
    @Binding var layoutExperience: LayoutExperienceSetting
    @State var jobSettingsPicker:String = "Present"
    var body: some View {
        Group{
            if let role = masterDataManager.role {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SideBarView(dataService: dataService, role: role, selectedCategory: $masterDataManager.selectedCategory)
                        .navigationTitle("Menu")
                        .font(.system(.body , design: .rounded))
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackground()
                        .navigationSplitViewColumnWidth(min: 300, ideal: 450, max: 600)
                } content: {
                    ZStack {
                        if let user = masterDataManager.user, let company = masterDataManager.currentCompany{
                            MiddleSidebarView(user: user, company: company, showSignInView: masterDataManager.showSignInView)
                                .font(.system(.body , design: .rounded))
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarBackground()
                        }
                    }
                    .navigationSplitViewColumnWidth(min: 300, ideal: 450, max: 600)
                } detail: {
                    
                    NavigationStack(path: $navigationManager.routes) {
                        DetailView(dataService:dataService)
                            .navigationDestination(for: Route.self) { $0 }
                            .toolbar{
                                ToolbarItem(placement: .topBarLeading, content: {
                                    Button(action: {
                                        switch columnVisibility{
                                        case .all:
                                            columnVisibility = .detailOnly
                                        case .doubleColumn:
                                            columnVisibility = .detailOnly
                                        case .detailOnly:
                                            columnVisibility = .detailOnly
                                        default:
                                            columnVisibility = .detailOnly
                                        }
                                    }, label: {
                                        Image(systemName: columnVisibility == .detailOnly ? "" : "square.leftthird.inset.filled")
                                    })
                                })
                            }
                    }
                }
                .navigationBarBackground()
            } else {
                WaterLevelLoading()
            }
        }
        .task {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                do{
                    try await userAccessVM.getUserAccessCompanies(userId: user.id, companyId: company.id)
                    if let access = userAccessVM.userAccess{
                        print("Mobile Home Access >> \(access)")
                        try await roleVM.getSpecificRole(companyId: company.id, roleId: access.roleId)
                        if let role = roleVM.role {
                            masterDataManager.role = role
                        } else {
                            masterDataManager.showSignInView = true
                        }
                    } else {
                        masterDataManager.showSignInView = true
                    }
                } catch {
                    print("Error 1 Mobile Home")
                    print(error)
                }
                do {
                    try await userAccessVM.getAllUserAvailableCompanies(userId: user.id)
                    try await userAccessVM.getCompaniesFromAccess(accessList: userAccessVM.allAvailableAccess)
                    masterDataManager.allCompanies = userAccessVM.companies
                } catch {
                    print("Error 2 Mobile Home")
                    print(error)
                }
            } else {
                print("No Company or User on Three Column")
                do {
                    print("Root View")
                    try await VM.onInitialLoad()
                    masterDataManager.user = VM.user
                    masterDataManager.currentCompany = VM.company
                    masterDataManager.companyUser = VM.companyUser
                    VM.isLoading = false
                    masterDataManager.showSignInView = false
                } catch {
                    print("error")
                    print(error)
                }
                if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                    do{
                        try await userAccessVM.getUserAccessCompanies(userId: user.id, companyId: company.id)
                        if let access = userAccessVM.userAccess{
                            print("Mobile Home Access >> \(access)")
                            try await roleVM.getSpecificRole(companyId: company.id, roleId: access.roleId)
                            if let role = roleVM.role {
                                masterDataManager.role = role
                            } else {
                                masterDataManager.showSignInView = true
                            }
                        } else {
                            masterDataManager.showSignInView = true
                        }
                    } catch {
                        print("Error 1 Mobile Home")
                        print(error)
                    }
                    do {
                        try await userAccessVM.getAllUserAvailableCompanies(userId: user.id)
                        try await userAccessVM.getCompaniesFromAccess(accessList: userAccessVM.allAvailableAccess)
                        masterDataManager.allCompanies = userAccessVM.companies
                    } catch {
                        print("Error 2 Mobile Home")
                        print(error)
                    }
                } else {
                    print("No Company or User on Three Column Twice")
                }
            }
        }
    }
}

private extension ThreeColumnMenuView {
    
    @ViewBuilder
    func getView(for item: any ServiceItemProtocol) -> some View {
//        if let job = item as? Job {
//            EmptyView()
//        } else if let location = item as? ServiceLocation {
//            ServiceLocationDetailView(serviceLocation: location)
//        } else if let chat = item as? MessageGroup {
//            EmptyView()
//        } else if let estimate = item as? Estimate {
//            EmptyView()
//        } else if let invoice = item as? Invoice {
//            EmptyView()
//        } else if let company = item as? Company {
//            EmptyView()
//        } else {
//            EmptyView()
//        }
        EmptyView()

    }
}

