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
                ZStack{
                    Color.poolBlue
                    Image(systemName: "doc.fill")
                }
                .frame(width: 40,height: 40)
                Divider()
                Text("\(route.title())")
                    .font(.callout)
                    .lineLimit(2)
                Spacer()

            }
            .foregroundColor(Color.white)
            .background(Color.darkGray)
            .cornerRadius(6)
            .fontDesign(.monospaced)
        })
    }
}
struct NavigationCardView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        NavigationCardView(route: .dashBoard(dataService: dataService))
    }
}
