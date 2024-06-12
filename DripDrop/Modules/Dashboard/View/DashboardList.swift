//
//  DashboardList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/21/24.
//

import SwiftUI

struct DashboardList: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var activeRouteVM = ActiveRouteViewModel()
    @StateObject var recurringRouteVM = RecurringRouteViewModel()
    
    @StateObject var toDoVM : ToDoViewModel
    @StateObject var shoppingListVM : ShoppingListViewModel
    @StateObject var repairRequestVM : RepairRequestViewModel
    
    @StateObject var purchaseVM = PurchasesViewModel()
    init(dataService:any ProductionDataServiceProtocol){
        _shoppingListVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
    }
    let data = (1...100).map { "Item \($0)" }
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    @State var isLoading : Bool = false
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                routePreview
                    .padding(5)
                if UIDevice.isIPhone {
                    dashboardDetails
                        .padding(5)
                    
                }
                todoList
                    .padding(5)
                pendingJobs
                    .padding(5)
                
                shoppingList
                    .padding(5)
                unassignedPurchasedItems
                    .padding(5)
                repairRequests
                    .padding(5)
            }
            .padding(20)
        }
        //        .background(Color.white)
        .task{
            isLoading = true
            if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                do {
                    let recurringRouteId = weekDay(date: Date()) + user.id
                    print(recurringRouteId)
                    try await recurringRouteVM.getSingleRoute(companyId: company.id, recurringRouteId: recurringRouteId)
                    print("Successfully Got Recurring Route \(fullDateAndDay(date: Date())) for \(user.id)")
                } catch {
                    print("\(recurringRouteVM.recurringRoute == nil ? "No Route Today" : "Route Exists")")
                }
                
                do {
                    try await activeRouteVM.checkForActiveRouteOnDateForUserFromRecurringRoute(companyId: company.id, date: Date(), tech: user,recurringRoute: recurringRouteVM.recurringRoute)
                    print("Successfully Got Active Route \(fullDateAndDay(date: Date())) for \(user.id)")
                    
                } catch MobileDisplayError.noRouteToday{
                    print("noRouteToday")
                } catch MobileDisplayError.invalidUser{
                    print("invalidUser")
                } catch MobileDisplayError.invalidStatus{
                    print("invalidStatus")
                } catch MobileDisplayError.noDescription{
                    print("noDescription")
                } catch MobileDisplayError.semething{
                    print("semething")
                } catch MobileDisplayError.failedToGetWeather {
                    print("Weather Error")
                } catch {
                    print("Error Basic Getting Active Route of \(fullDateAndDay(date: Date()))")
                }
                do {
                    try await toDoVM.readToDoTechListCount(companyId: company.id, techId: user.id)
                } catch {
                    print(error)
                }
                do {
                    try await shoppingListVM.getAllShoppingListItemsByUserCount(companyId: company.id, userId: user.id)
                } catch {
                    print(error)
                }
                do {
                    try await repairRequestVM.getRepairRequestByUserCount(companyId: company.id, userId: user.id)
                } catch {
                    print(error)
                }
                do {
                    try await purchaseVM.getPurchasesCountForTechId(companyId: company.id, userId: user.id)
                } catch {
                    print(error)
                }
            }
            isLoading = false
        }
        
    }
}

struct DashboardList_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        DashboardList(dataService:dataService)
    }
}
extension DashboardList{
    
