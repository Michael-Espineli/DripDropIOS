//
//  MiddleSideBarView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
import SwiftUI

struct MiddleSidebarView: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @State var layoutExperience: LayoutExperienceSetting = .threeColumn
    //Get Ride of this Later I just dont wanna deal with the errors
    @State var user:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    @State var company:Company = Company(id: "", ownerId: "", ownerName: "", name: "", photoUrl: "", dateCreated: Date(), email: "", phoneNumber: "", verified: false, serviceZipCodes: [], services: [])
    @State var showSignInView:Bool = false


    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            if let category = masterDataManager.selectedCategory {
                switch category {
                case .taskGroups:
                    TaskGroupListView(dataService: dataService)
                case .customers:
                    CustomerListView(dataService: dataService)
                case .management:
                    UserRouteOverView(dataService: dataService)
                case .dailyDisplay:
                    ContractorDailyDashboard(dataService: dataService)
                case .serviceStops:
                    ServiceStopListView(dataService: dataService)
                case .databaseItems:
                    ReceiptDatabaseView(dataService: dataService )
                case .routeBuilder:
                    RouteManagmentView(dataService: dataService)
                case .maps:
                    EmptyView()
                case .calendar:
                    CalendarView(showSignInView: $showSignInView, user: user, company: company)
                case .profile:
                    ProfileView(dataService: dataService)
                case .contract:
                    ContractListView(dataService: dataService)
                case .pnl:
                    PNLListView()
                case .receipts:
                    ReceiptListView()
                case .vender:
                    StoreView()
                case .purchases:
                    PurchaseListView(dataService: dataService)
                case .jobs:
                    JobView(dataService: dataService)
                case .userRoles:
                    UserRoleView()
                case .companyProfile:
                   Text("Company Profile View")
                case .chat:
                    ChatListView(dataService: dataService)
                case .repairRequest:
                    RepairRequestListView(dataService: dataService)
                case .marketPlace:
                    Text("Market Place")
                case .jobPosting:
                    Text("Job Posting")
                case .feed:
                    Text("Feed")
                case .reports:
                    ReportListView()
                case .users:
                    TechListView(dataService: dataService)
                case .fleet:
                    FleetListView(dataService: dataService)
                case .readingsAndDosages:
                    ReadingsAndDosagesList()
                case .genericItems:
                    GenericItemList(dataService: dataService)
                case .dashBoard:
                    All(dataService: dataService)
                case .companyRouteOverView:
                    UserRouteOverView(dataService: dataService)
                case .accountsPayable:
                    AccountsPayableList(dataService: dataService)
                case .accountsReceivable:
                    AccountsReceivableList(dataService: dataService)
                case .equipment:
                    EquipmentList(dataService: dataService)
                case .settings:
                    SettingsView(dataService: dataService)
                case .jobTemplates:
                    JobTemplateSettingsView(dataService: dataService)
                case .contracts:
                    ContractListView(dataService: dataService)
                case .companyUser:
                    TechListView(dataService: dataService)
                case .alerts:
                    PersonalAlertView(dataService: dataService)
                case .shoppingList:
                    ShoppingListView(dataService: dataService)
                case .businesses:
                    BusinessesListView(dataService: dataService)
                case .companyAlerts:
                    CompanyAlerts(dataService: dataService)
                case .personalAlerts:
                    Text("Feed")
                case .receivedLaborContracts:
                    ReceivedRecurringLaborContractListView(dataService: dataService)
                case .sentLaborContracts:
                    SentRecurringLaborContractListView(dataService: dataService)
                case .externalRoutesOverview:
                    ExternalRouteListView(dataService: dataService)
                case .managementTables:
                    VStack{
                        Text("Management Tables Options")
                        HStack{
                            Spacer()
                            Text("Customer Over Table")
                            Spacer()
                        }
                        .modifier(ListButtonModifier())
                        HStack{
                            Spacer()
                            Text("Job Over Table")
                            Spacer()
                        }
                        .modifier(ListButtonModifier())
                        HStack{
                            Spacer()
                            Text("Service Stop Table")
                            Spacer()
                        }
                        .modifier(ListButtonModifier())
                        
                        HStack{
                            Spacer()
                            Text("Routing Table")
                            Spacer()
                        }
                        .modifier(ListButtonModifier())
                    }
                }
            } else {
                Text("Select Category")
            }
        }
        .onChange(of: masterDataManager.selectedCategory, perform: { cat in
            print("Middle Side Bar Selected Category \(cat)")
        })
    }
}

