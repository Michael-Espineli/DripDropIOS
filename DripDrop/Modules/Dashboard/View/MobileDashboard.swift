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
 //DEVELOPER CONSAOLIDATE STATO BJECTS
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var activeRouteVM : ActiveRouteViewModel
    @StateObject var recurringRouteVM : RecurringRouteViewModel
    @StateObject var toDoVM : ToDoViewModel
    @StateObject var shoppingListVM : ShoppingListViewModel
    @StateObject var repairRequestVM : RepairRequestViewModel
    @StateObject var purchaseVM : PurchasesViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _shoppingListVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        _toDoVM = StateObject(wrappedValue: ToDoViewModel(dataService: dataService))
        _recurringRouteVM = StateObject(wrappedValue: RecurringRouteViewModel(dataService: dataService))
        _purchaseVM = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))
        _activeRouteVM = StateObject(wrappedValue: ActiveRouteViewModel(dataService: dataService))
    }
    let data = (1...100).map { "Item \($0)" }
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 14)
    ]
    @State var isLoading : Bool = false
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
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
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .task{
            isLoading = true
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    let recurringRouteId = weekDay(date: Date()) + user.id
                    print(recurringRouteId)
                    //DEVELOPER
                    print("Developer")
//                    try await recurringRouteVM.getSingleRoute(companyId: company.id, recurringRouteId: recurringRouteId)
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
        NavigationLink(value: Route.repairRequestList(dataService: dataService)) {
            dashboardActionTile(
                title: "Repair Requests",
                systemImage: "wrench.and.screwdriver",
                badgeCount: repairRequestVM.count
            )
        }
        .buttonStyle(.plain)
    }

    var todoList: some View {
        NavigationLink(value: Route.toDoList(dataService: dataService)) {
            dashboardActionTile(
                title: "To Do List",
                systemImage: "checklist",
                badgeCount: toDoVM.toDoListCount
            )
        }
        .buttonStyle(.plain)
    }

    var shoppingList: some View {
        NavigationLink(value: Route.shoppingList(dataService: dataService)) {
            dashboardActionTile(
                title: "Shopping List",
                systemImage: "cart",
                badgeCount: shoppingListVM.shoppingListItemCount
            )
        }
        .buttonStyle(.plain)
    }

    var unassignedPurchasedItems: some View {
        NavigationLink(value: Route.purchasedItemsList(dataService: dataService)) {
            dashboardActionTile(
                title: "Purchased Items",
                systemImage: "shippingbox",
                badgeCount: purchaseVM.purchaseCount
            )
        }
        .buttonStyle(.plain)
    }

    var pendingJobs: some View {
        NavigationLink(value: Route.pendingJobs(dataService: dataService)) {
            dashboardActionTile(
                title: "Pending Jobs",
                systemImage: "briefcase",
                badgeCount: 12
            )
        }
        .buttonStyle(.plain)
    }

    var dashboardDetails: some View {
        NavigationLink(value: Route.dashBoard(dataService: dataService)) {
            dashboardActionTile(
                title: "Dashboard",
                systemImage: "rectangle.grid.2x2"
            )
        }
        .buttonStyle(.plain)
    }

    var routePreview: some View {
        NavigationLink(value: Route.mainDailyDisplayView(dataService: dataService)) {
            dashboardTile {
                VStack(alignment: .leading, spacing: 10) {
                    routeProgressRing

                    Spacer(minLength: 8)

                    Text("Today's Route")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(routeStopSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    var routeProgressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.14), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            Circle()
                .trim(from: 0, to: routeProgress)
                .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))

            Text("\(activeRouteVM.finishedStops ?? 0)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(width: 58, height: 58)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(routeStopSummary)
    }

    var routeProgress: Double {
        guard let totalStops = activeRouteVM.totalStops, totalStops > 0 else {
            return 0
        }

        let finishedStops = min(max(activeRouteVM.finishedStops ?? 0, 0), totalStops)
        return Double(finishedStops) / Double(totalStops)
    }

    var routeStopSummary: String {
        "\(activeRouteVM.finishedStops ?? 0) of \(activeRouteVM.totalStops ?? 0) stops"
    }

    func dashboardActionTile(
        title: String,
        systemImage: String,
        badgeCount: Int? = nil
    ) -> some View {
        dashboardTile {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.14), in: Circle())

                    Spacer(minLength: 8)

                    dashboardBadge(count: badgeCount)
                }

                Spacer(minLength: 8)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    func dashboardTile<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }

    @ViewBuilder
    func dashboardBadge(count: Int?) -> some View {
        if let count, count > 0 {
            Text(count > 50 ? "50+" : "\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(minWidth: 24, minHeight: 24)
                .padding(.horizontal, count > 9 ? 4 : 0)
                .background(Color.poolRed, in: Capsule())
                .accessibilityLabel("\(count) items")
        }
    }
}
