//
//  PerformanceHistoryCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import SwiftUI

struct PerformanceHistoryCardView: View {
    let performanceHistory:PerformaceHistory
    var body: some View {
        HStack{
            Text("\(shortDate(date: performanceHistory.date))")
            Text("\(performanceHistory.description)")
            switch performanceHistory.performaceHistoryType {
            case .kudo:
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(Color.poolGreen)
            case .complaint:
                Image(systemName: "hand.thumbsdown.fill")
                    .foregroundColor(Color.poolRed)
            }
            Spacer()
            Button(action: {
                
            }, label: {
                HStack{
                    Text("See More")
                    Image(systemName: "arrow.right")
                }
                    .foregroundColor(Color.poolRed)
            })
        }
    }
}
//
//#Preview {
//    PerformanceHistoryCardView(performanceHistory: <#PerformaceHistory#>)
//}
