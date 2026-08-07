//
//  RouteFinder.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/21/23.
//

import Foundation

enum DeepLinkURLs:String {
    case customer
    case share
}

struct SharedRecordReference: Hashable {
    var type:String
    var recordId:String
    var companyId:String?
    var customerId:String?
    var customerUserId:String?
    var audience:String?
    var chatId:String?
    var title:String?

    var linkType:ConversationLinkType {
        ConversationLinkType.normalized(type)
    }

    var category:MacCategories {
        if type == "chat" || chatId == recordId {
            return .chat
        }
        return linkType.alertCategory
    }

    var routeString:RouteString {
        if type == "chat" || chatId == recordId {
            return .chat
        }
        if let route = linkType.mobileRouteString.flatMap({ RouteString(rawValue: $0) }) {
            return route
        }
        return .alerts
    }

    var appURLString:String {
        var components = URLComponents()
        components.scheme = "dripdrop"
        components.host = "share"
        components.queryItems = queryItems
        return components.url?.absoluteString ?? "dripdrop://share"
    }

    private var queryItems:[URLQueryItem] {
        var items = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "id", value: recordId)
        ]
        if let companyId, !companyId.isEmpty {
            items.append(URLQueryItem(name: "companyId", value: companyId))
        }
        if let customerId, !customerId.isEmpty {
            items.append(URLQueryItem(name: "customerId", value: customerId))
        }
        if let customerUserId, !customerUserId.isEmpty {
            items.append(URLQueryItem(name: "customerUserId", value: customerUserId))
        }
        if let audience, !audience.isEmpty {
            items.append(URLQueryItem(name: "audience", value: audience))
        }
        if let chatId, !chatId.isEmpty {
            items.append(URLQueryItem(name: "chatId", value: chatId))
        }
        if let title, !title.isEmpty {
            items.append(URLQueryItem(name: "title", value: title))
        }
        return items
    }
}

struct RouteFinder {
    func find(from url:URL,dataService:any ProductionDataServiceProtocol) -> Route? {
        guard let host = url.host() else {return nil}
        switch DeepLinkURLs(rawValue: host){
        case .customer:
            let queryParams = url.queryParameters
            guard let itemQueryVal = queryParams?["id"] as? String else {return nil}
            let customer =  Customer(
                id: itemQueryVal,
                firstName: "",
                lastName: "",
                email: "",
                billingAddress: Address(
                    streetAddress: "",
                    city: "",
                    state: "",
                    zip: "",
                    latitude: 0,
                    longitude: 0
                ),
                active: true,
                displayAsCompany: true,
                hireDate: Date(),
                billingNotes: "",
                linkedInviteId: UUID().uuidString
            )
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

    func findSharedRecordReference(from url:URL) -> SharedRecordReference? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        let host = url.host()?.lowercased()
        let isShareURL = host == DeepLinkURLs.share.rawValue || components.path == "/share"
        guard isShareURL else { return nil }

        let params = url.queryParameters ?? [:]
        guard
            let type = params["type"]?.trimmingCharacters(in: .whitespacesAndNewlines),
            !type.isEmpty
        else { return nil }

        let recordId = (
            params["id"] ??
            params["recordId"] ??
            params["sourceId"] ??
            params["chatId"] ??
            ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !recordId.isEmpty else { return nil }

        return SharedRecordReference(
            type: type,
            recordId: recordId,
            companyId: params["companyId"],
            customerId: params["customerId"],
            customerUserId: params["customerUserId"],
            audience: params["audience"],
            chatId: params["chatId"],
            title: params["title"]
        )
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
