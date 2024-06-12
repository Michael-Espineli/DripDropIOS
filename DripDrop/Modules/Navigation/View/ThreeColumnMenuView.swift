//
//  ThreeColumnMenuView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct ThreeColumnMenuView: View {
    
    @EnvironmentObject private var routerManager: NavigationRouter
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var roleVM = RoleViewModel()
    @StateObject var accessVM = UserAccessViewModel()

    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var showCart: Bool
    @Binding var showSettings: Bool
    @Binding var showCompany: Bool
    @Binding var layoutExperience: LayoutExperienceSetting?
    @Binding var showSignInView: Bool
    let user:DBUser
    @State var jobSettingsPicker:String = "Present"
    var body: some View {
        Group{
            if let role = masterDataManager.role {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    
                    //            SecondarySideBar(selectedCategory: $routerManager.selectedCategory, layoutExperience:$layoutExperience)
                    SideBarView(dataService: dataService, role: role, selectedCategory: $masterDataManager.selectedCategory)
                        .navigationTitle("Menu")
                        .font(.system(.body , design: .rounded))
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackground()

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
                    
                } content: {
                    ZStack {
                        MiddleSidebarView(user: user, company: masterDataManager.selectedCompany!, showSignInView: showSignInView)
                            .toolbar {
                                if  masterDataManager.selectedCategory == .customers {
                                    ToolbarItem {
                                        Button {
                                            showCompany.toggle()
                                        } label: {
                                            Image(systemName: "person.text.rectangle")
                                        }
                                    }
                                }
                            }
                            .font(.system(.body , design: .rounded))
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarBackground()
                    }
                    
                    
                } detail: {
                    
                    NavigationStack(path: $navigationManager.routes) {
                        
                        DetailView(dataService:dataService)
                            .navigationDestination(for: Route.self) { $0 }
                    }
                }
                .navigationBarBackground()
            } else {
                ProgressView()
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
        .onChange(of: masterDataManager.selectedCategory, perform: { id in
            columnVisibility = .doubleColumn
        })
  
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

