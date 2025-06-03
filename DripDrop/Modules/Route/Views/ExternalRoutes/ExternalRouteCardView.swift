//
//  ExternalRouteCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/29/24.
//

import SwiftUI

struct ExternalRouteCardView: View {
    let externalRoute : ExternalRoute
    var body: some View {
        VStack{
            HStack{
                Text(" \(externalRoute.techName)")
                Spacer()
                Text("\(externalRoute.day)")
            }
            Text("\(externalRoute.companyName)")
        }
        .modifier(ListButtonModifier())
        .fontDesign(.monospaced)
        .foregroundColor(Color.poolWhite)
    }
}

//#Preview {
//    ExternalRouteCardView()
//}
