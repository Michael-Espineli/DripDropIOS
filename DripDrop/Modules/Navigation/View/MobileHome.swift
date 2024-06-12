//
//  MobileHome.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI
enum MobileHomeScreenCategories:String {
    case operations
    case finace
    case managment
    case all
    case publicView
    case myCompany
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
    @StateObject private var accessVM = UserAccessViewModel()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()

    @State private var jobSettingsPicker:String = "Present"
    @State private var screen:MobileHomeScreenCategories = .all
    var body: some View {
        NavigationStack(path: $navigationManager.routes, root: {
            mainDashboard
            .navigationDestination(for: Route.self) { $0 }
        })
//        NavigationStack(path: $navigationManager.routes) {
//            mainDashboard
//            .navigationDestination(for: Route.self) { $0 }
//        }

        .onChange(of: phase) { newPhase in
                switch newPhase {
                case .background: background()
                case .active: foreground()
                default: break
                }
            }

        .onChange(of: navigationManager.routes, perform: { routes in
            Task{
                if let user = masterDataManager.user,
                   let company = masterDataManager.selectedCompany,
                   let route = routes.last {
                    do {
                        let routeString = convertRouteToString(route: route)
                        
                        try await userVM.addRecentActivity(
                            userId: user.id,
                            recentActivity: RecentActivityModel(
                                id: routeString,
                                route: routeString,
                                date: Date(),
                                companyId: company.id,
                                itemId: ""
                            )
                        )
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .task {
            if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                do{
                    try await accessVM.getUserAccessCompanies(userId: user.id, companyId: company.id)
                    if let access = accessVM.userAccess{
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
    var secondaryDashboard: some View {
        ScrollView{
            VStack{
                    NavigationLink(value: Route.customers(dataService:dataService), label: {

                    Text("\(Route.customers(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.dashBoard(dataService:dataService), label: {

                    Text("\(Route.dashBoard(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
 
                    NavigationLink(value: Route.repairRequestList(dataService:dataService), label: {

                    Text("\(Route.repairRequestList(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.dailyDisplay(dataService:dataService), label: {

                    Text("\(Route.dailyDisplay(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.companyRouteOverView(dataService:dataService), label: {

                    Text("\(Route.companyRouteOverView(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {

                    Text("\(Route.mainDailyDisplayView(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
            }
            VStack{
                    NavigationLink(value: Route.dashBoard(dataService:dataService), label: {

                    Text("\(Route.dashBoard(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.serviceStops(dataService:dataService), label: {

                    Text("\(Route.serviceStops(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.equipmentList(dataService:dataService), label: {

                    Text("\(Route.equipmentList(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                    NavigationLink(value: Route.routes(dataService:dataService), label: {
                    Text("\(Route.routes(dataService: dataService).title())")
                })
                .padding(16)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(8)

            }
        }
    }
    var mainDashboard: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
                ScrollView{

                    LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                        Section(content: {
                            screens
                        }, header: {
                            header
                        })
                    })
                }
                .padding(.top,20)
                .clipped()
        }
    }
    var header: some View {
        ZStack{
            ScrollView(.vertical, showsIndicators: false){
                    HStack(spacing: 0){
                            NavigationLink(value: Route.profile(dataService:dataService), label: {
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width:30 ,height:30)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.basicFontText)
                                                        .frame(width:30 ,height:30)
                                                        .clipShape(Circle())
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.basicFontText)
                                                        .frame(width:30 ,height:30)
                                                        .clipShape(Circle())
                                                }
                                            }
                                        }
                                    )
                                
                            }
                        })
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack{
                                
                                Button(action: {
                                    screen = .all
                                }, label: {
                                    HStack{
                                        Text("All")
                                    }
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .font(.footnote)
                                    .foregroundColor(Color.poolWhite)
                                    .padding(10)
                                    .background(screen == .all ? Color.poolBlue : Color.darkGray)
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .clipShape(Capsule())
                                })
                                
                                ForEach(userAccessVM.companies) { company in
                                    ZStack{
                                        if screen == .myCompany {
                                            if let selectedCompany = masterDataManager.selectedCompany{
                                                Button(action: {
                                                    masterDataManager.selectedCompany = company
                                                    screen = .myCompany
                                                }, label: {
                                                    HStack{
                                                        Text("\(company.name ?? "")")
                                                    }
                                                    .frame(minWidth: 50,maxHeight: 30)
                                                    .font(.footnote)
                                                    .foregroundColor(Color.poolWhite)
                                                    .padding(10)
                                                                                                    .background(selectedCompany == company ? Color.poolBlue : Color.darkGray)
                                                    .frame(minWidth: 50,maxHeight: 30)
                                                    .clipShape(Capsule())
                                                })
                                                
                                            }
                                        } else {
                                            Button(action: {
                                                masterDataManager.selectedCompany = company
                                                screen = .myCompany
                                            }, label: {
                                                HStack{
                                                    Text("\(company.name ?? "")")
                                                }
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .font(.footnote)
                                                .foregroundColor(Color.poolWhite)
                                                .padding(10)
                                                .background(Color.darkGray)
                                                .frame(minWidth: 50,maxHeight: 30)
                                                .clipShape(Capsule())
                                            })
                                        }
                                    }
                                }
                                Button(action: {
                                    screen = .operations
                                }, label: {
                                    HStack{
                                        Text("Operations")
                                    }
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .font(.footnote)
                                    .foregroundColor(Color.poolWhite)
                                    .padding(10)
                                    .background(screen == .operations ? Color.poolBlue : Color.darkGray)
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .clipShape(Capsule())
                                })
                                Button(action: {
                                    screen = .finace
                                }, label: {
                                    HStack{
                                        Text("Finace")
                                    }
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .font(.footnote)
                                    .foregroundColor(Color.poolWhite)
                                    .padding(10)
                                    .background(screen == .finace ? Color.poolBlue : Color.darkGray)
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .clipShape(Capsule())
                                })
                                Button(action: {
                                    screen = .managment
                                }, label: {
                                    HStack{
                                        Text("Mangment")
                                    }
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .font(.footnote)
                                    .foregroundColor(Color.poolWhite)
                                    .padding(10)
                                    .background(screen == .managment ? Color.poolBlue : Color.darkGray)
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .clipShape(Capsule())
                                    
                                })
                                Button(action: {
                                    screen = .publicView
                                }, label: {
                                    HStack{
                                        Text("Market Place")
                                    }
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .font(.footnote)
                                    .foregroundColor(Color.poolWhite)
                                    .padding(10)
                                    .background(screen == .publicView ? Color.poolBlue : Color.darkGray)
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .clipShape(Capsule())
                                    
                                })
                            }
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
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))

            }
        }
        .background(Color.listColor)
    }
    var all: some View {
        VStack{
            Text("All")
        }
    }
    var screens: some View {
        VStack{
 
            switch screen {
                case .all:
                All(dataService: dataService)
                case .operations :
                    Operations()
                case .finace :
                    Finance()
                case .managment :
                    Managment()
            case .publicView:
                MarketPlaceView()
            case .myCompany:
                MyCompany(
                    dataService: dataService
                )
            }
        }
    }
}
