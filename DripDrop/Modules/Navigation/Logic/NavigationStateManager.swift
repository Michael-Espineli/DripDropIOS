//
//  NavigationStateManager.swift
//  TripleColumnNavigationSplitProject
//
//  Created by Karin Prater on 13.11.22.
//

import SwiftUI
import Combine

class NavigationStateManager: ObservableObject {
//    @Published var routes = [Route]()
    @Published var routes:[Route] = []

    func setSelectedCustomer(to customer: Customer) {
        
    }
    func push(to screen: Route) {
        guard !routes.contains(screen) else {
            return
        }
        routes.append(screen)
    }
    func goBack() {
        _ = routes.popLast()
    }
    func reset() {
        routes.removeLast(routes.count)
    }
    func replace(stack: [Route]) {
        routes = stack
    }
    func getRoute(for item: any ServiceItemProtocol) -> Route? {
        switch item {
            //        case is Job:
            //            return Route.serviceItem(item: item as! Job)
            //        case is ServiceHistory:
            //            return Route.serviceItem(item: item as! ServiceHistory)
            //
            //        case is MessageGroup:
            //            return Route.serviceItem(item: item as! MessageGroup)
            //        case is Invoice:
            //            return Route.serviceItem(item: item as! Invoice)
            //        case is ServiceLocation:
            //            return Route.serviceItem(item: item as! ServiceLocation)
        default:
            return nil
        }
    }
}
