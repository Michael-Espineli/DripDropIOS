//
//  MobileHome.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI
enum MobileHomeScreenCategories:String {
    case all
    case routing
    case operations
    case finance
    case managment
    case publicView
    case myCompany
    case settings
    case sales
}

struct MobileHome: View {
    
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var masterRoleManager: MasterRoleManager

    @StateObject private var VM : MobileHomeViewModel
    @Environment(\.scenePhase) private var phase
    @StateObject var termsTemplateVM : TermsTemplateListViewModel
    @StateObject var mobileRouteVM: MobileDailyRouteDisplayViewModel
    @StateObject var fleetVM : FleetViewModel
    @StateObject var techListVM : TechListViewModel
    @StateObject var routeBoardVM: RouteBoardViewModel
    @StateObject var customerVM: CustomerListViewModel
    @StateObject var customerProfileVM: CustomerProfileViewModel

    

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: MobileHomeViewModel(dataService: dataService))
        _mobileRouteVM = StateObject(wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService))
        _fleetVM = StateObject(wrappedValue: FleetViewModel(dataService: dataService))
        _termsTemplateVM = StateObject(wrappedValue: TermsTemplateListViewModel(dataService: dataService))
        _techListVM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
        _routeBoardVM = StateObject(wrappedValue: RouteBoardViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerListViewModel(dataService: dataService))
        _customerProfileVM = StateObject(wrappedValue: CustomerProfileViewModel(dataService: dataService))

    }

    @StateObject private var roleVM = RoleViewModel()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()
    @State private var showSettings: Bool = false

    @State private var jobSettingsPicker:String = "Present"
    var body: some View {
        
            ZStack(alignment: .bottomLeading) {
            NavigationStack(path: $navigationManager.routes, root: {
                    TabView(selection: $masterDataManager.tabViewSelection) {
                        ProfileView(dataService: dataService)
                            .tabItem {
                                Label("Profile", systemImage: "person")
                            }
                            .tag("Profile")
                            //----------------------------------------
                            //Add Back in During Roll out of Phase 2
                            //----------------------------------------

                        mainDashboard
                            .tabItem {
                                Label("Dashboard", systemImage: "list.dash")
                            }
                            .tag("Dashboard")
                        SettingsView(dataService: dataService)
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                            .tag("Preferences")
                    }
                .navigationDestination(for: Route.self) { $0 }
            })
            .environmentObject(mobileRouteVM)
            .environmentObject(fleetVM)
            .environmentObject(termsTemplateVM)
            .environmentObject(techListVM)
            .environmentObject(routeBoardVM)
            .environmentObject(customerVM)
            .environmentObject(customerProfileVM)
                routeDashboardFloatingButton
            }
        .toolbar{
            ToolbarItem{
                Button(action: {
                    self.showSettings.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
            }
        }
//        .navigationTitle("Mobile Home")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbarBackground(.blue)

        .task {
            #warning("Please add listeners to get user access and role")
//            masterRoleManager.start(companyId: masterDataManager.currentCompany?.id, userId: masterDataManager.user?.id)
            
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                do{
                    try await userAccessVM.getUserAccessCompanies(userId: user.id, companyId: company.id)
                    if let access = userAccessVM.userAccess{
                        print("[MobileHome][task] \(access)")
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
                    print("[MobileHome][task]Error 1 Mobile Home")
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
            }
             
        }
        
        .onChange(of: masterRoleManager.role) { role in
            masterDataManager.role = role
            
        }
        .onDisappear(perform: {
            masterRoleManager.stop()
        })
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background: background()
            case .active: foreground()
            default: break
            }
        }
        
        .onChange(of: navigationManager.routes,
                  perform: {
            routes in
            Task{
                if let user = masterDataManager.user,
                   let company = masterDataManager.currentCompany,
                   let selectedCategory = masterDataManager.selectedCategory,
                   
                    let route = routes.last {
                    do {
                        let routeString = convertRouteToString(route: route)
                        let itemId:String = masterDataManager.selectedID ?? ""//Developer Figure out how to get the selectedID
                        try await userVM.addRecentActivity(
                            userId: user.id,
                            recentActivity: RecentActivityModel(
                                id: routeString.rawValue+itemId,
                                companyId: company.id,
                                category: selectedCategory,
                                route: routeString,
                                itemId: itemId,
                                name: "",
                                date: Date())
                        )
                    } catch {
                        print(error)
                    }
                }
            }
        })
    }
    func background() {
        print("App Entering Background From Mobile Home")
    }
    func foreground() {
        print("App Entering Foreground From Mobile Home")
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        print(timer)
    }
    private var routeDashboardFloatingButton: some View {
        Button {
            masterDataManager.tabViewSelection = "Dashboard"
            masterDataManager.mobileHomeScreen = .routing
            navigationManager.replace(stack: [Route.employeeMainDailyDisplayView(dataService: dataService)])
  
        } label: {
            Image(systemName: "map.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.bottom, 72)
        .accessibilityLabel("Back to route dashboard")
    }
}
struct MobileHome_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        MobileHome(dataService: dataService)
    }
    
}
extension MobileHome {
    var mainDashboard: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if masterDataManager.currentCompany == nil {
                    NoCompanySelectedView(dataService:dataService)
                } else {
                    header
                    ScrollView{
                        screens
                    }
                    Spacer()
                }
            }
        }
    }
    var header: some View {
        ZStack{
            if let role = masterDataManager.role {
                    HStack(spacing: 10){
                        VStack{
                            HStack{
                                if let selectedCompany = masterDataManager.currentCompany{
                                    Text("\(selectedCompany.name)")
                                        .bold()
                                        .fontDesign(.monospaced)
                                    Spacer()
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack{
                                    /*
                                     Roll Out In Update 3.1
                                    Button(action: {
                                        masterDataManager.mobileHomeScreen = .all
                                    }, label: {
                                        if masterDataManager.mobileHomeScreen == .all {
                                            HStack{
                                                Text("Dashboard")
                                            }
                                     .frame(minWidth: 50)
                                            .modifier(BlueButtonModifier())
                                            .bold()
                                        } else {
                                            HStack{
                                                Text("Dashboard")
                                            }
                                            
                                     .frame(minWidth: 50)
                                            .modifier(ListButtonModifier())
                                        }
                                    })
                                     */
                                    Button(action: {
                                        masterDataManager.mobileHomeScreen = .routing
                                    }, label: {
                                        if masterDataManager.mobileHomeScreen == .routing {
                                            HStack{
                                                Text("Route")
                                            }
                                            .modifier(EditButtonModifier())
                                            .bold()
                                        } else {
                                            HStack{
                                                Text("Route")
                                            }
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.poolWhite)
                                            .foregroundColor(.poolBlack)
                                            .cornerRadius(12)
                                            .bold()
                                        }
                                    })
                                    if role.permissionIdList.contains("0") {
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .operations
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .operations {
                                                HStack{
                                                    Text("Operations")
                                                }
                                                .modifier(EditButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Operations")
                                                }
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.poolWhite)
                                                .foregroundColor(.poolBlack)
                                                .cornerRadius(12)
                                                .bold()
                                            }
                                        })
                                    }
                                    if role.permissionIdList.contains("400") {
                                        if role.permissionIdList.contains("200") {
                                            Button(action: {
                                                masterDataManager.mobileHomeScreen = .managment
                                            }, label: {
                                                if masterDataManager.mobileHomeScreen == .managment {
                                                    HStack{
                                                        Text("Management")
                                                    }
                                                    .modifier(EditButtonModifier())
                                                    .bold()
                                                } else {
                                                    HStack{
                                                        Text("Management")
                                                    }
                                                    .font(.subheadline.weight(.semibold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color.poolWhite)
                                                    .foregroundColor(.poolBlack)
                                                    .cornerRadius(12)
                                                    .bold()
                                                }
                                            })
                                        }
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .sales
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .sales {
                                                HStack{
                                                    Text("Sales")
                                                }
                                                .modifier(EditButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Sales")
                                                }
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.poolWhite)
                                                .foregroundColor(.poolBlack)
                                                .cornerRadius(12)
                                                .bold()
                                            }
                                        })
//  MARK:                                         Update 2.1: Finance

                                        if role.permissionIdList.contains("200") {
                                            
                                            Button(action: {
                                                masterDataManager.mobileHomeScreen = .finance
                                            }, label: {
                                                if masterDataManager.mobileHomeScreen == .finance {
                                                    HStack{
                                                        Text("Finance")
                                                    }
                                                    .modifier(EditButtonModifier())
                                                    .bold()
                                                } else {
                                                    HStack{
                                                        Text("Finance")
                                                    }
                                                    .font(.subheadline.weight(.semibold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color.poolWhite)
                                                    .foregroundColor(.poolBlack)
                                                    .cornerRadius(12)
                                                    .bold()
                                                }
                                            })
                                        }
                                    }
                                    
                                    if role.permissionIdList.contains("800") {
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .settings
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .settings {
                                                HStack{
                                                    Text("Company Settings")
                                                }
                                                .modifier(EditButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Company Settings")
                                                }
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.poolWhite)
                                                .foregroundColor(.poolBlack)
                                                .cornerRadius(12)
                                                .bold()
                                            }
                                        })
                                    }
                                
                                    // Also At Marketing Things
                                    
                                    //----------------------------------------
                                    //Add Back in During Roll out of Phase 2
                                    //----------------------------------------
                                
                                    //                                VStack{
                                    //                                    HStack{
                                    //                                        Text("1")
                                    //                                            .font(.footnote)
                                    //                                            .foregroundColor(Color.clear)
                                    //                                    }
                                    //                                    Button(action: {
                                    //                                        screen = .publicView
                                    //                                    }, label: {
                                    //                                        HStack{
                                    //                                            Text("Market Place")
                                    //                                        }
                                    //                                        .frame(minWidth: 50,maxHeight: 30)
                                    //                                        .font(.footnote)
                                    //                                        .foregroundColor(Color.poolWhite)
                                    //                                        .padding(10)
                                    //                                        .background(screen == .publicView ? Color.poolBlue : Color.darkGray)
                                    //                                        .frame(minWidth: 50,maxHeight: 30)
                                    //                                        .clipShape(Capsule())
                                    //
                                    //                                    })
                                    //                                }
                                    //                                .padding(.leading,5)
                                
                                }
//                                .font(.footnote)
                                .lineLimit(1)
//                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
                            }
                            .overlay(
                                HStack{
                                    LinearGradient(colors: [
                                        Color.listColor,
                                        Color.listColor.opacity(0.5),
                                        Color.clear
                                    ],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                                    .frame(width: 10)
                                    Spacer()
                                }
                            )
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                
            }
            else {
                Text("No Role Selected")
            }
        }
        .frame(height: 100)
//        .background(Color.listColor)
        .padding(.leading,8)
    }
    var all: some View {
        VStack{
            Text("All")
        }
    }
    var screens: some View {
        VStack{
            
            switch masterDataManager.mobileHomeScreen {
            case .all:
                All(dataService: dataService)
                
            case .routing:
                CompanyRoutingView(dataService: dataService)
                
            case .operations :
                Operations(dataService: dataService)
                
            case .sales:
                OwesMoneyView(dataService: dataService)
                
            case .finance :
                Finance(dataService: dataService)
                
            case .managment :
                Managment(dataService: dataService)
                
            case .publicView:
                MarketPlaceView(dataService: dataService)
                
            case .myCompany:
                MyCompany(dataService: dataService)
                
            case .settings:
                CompanySettings(dataService: dataService)
            }
        }
    }
}
