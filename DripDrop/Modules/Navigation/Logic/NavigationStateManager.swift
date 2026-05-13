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
            print("")
            print("[NavigationStateManager][push] Returning as already in stack")
            routes.append(screen)
            return
        }
        print("")
        print("[NavigationStateManager][push] oldList: \(screen)")
        routes.append(screen)
    }
    func goBack() {
        _ = routes.popLast()
    }
    
    func goBackTwice() {
        _ = routes.popLast()
        _ = routes.popLast()
    }
    func reset() {
        routes.removeLast(routes.count)
    }
    func replace(stack: [Route]) {
        print("")
        print("[NavigationStateManager][replace] routes \(routes)")

        routes = stack
        print("")
        print("[NavigationStateManager][replace] stack \(stack)")

    }
    func replaceLast(new: Route) {
        guard !routes.isEmpty else {
            routes = [new]
            print("")
            print("[NavigationStateManager][replaceLast] return")
            return
        }
        var newList = routes
        print("")
        print("[NavigationStateManager][replaceLast] oldList: \(newList.count) - \(newList.last)")
        newList.removeLast()
        newList.append(new)
        print("")
        print("[NavigationStateManager][replaceLast] newList: \(newList.count) - \(newList.last)")
        routes = newList
        print("")
        print("[NavigationStateManager][replaceLast] publishedRoute: \(routes.count) - \(routes.last)")
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
