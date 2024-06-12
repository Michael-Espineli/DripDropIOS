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
    @State var user:DBUser = DBUser(id: "",exp: 0)
    @State var company:Company = Company(id: "")
    @State var showSignInView:Bool = false


    var body: some View {
        if let category = masterDataManager.selectedCategory {
            switch category {
            case .customers:
                CustomerListView(dataService: dataService)
            case .management:
                UserRouteOverView(dataService: dataService)
                    .navigationTitle("Managment")
            case .dailyDisplay:
                EmployeeDailyDashboard(dataService: dataService)
                    .navigationTitle("Dashboard")
            case .serviceStops:
                ServiceStopMainView()
                    .navigationTitle("Service Stops")
            case .databaseItems:
                ReceiptDatabaseView()
                    .navigationTitle("Data Base Items")
            case .routeBuilder:
                RouteManagmentView(dataService: dataService)
                    .navigationTitle("Route Builder View")
            case .maps:
                EmptyView()
                    .navigationTitle("Maps")
            case .calendar:
                CalendarView(showSignInView: $showSignInView, user: user, company: company)
                    .navigationTitle("Calendar")
            case .profile:
                ProfileView(dataService: dataService)
                    .navigationTitle("Profile View")
            case .contract:
                ContractListView(dataService: dataService)
                    .navigationTitle("Contract")
            case .pnl:
                PNLListView()
                    .navigationTitle("PNL")
            case .receipts:
                ReceiptListView()
                    .navigationTitle("Receipts")

            case .vender:
                StoreView()
                    .navigationTitle("Vender")
            case .purchases:
                PurchasesView()
                    .navigationTitle("Purchases")
            case .jobs:
                JobView()
                    .navigationTitle("Work Order")
            case .userRoles:
                UserRoleView()
                    .navigationTitle("User Roles")
            case .companyProfile:
                CompanyProfileView()
                    .navigationTitle("Company Profile")
            case .chat:
                ChatListView(dataService: dataService)
                    .navigationTitle("Chat")
            case .repairRequest:
                RepairRequestListView(dataService: dataService)
                    .navigationTitle("Repair Request")
            case .marketPlace:
                Text("Market Place")
                    .navigationTitle("Market Place")
            case .jobPosting:
                Text("Job Posting")
                    .navigationTitle("Job Postings")
            case .feed:
                Text("Feed")
                    .navigationTitle("Feed")
            case .reports:
                ReportListView()
                    .navigationTitle("Reports")
            case .users:
                TechView(showSignInView: $showSignInView, user: user,company: company)
                    .navigationTitle("Users")
            case .fleet:
                FleetListView(dataService: dataService)
                    .navigationTitle("Fleet")
            case .readingsAndDosages:
                ReadingsAndDosagesList()
            case .genericItems:

                GenericItemList(dataService: dataService)
            case .dashBoard:
                DashboardList(dataService: dataService)
                    .navigationTitle("\(fullDate(date:Date()))")
                    .navigationBarTitleDisplayMode(.inline)

            }
            
        } else {
           Text("Select Category")
                .navigationTitle("Select Category")

        }
    }
}

