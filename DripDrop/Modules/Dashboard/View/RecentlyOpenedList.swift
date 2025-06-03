//
//  RecentlyOpenedList.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/9/24.
//

import SwiftUI

struct RecentlyOpenedList: View {
    init(dataService:any ProductionDataServiceProtocol,recentActivityList:[RecentActivityModel]){
        _VM = StateObject(wrappedValue: CompanyAlertViewModel(dataService: dataService))
        _recentActivityList = State(wrappedValue: recentActivityList)
    }
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject var VM : CompanyAlertViewModel

    @State var recentActivityList: [RecentActivityModel]

    var body: some View {
        HStack(spacing:6){
            VStack(spacing:3){
                ForEach(Array(recentActivityList.prefix(4))) { datum in
                    ReceentlyOpenedCardView(dataService: dataService, recentActivity: datum)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            VStack(spacing:3){
                ForEach(Array(recentActivityList.suffix(4))) { datum in
                    ReceentlyOpenedCardView(dataService: dataService, recentActivity: datum)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
}

#Preview {
    RecentlyOpenedList(dataService: MockDataService(), recentActivityList: [])
}
