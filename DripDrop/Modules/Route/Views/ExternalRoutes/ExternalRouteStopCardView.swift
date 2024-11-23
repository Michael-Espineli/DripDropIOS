//
//  ExternalRouteStopCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/29/24.
//

import SwiftUI

struct ExternalRouteStopCardView: View {
    let externalRouteStop : ExternalRouteStop
    var body: some View {
        VStack{
            Text("\(externalRoute.recurringServicestopId) - \(externalRoute.techName) - \(externalRoute.day)")
            Text("\(externalRoute.companyName)")
        }
        .fontDesign(.monospaced)
        .foregroundColor(Color.poolWhite)
    }
}

//#Preview {
//    ExternalRouteCardView()
//}
