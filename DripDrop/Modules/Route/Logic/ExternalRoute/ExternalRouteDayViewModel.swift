//
//  ExternalRouteDayViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/29/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
struct ExternalRoute:Identifiable, Codable, Hashable{
    var id:String = UUID().uuidString
    var companyId:String
    var companyName:String
    var day:String
    var techId:String
    var techName:String
}
@MainActor
final class ExternalRouteDayViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var externalRoutesWithStops:[ExternalRoute:[ExternalRouteStop]] = [:]
    @Published private(set) var externalRoutes:[ExternalRoute] = []

    func onLoad(companyId:String,day:String,externalRoutestopList:[ExternalRouteStop])async throws {
        for stop in externalRoutestopList {
            if self.externalRoutes.contains(where: {$0.companyId == stop.companyId && $0.techId == stop.techId && $0.day == stop.day}){
                print("Already Contains")
            } else {
                print("Does Not Contain")
                self.externalRoutes.append(
                    ExternalRoute(
                        companyId: stop.companyId,
                        companyName: stop.companyName,
                        day: stop.day,
                        techId: stop.techId,
                        techName: stop.techName
                    )
                )
            }
        }
        for route in self.externalRoutes {
            let list = externalRoutestopList.filter({$0.companyId == route.companyId && $0.techId == route.techId && $0.day == route.day})
            self.externalRoutesWithStops[route] = list
        }
    }
}
