//
//  RecentActivity.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI

struct RecentActivity: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale
    init(dataService: any ProductionDataServiceProtocol){
        _recurringRouteVM = StateObject(wrappedValue: RecurringRouteViewModel(dataService: dataService))
        _activeRouteVM = StateObject(wrappedValue: ActiveRouteViewModel(dataService: dataService))

    }
    @StateObject var activeRouteVM : ActiveRouteViewModel
    @StateObject var recurringRouteVM : RecurringRouteViewModel
    
    var body: some View {
        ScrollView{
            summary
            Divider()

            routeList
        }
        .navigationTitle("Recent Activity")
        .task {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    //Get Recent Routes - 7 Days -> 30 days
                    try await activeRouteVM.getRecentActiveRouteForTech(companyId: company.id, techId: user.id, days: 7)
                    activeRouteVM.calculateRouteSummary(activeRouteList: activeRouteVM.listOfActiveRoutes)
                } catch {
                    print(error)
                }
            }
        }
    }
    
}

struct RecentActivity_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivity(dataService: MockDataService())
    }
}
extension RecentActivity {
    var summary: some View {
        VStack{
            HStack{
                Text("Stops : ")
                if let finished = activeRouteVM.finishedStops {
                    Text("\(String(format:  "%.0f",finished))")
                } else {
                    Text("Error")
                }
                Text(" / ")
                if let total = activeRouteVM.totalStops {
                    Text("\(String(format:  "%.0f",total))")
                } else {
                    Text("Error")
                }
                if let total = activeRouteVM.totalStops, let finished = activeRouteVM.finishedStops {
                    Text("\(String(format:  "%.2f",finished / total))")
                }
            }

            HStack{
                Spacer()
                if let total = activeRouteVM.totalMiles {
                    Text(" (\(Measurement(value:total, unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))))")

                        .foregroundColor(Color.white)
                }
            }
            HStack{
                Text("Total Time : ")

                if let total = activeRouteVM.totalTime {
                    Text(displayNumberAsMinAndHourAndSecond(seconds: Int(total)))
                } else {
                    Text("Error")
                }
            }
            HStack{
                Spacer()
                if let total = activeRouteVM.totalTime {
                    Text(" (\(displayMinAsMinAndHour(min:Int(total))))")
                }
            }
        }
    }
    var routeList: some View {
        VStack{
            
            Text("Recent Routes")
                .font(.headline)
            ForEach(activeRouteVM.listOfActiveRoutes){ activeRoute in
                ActiveRouteCardView(activeRoute: activeRoute)
                    .modifier(ListButtonModifier())
                    .padding(.horizontal,8)
            }
        }
    }
}
