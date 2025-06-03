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
    @StateObject private var VM : MobileHomeViewModel
    @Environment(\.scenePhase) private var phase
    
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: MobileHomeViewModel(dataService: dataService))
    }
    
    @StateObject private var roleVM = RoleViewModel()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()
    @State private var showSettings: Bool = false

    @State private var jobSettingsPicker:String = "Present"
    var body: some View {
            NavigationStack(path: $navigationManager.routes, root: {
                ZStack{
                    TabView(selection: $masterDataManager.tabViewSelection) {
                        ProfileView(dataService: dataService)
                            .tabItem {
                                Label("Profile", systemImage: "person")
                            }
                            .tag("Profile")
                            //----------------------------------------
                            //Add Back in During Roll out of Phase 2
                            //----------------------------------------

//                        ChatListView(dataService: dataService)
//                            .tabItem {
//                                Label("Messages", systemImage: "message.fill")
//                            }
//                            .tag("Messages")
//                            .badge(23)
                        mainDashboard
                            .tabItem {
                                Label("Dashboard", systemImage: "list.dash")
                            }
                            .tag("Dashboard")
                        SettingsView(dataService: dataService)
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                            .tag("Settings")
                    }
                }
                .navigationDestination(for: Route.self) { $0 }
            })
        
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
            }
        }
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
                header
                ScrollView{
                    screens
                }
                Spacer()
            }
        }
    }
    var header: some View {
        ZStack{
            if let role = masterDataManager.role {
                
                ScrollView(.vertical, showsIndicators: false){
                    HStack(spacing: 10){
//                        NavigationLink(value: Route.profile(dataService:dataService), label: {
//                            ZStack{
//                                Circle()
//                                    .fill(Color.gray)
//                                    .frame(width:40 ,height:40)
//                                    .overlay(
//                                        ZStack{
//                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
//                                                AsyncImage(url: url){ image in
//                                                    image
//                                                        .resizable()
//                                                        .scaledToFill()
//                                                        .foregroundColor(Color.basicFontText)
//                                                        .frame(width:40 ,height:40)
//                                                        .clipShape(Circle())
//                                                } placeholder: {
//                                                    Image(systemName:"person.circle")
//                                                        .resizable()
//                                                        .scaledToFill()
//                                                        .foregroundColor(Color.basicFontText)
//                                                        .frame(width:40 ,height:40)
//                                                        .clipShape(Circle())
//                                                }
//                                            }
//                                        }
//                                    )
//                                
//                            }
//                        })
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
                                    Button(action: {
                                        masterDataManager.mobileHomeScreen = .all
                                    }, label: {
                                        if masterDataManager.mobileHomeScreen == .all {
                                            HStack{
                                                Text("Dashboard")
                                            }
                                            .frame(minWidth: 50,maxHeight: 30)
                                            .modifier(BlueButtonModifier())
                                            .bold()
                                        } else {
                                            HStack{
                                                Text("Dashboard")
                                            }
                                            
                                            .frame(minWidth: 50,maxHeight: 30)
                                            .modifier(ListButtonModifier())
                                        }
                                    })
                                    Button(action: {
                                        masterDataManager.mobileHomeScreen = .routing
                                    }, label: {
                                        if masterDataManager.mobileHomeScreen == .routing {
                                            HStack{
                                                Text("Route")
                                            }
                                            .frame(minWidth: 50,maxHeight: 30)
                                            .modifier(BlueButtonModifier())
                                            .bold()
                                        } else {
                                            HStack{
                                                Text("Route")
                                            }
                                            .frame(minWidth: 50,maxHeight: 30)
                                            .modifier(ListButtonModifier())
                                        }
                                    })
                                    if role.permissionIdList.contains("11") {
                                        
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .operations
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .operations {
                                                HStack{
                                                    Text("Operations")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(BlueButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Operations")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(ListButtonModifier())
                                            }
                                        })
                                    }
                                    if role.permissionIdList.contains("13") {
                                        
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .sales
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .sales {
                                                HStack{
                                                    Text("Sales")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(BlueButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Sales")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(ListButtonModifier())
                                            }
                                        })
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .finance
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .finance {
                                                HStack{
                                                    Text("Finace")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(BlueButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Finace")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(ListButtonModifier())
                                            }
                                        })
                                    }
                                    if role.permissionIdList.contains("7") {
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .managment
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .managment {
                                                HStack{
                                                    Text("Manegment")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(BlueButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Manegment")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(ListButtonModifier())
                                            }
                                        })
                                    }
                                    if role.permissionIdList.contains("6") {
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .settings
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .settings {
                                                HStack{
                                                    Text("Company Settings")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(BlueButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Company Settings")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .modifier(ListButtonModifier())
                                            }
                                        })
                                    }
                                
                                    
                                    
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
                                .font(.footnote)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
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
                                    .frame(width: 20)
                                    Spacer()
                                }
                            )
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                    
                }
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
                
            case .sales:
                OwesMoneyView(dataService: dataService)
            }
        }
    }
}
