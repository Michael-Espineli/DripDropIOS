//
//  TwoColumnMenuView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct TwoColumnMenuView: View {
    
    @EnvironmentObject private var routerManager: NavigationRouter
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var roleVM = RoleViewModel()
    @StateObject var accessVM = UserAccessViewModel()

    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var showCart: Bool
    @Binding var showSettings: Bool
    @Binding var showCompany: Bool
    @Binding var layoutExperience: LayoutExperienceSetting?
    @Binding var showSignInView: Bool
    let user:DBUser
    
    var body: some View {
        Group {
            if let role = masterDataManager.role{
                NavigationSplitView(columnVisibility: $columnVisibility, sidebar: {
                    SideBarView(dataService: dataService, role: role, selectedCategory: $masterDataManager.selectedCategory)
                        .navigationTitle("Menu")
                        .navigationBarBackground()
                        .font(.system(.body , design: .rounded))

//                        .toolbar {
//                            ToolbarItem(placement: .primaryAction) {
//                                Button(action: {
//                                    
//                                }, label: {
//                                    Text("Something")
//                                })
//                            }
//                            if UIDevice.current.userInterfaceIdiom != .phone {
//                                ToolbarItem {
//                                    Button {
//                                        showSettings.toggle()
//                                    } label: {
//                                        Image(systemName: "gear")
//                                    }
//                                }
//                            }
//                            
//                        }
                }, detail: {
                    NavigationStack(path: $navigationManager.routes) {
                        
                        MiddleSidebarView(user: user, company: masterDataManager.selectedCompany!, showSignInView: showSignInView)
                        
                            .navigationDestination(for: Route.self) { $0 }
                    }
                    .navigationBarBackground()

                })
                .navigationBarBackground()

            } else {
                Text("Bad User Access")
            }
        }
        .task {
            do{
                try await accessVM.getUserAccessCompanies(userId: user.id, companyId: masterDataManager.selectedCompany!.id)
                if let access = accessVM.userAccess{
                    print("Access >> \(access)")
                    try await roleVM.getSpecificRole(companyId: masterDataManager.selectedCompany!.id, roleId: access.roleId)
                    if let role = roleVM.role {
                        masterDataManager.role = role
                    } else {
                        masterDataManager.showSignInView = true
                    }

                } else {
                    masterDataManager.showSignInView = true
                }
            } catch {
                print("Error")
            }
        }
    }
}