    var repairRequests: some View {

            NavigationLink(value: Route.repairRequestList(dataService: dataService), label: {

            ZStack{
                VStack{
                    Text("Repair Requests")
                }
                VStack{
                    HStack{
                        ZStack{
                            
                            if let count = repairRequestVM.count {
                                if count >= 1 && count <= 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "\(String(count)).circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .font(.title)
                                } else if count > 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .overlay{
                                            HStack{
                                                Text("50")
                                                Image(systemName: "plus")
                                                
                                            }
                                        }
                                }
                                
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(width: 100, height: 100)
            .foregroundColor(Color.basicFontText)
            .background(Color.headerColor)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
            )
        })
        
    }
    
    var todoList: some View {

            NavigationLink(value: Route.toDoList(dataService: dataService), label: {

            ZStack{
                VStack{
                    Text("To Do List")
                }
                VStack{
                    HStack{
                        ZStack{
                            
                            if let count = toDoVM.toDoListCount {
                                if count >= 1 && count <= 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "\(String(count)).circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .font(.title)
                                } else if count > 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .overlay{
                                            HStack{
                                                Text("50")
                                                Image(systemName: "plus")
                                            }
                                        }
                                }
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(width: 100, height: 100)
            .foregroundColor(Color.basicFontText)
            .background(Color.headerColor)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.basicFontText, radius: 6, x: 0, y: 0)
            )
        })
        
    }
    var shoppingList: some View {
   
            NavigationLink(value: Route.shoppingList(dataService: dataService), label: {

            ZStack{
                VStack{
                    Text("Shopping List")
                }
                VStack{
                    HStack{
                        ZStack{
                            if let count = shoppingListVM.shoppingListItemCount {
                                if count >= 1 && count <= 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "\(String(count)).circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .font(.title)
                                } else if count > 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .overlay{
                                            HStack{
                                                Text("50")
                                                Image(systemName: "plus")
                                                
                                            }
                                        }
                                }
                                
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(width: 100, height: 100)
            .foregroundColor(Color.basicFontText)
            .background(Color.headerColor)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
            )
        })
        
    }
    var unassignedPurchasedItems: some View {
            NavigationLink(value: Route.purchasedItemsList(dataService: dataService), label: {

            ZStack{
                VStack{
                    Text("Purchased Items")
                }
                VStack{
                    HStack{
                        ZStack{
                            if let count = purchaseVM.purchaseCount {
                                if count >= 1 && count <= 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "\(String(count)).circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .font(.title)
                                } else if count > 50 {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color.poolRed)
                                        .overlay{
                                            HStack{
                                                Text("50")
                                                Image(systemName: "plus")
                                                
                                            }
                                        }
                                }
                                
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(width: 100, height: 100)
            .foregroundColor(Color.basicFontText)
            .background(Color.headerColor)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
            )
        })
        
    }
    
    var pendingJobs: some View {

            NavigationLink(value: Route.pendingJobs(dataService: dataService), label: {

            ZStack{
                VStack{
                    Text("Pending Jobs")
                }
                VStack{
                    HStack{
                        ZStack{
                            Image(systemName: "circle.fill")
                                .foregroundColor(Color.white)
                            Image(systemName: "12.circle.fill")
                                .foregroundColor(Color.poolRed)
                                .font(.title)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(width: 100, height: 100)
            .foregroundColor(Color.basicFontText)
            .background(Color.headerColor)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.basicFontText, radius: 6, x: 0, y: 0)
            )
        })
        
    }
    
    var dashboardDetails: some View {
            NavigationLink(value: Route.dashBoard(dataService: dataService), label: {

            HStack{
                Text("Dashboard")
            }
            .frame(width: 100, height: 100)
            .foregroundColor(Color.basicFontText)
            .background(Color.headerColor)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.basicFontText, radius: 6, x: 0, y: 0)
            )
        })
    }
    var routePreview: some View {
        Button(action: {
            masterDataManager.selectedCategory = .dailyDisplay
        }, label: {
            VStack{
                ZStack{
                    Circle()
                        .fill(.gray.opacity(0.5))
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: Double((activeRouteVM.finishedStops ?? 0)) / Double((activeRouteVM.totalStops ?? 0)))
                        .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 10, dash:[1,20]))
                        .fill(.black)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 20, dash:[1,54.1]))
                        .fill(.black)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(String(format:  "%.0f", activeRouteVM.finishedStops ?? 0)) / \(String(format:  "%.0f", activeRouteVM.totalStops ?? 0))")
                        .foregroundColor(Color.basicFontText)
                        .font(.headline)
                        .bold(true)
                }
            }
        })
        .padding(20)
        .frame(width: 100, height: 100)
        .foregroundColor(Color.basicFontText)
        .background(Color.headerColor // any non-transparent background
            .cornerRadius(5)
            .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
        )
        
    }
}
