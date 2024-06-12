//
//  Public.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct PublicView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var dataService: ProductionDataService

    let data = (1...100).map { "Item \($0)" }

    let columns = [
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    let recentActivity: [Route] = []

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    MobileDashboard(dataService:dataService)
                    items
                }
            }
        }
        
    }
}

struct PublicView_Previews: PreviewProvider {
    static var previews: some View {
        PublicView()
    }
}
extension PublicView {
    var items: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
        }
    }
  
//    var recentlyOpened: some View {
//            LazyVGrid(columns: columns, spacing: 4) {
//
//
//                /*
//                ForEach(recentActivity, id:\.self) {
//                    NavigationCardView(route: $0)//DEVELOPER SAFELY UNWRAP
//                }
//                 */
//                NavigationCardView(route: .customers)
//                NavigationCardView(route: .serviceStops)
//                NavigationCardView(route: .repairRequestList)
//                NavigationCardView(route: .repairRequestList)
//                NavigationCardView(route: .customers)
//                NavigationCardView(route: .serviceStops)
//                NavigationCardView(route: .repairRequestList)
//                NavigationCardView(route: .repairRequestList)
//            }
//            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
//    }
    
}
