//
//  RouteFinder.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/21/23.
//

import Foundation

enum DeepLinkURLs:String {
    case customer
}

struct RouteFinder {
    func find(from url:URL,dataService:any ProductionDataServiceProtocol) -> Route? {
        guard let host = url.host() else {return nil}
        switch DeepLinkURLs(rawValue: host){
        case .customer:
            let queryParams = url.queryParameters
            guard let itemQueryVal = queryParams?["id"] as? String else {return nil}
            let customer =  Customer(id: itemQueryVal, firstName: "", lastName: "", email: "", billingAddress: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), active: true, displayAsCompany: true, hireDate: Date(), billingNotes: "")
            print("Returning Customer")
            return .customer(customer: customer, dataService: dataService)
            
        default:
            print("Returning Nil")
            return nil
        }
    }
    func find2(from url:URL) -> (category:MacCategories,id:String)? {
        guard let host = url.host() else {return nil}
        switch DeepLinkURLs(rawValue: host){
        case .customer:
            let queryParams = url.queryParameters
            guard let itemQueryVal = queryParams?["id"] as? String else {return nil}

            print("Returning Customer \(itemQueryVal)")
            return (category:.customers,id:itemQueryVal)
            
        default:
            print("Returning Nil")

            return nil
        }
    }
}
extension URL {
    public var queryParameters: [String:String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String:String]()){ (result,item) in
            result[item.name] = item.value?.replacingOccurrences(of: "+", with: " ")
        }
    }
}
