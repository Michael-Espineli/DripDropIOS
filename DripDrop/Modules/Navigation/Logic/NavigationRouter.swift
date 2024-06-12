//
//  NavigationRouter.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//

import Foundation
import SwiftUI

final class NavigationRouter: ObservableObject {
    @Published var routes = [Route]()
    @Published var selectedCategory:MenuCategory?

    @Published var selectedItemId: String?

    func push(to screen: Route) {
            return
        
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
