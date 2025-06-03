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
            Text("\(externalRouteStop.recurringServicestopId) - \(externalRouteStop.day)")
        }
        .fontDesign(.monospaced)
        .foregroundColor(Color.poolWhite)
    }
}

//#Preview {
//    ExternalRouteCardView()
//}
