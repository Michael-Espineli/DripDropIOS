//
//  RouteTechView2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/7/26.
//

import SwiftUI

struct RouteTechView2: View {

    @EnvironmentObject var VM: RouteBoardViewModel

    let tech: CompanyUser
    let day: String

    var route: RecurringRoute? {
        VM.route(for: tech.userId, day: day)
    }

    var stops: [RecurringServiceStop] {
        VM.stops(for: tech.userId, day: day)
    }

    var body: some View {
        VStack {
            if let route {
                Text(route.tech)

                ForEach(route.order) { order in
                    Text(order.customerName)
                }
            }
        }
    }
}
