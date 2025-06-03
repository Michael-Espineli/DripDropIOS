//
//  NavigationCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct NavigationCardView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    let route:Route
    var body: some View {
        
NavigationLink(value: route, label: {

            HStack(spacing:3){
                Text("\(route.title())")
                    .font(.callout)
                    .lineLimit(2)
                
                Spacer()

            }
            .padding(3)
            .frame(height: 40)
            .foregroundColor(Color.white)
            .background(Color.darkGray)
            .cornerRadius(6)
            .fontDesign(.monospaced)
            .padding(3)
        })
    }
}
struct NavigationCardView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        NavigationCardView(route: .dashBoard(dataService: dataService))
    }
}
