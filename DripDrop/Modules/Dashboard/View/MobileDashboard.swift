//
//  MobileDashboard.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct MobileDashboard: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
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
        GridItem(.adaptive(minimum: 100))
    ]
    @State var isLoading : Bool = false
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                routePreview
                if UIDevice.isIPhone {
                    dashboardDetails
                    
                }
                todoList
                pendingJobs
                shoppingList
                unassignedPurchasedItems
                repairRequests
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

struct MobileDashboard_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        MobileDashboard(dataService: dataService)
    }
}
extension MobileDashboard{
    
    var repairRequests: some View {
            NavigationLink(value: Route.repairRequestList(dataService: dataService), label: {
            ZStack{
                VStack{
                    Spacer()
                    ZStack{
                        Color.poolBlue
                        Text("Repair Requests")
                            .foregroundColor(Color.white)
                    }
                    .frame(height: 50)
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
            .frame(minWidth: 80, idealWidth: 100, maxWidth: 120, minHeight: 80, idealHeight: 100, maxHeight: 120)
            .foregroundColor(Color.basicFontText)
            .background(Color.gray)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(10)
                .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
            )
        })
        
    }
    
    var todoList: some View {
            NavigationLink(value: Route.toDoList(dataService: dataService), label: {
            ZStack{
                VStack(alignment: .leading){
                    Spacer()
                    ZStack{
                        Color.poolBlue
                        Text("To Do List")
                            .foregroundColor(Color.white)
                    }
                    .frame(height: 50)

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
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
            }
            .frame(minWidth: 80, idealWidth: 100, maxWidth: 120, minHeight: 80, idealHeight: 100, maxHeight: 120)
            .foregroundColor(Color.basicFontText)
            .background(Color.gray)
            .cornerRadius(10)
            .background(Color.white // any non-transparent background
                .cornerRadius(10)
                .shadow(color: Color.basicFontText, radius: 6, x: 0, y: 0)
            )
        })
        
    }
    var shoppingList: some View {

            NavigationLink(value: Route.shoppingList(dataService: dataService), label: {

            ZStack{
                VStack(alignment: .leading){
                    Spacer()
                    ZStack{
                        Color.poolBlue
                        Text("Shopping List")
                            .foregroundColor(Color.white)
                    }
                    .frame(height: 50)

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
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
            }
            .frame(minWidth: 80, idealWidth: 100, maxWidth: 120, minHeight: 80, idealHeight: 100, maxHeight: 120)
            .foregroundColor(Color.basicFontText)
            .background(Color.gray)
            .cornerRadius(10)
            .background(Color.white // any non-transparent background
                .cornerRadius(10)
                .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
            )
        })
        
    }
    var unassignedPurchasedItems: some View {

            NavigationLink(value: Route.purchasedItemsList(dataService: dataService), label: {

            ZStack{
                VStack(alignment: .leading){
                Spacer()
                    ZStack{
                        Color.poolBlue
                        Text("Purchased Items")
                            .foregroundColor(Color.white)
                    }
                    .frame(height: 50)

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
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))

            }
            .frame(minWidth: 80, idealWidth: 100, maxWidth: 120, minHeight: 80, idealHeight: 100, maxHeight: 120)
            .foregroundColor(Color.basicFontText)
            .background(Color.gray)
            .cornerRadius(10)
            .background(Color.white // any non-transparent background
                .cornerRadius(10)
                .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
            )
        })
        
    }
    
    var pendingJobs: some View {

            NavigationLink(value: Route.pendingJobs(dataService: dataService), label: {

            ZStack{
                VStack(alignment: .leading){
                    Spacer()
                    ZStack{
                        Color.poolBlue
                        Text("Pending Jobs")
                            .foregroundColor(Color.white)
                    }
                    .frame(height: 50)
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
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
            }
            .frame(minWidth: 80, idealWidth: 100, maxWidth: 120, minHeight: 80, idealHeight: 100, maxHeight: 120)
            .foregroundColor(Color.gray)
            .background(Color.gray)
            .cornerRadius(10)
            .background(Color.white // any non-transparent background
                .cornerRadius(10)
                .shadow(color: Color.basicFontText, radius: 6, x: 0, y: 0)
            )
        })
        
    }
    
    var dashboardDetails: some View {

            NavigationLink(value: Route.dashBoard(dataService: dataService), label: {

            HStack{
                VStack(alignment: .leading){
                    Spacer()
                    ZStack{
                        Color.poolBlue
                        Text("Dashboard")
                            .foregroundColor(Color.white)
                    }
                    .frame(height: 50)
                }
            }
            .frame(minWidth: 80, idealWidth: 100, maxWidth: 120, minHeight: 80, idealHeight: 100, maxHeight: 120)
            .foregroundColor(Color.basicFontText)
            .background(Color.gray)
            .cornerRadius(10)
            .background(Color.white // any non-transparent background
                .cornerRadius(10)
                .shadow(color: Color.basicFontText, radius: 6, x: 0, y: 0)
            )
        })
    }
    var routePreview: some View {
            NavigationLink(value: Route.mainDailyDisplayView(dataService: dataService), label: {

            VStack{
                ZStack{
                    Circle()
                        .fill(.gray.opacity(0.5))
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: Double(activeRouteVM.finishedStops ?? 0) / Double(activeRouteVM.totalStops ?? 0))
                        .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 10, dash:[1,20]))
                        .fill(.black)
                        .rotationEffect(.degrees(-90))
                    Text("\(String(format:  "%.0f", activeRouteVM.finishedStops ?? 0)) / \(String(format:  "%.0f", activeRouteVM.totalStops ?? 0))")
                        .foregroundColor(Color.basicFontText)
                        .font(.headline)
                        .bold(true)
                }
            }
        })
        .foregroundColor(Color.basicFontText)
        .background(Color.gray // any non-transparent background
            .cornerRadius(10)
            .shadow(color: Color.basicFontText, radius: 6, x: 2, y: 2)
        )
        
    }
}

