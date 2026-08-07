//
//  FunctionsManager.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/6/26.
//
//  Functions In FunctionsManager
import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFunctions
import FirebaseFirestore

final class FunctionsManager {
        //Starting The App
    private var auth: Auth { Auth.auth() }
    private let functions = Functions.functions()
    private let db = Firestore.firestore()
    
    static let shared = FunctionsManager()
    private init(){}
    
        // MARK: acceptTechInvite
    func acceptTechInvite(inviteId: String, userId: String) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(
                domain: "AcceptTechInvite",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to accept an invite"]
            )
        }

        let idToken = try await currentUser.getIDToken()
        let payload: [String: Any] = [
            "inviteId": inviteId,
            "userId": userId,
            "idToken": idToken,
        ]
        
        let callable = functions.httpsCallable("acceptTechInvite")
        let result = try await callable.call(payload)
        
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][acceptTechInvite] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
        
        let status = json["status"] as? Int ?? 500
        guard status == 200 else {
            let message = json["error"] as? String ?? "Invite could not be accepted."
            print("      [FunctionsManager][acceptTechInvite] Error: \(message)")
            throw NSError(domain: "AcceptTechInvite", code: status, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    // MARK: convertHomeownerServiceRequestToCompanyCustomer
    func convertHomeownerServiceRequestToCompanyCustomer(companyId: String, leadId: String, payload: [String: Any] = [:]) async throws -> [String: Any] {
        var requestPayload = payload
        requestPayload["companyId"] = companyId
        requestPayload["leadId"] = leadId

        let callable = functions.httpsCallable("convertHomeownerServiceRequestToCompanyCustomer")
        let result = try await callable.call(requestPayload)

        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][convertHomeownerServiceRequestToCompanyCustomer] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }

        let status = json["status"] as? Int ?? 500
        guard status == 200 else {
            let message = json["error"] as? String ?? "Service request could not be converted."
            print("      [FunctionsManager][convertHomeownerServiceRequestToCompanyCustomer] Error: \(message)")
            throw NSError(domain: "ConvertHomeownerServiceRequest", code: status, userInfo: [NSLocalizedDescriptionKey: message])
        }

        return json
    }

    // MARK: updateServiceStopPermanently
    func updateServiceStopPermanently(companyId:String,serviceStopList:[ServiceStop],newTech:CompanyUser,newDay:DaysOfWeek){
        let serviceStopsPayload = serviceStopList.map { stop in
            [
                "id": stop.id,
                "recurringServiceStopId": stop.recurringServiceStopId,
                "operationStatus": stop.operationStatus.rawValue,
            ]
        }

        let newTechPayload: [String: Any] = [
            "id": newTech.id,
            "userId": newTech.userId,
            "userName": newTech.userName,
        ]

        let payload: [String: Any] = [
            "companyId": companyId,
            "serviceStopList": serviceStopsPayload,
            "newTech": newTechPayload,
            "newDay": newDay.rawValue,
        ]
        
        let callable = functions.httpsCallable("updateServiceStopDayPermanently")
        Task{
            do {
                let result = try await callable.call(payload)
                guard let data = result.data as? [String: Any],
                      let companyId = data["companyId"] as? String,
                      !companyId.isEmpty else {
                    throw NSError(domain: "CreateCompany", code: -1, userInfo: [NSLocalizedDescriptionKey: "Company ID not returned from function."])
                }
            } catch {
                print("      [FunctionsManager][updateServiceStopPermanently] Error: \(error)")
            }
        }
    }
    // MARK: updateRecurringRouteOrderPermanently
    func updateRecurringRouteOrderPermanently(
        companyId: String,
        routeId: String,
        recurringRouteOrder: [recurringRouteOrder],
        serviceStopOrders: [ServiceStopOrder]
    ) async throws {
        let recurringRouteOrderPayload = recurringRouteOrder.map { item in
            [
                "id": item.id,
                "order": item.order,
                "recurringServiceStopId": item.recurringServiceStopId,
                "customerId": item.customerId,
                "customerName": item.customerName,
                "locationId": item.locationId,
            ] as [String: Any]
        }

        let serviceStopOrdersPayload = serviceStopOrders.map { item in
            [
                "id": item.id,
                "order": item.order,
                "serviceStopId": item.serviceStopId,
                "recurringServiceStopId": item.recurringServiceStopId,
            ] as [String: Any]
        }

        let payload: [String: Any] = [
            "companyId": companyId,
            "routeId": routeId,
            "recurringRouteOrder": recurringRouteOrderPayload,
            "serviceStopOrders": serviceStopOrdersPayload,
        ]
        
        let callable = functions.httpsCallable("updateRecurringRouteOrderPermanently")
        let result = try await callable.call(payload)

        guard let data = result.data as? [String: Any] else {
            print("      [FunctionsManager][updateRecurringRouteOrderPermanently] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }

        let status = data["status"] as? Int ?? 500
        let success = data["success"] as? Bool ?? false
        guard status == 200 || success else {
            let message = data["error"] as? String ?? "Recurring route order could not be updated."
            print("      [FunctionsManager][updateRecurringRouteOrderPermanently] Error: \(message)")
            throw NSError(
                domain: "UpdateRecurringRouteOrder",
                code: status,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }
        // MARK: sendServiceReportOnFinish
    func sendServiceReportOnFinish(companyId:String, stopId:String) async throws {
        let payload: [String: Any]  = [
            "companyId":companyId,
            "serviceStopId":stopId,
        ]
        
        let callable = functions.httpsCallable("sendServiceReportOnFinish")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][sendServiceReportOnFinish] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
        print("    [FunctionsManager][sendServiceReportOnFinish] Sent Email \(json)")

    }
        // MARK: createFirstRecurringServiceStop
    func createFirstRecurringServiceStop(companyId:String, recurringServiceStop: RecurringServiceStop) async throws {
        let payload: [String: Any]  = [
            "companyId": companyId,
            "recurringServiceStop": [
                "id": recurringServiceStop.id,
                "internalId" : recurringServiceStop.internalId,
                "type" : recurringServiceStop.type,
                "typeId" : recurringServiceStop.typeId,
                "typeImage" : recurringServiceStop.typeImage,
                "customerName" : recurringServiceStop.customerName,
                "customerId" : recurringServiceStop.customerId,
                "address" : [
                    "streetAddress": recurringServiceStop.address.streetAddress,
                    "city": recurringServiceStop.address.city,
                    "state": recurringServiceStop.address.state,
                    "zip": recurringServiceStop.address.zip,
                    "latitude": recurringServiceStop.address.latitude,
                    "longitude": recurringServiceStop.address.longitude
                ] as [String: Any],
                "tech" : recurringServiceStop.tech,
                "techId": recurringServiceStop.techId,
                "dateCreated" : ms(recurringServiceStop.dateCreated),
                "startDate": ms(recurringServiceStop.startDate),
                "endDate" : ms(recurringServiceStop.endDate ?? nil),
                "noEndDate": recurringServiceStop.noEndDate,
                "frequency" : recurringServiceStop.frequency.rawValue,
                "day": recurringServiceStop.day.rawValue,
                "description": recurringServiceStop.description,
                "lastCreated": ms(recurringServiceStop.lastCreated),
                "serviceLocationId": recurringServiceStop.serviceLocationId,
                "estimatedTime": recurringServiceStop.estimatedTime,
                "otherCompany": recurringServiceStop.otherCompany,
                "laborContractId": recurringServiceStop.laborContractId ?? "",
                "contractedCompanyId": recurringServiceStop.contractedCompanyId ?? "",
                "mainCompanyId": recurringServiceStop.mainCompanyId ?? ""
                
            ] as [String: Any],
            
        ]
        print(payload)
        print("      [FunctionsManager][createFirstRecurringServiceStop] Calling Function")
        
        let callable = functions.httpsCallable("createFirstRecurringServiceStop2")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][createFirstRecurringServiceStop] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
    }
    func ms(_ date: Date?) -> Any {
        guard let d = date else { return NSNull() }
        return Int64(d.timeIntervalSince1970 * 1000)
    }
    
        // MARK: updateRecurringServiceStop
    func updateRecurringServiceStop(companyId:String, recurringServiceStop:RecurringServiceStop) async throws {
        let recurringServiceStopData = try recurringServiceStop.asDictionary()

        let payload: [String: Any]  = [
            "companyId":companyId,
            "recurringServiceStop":recurringServiceStopData,
        ]
        print("  [FunctionsManager][updateRecurringServiceStop]recurringServiceStopData: ")
        print(recurringServiceStopData)
        print("")
        let callable = functions.httpsCallable("updateRecurringServiceStop")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][updateRecurringServiceStop] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
    }
        // MARK: deleteRecurringServiceStop
    func deleteRecurringServiceStop(companyId:String, stopId:String) async throws {
        let payload: [String: Any]  = [
            "companyId":companyId,
            "stopId":stopId,
        ]
        let callable = functions.httpsCallable("deleteRecurringServiceStop")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][deleteRecurringServiceStop] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
    }
        // MARK: sendJobEstimate
    
func sendJobEstimate(companyId:String, jobId:String) async throws {
    let payload: [String: Any]  = [
        "companyId":companyId,
        "jobId":jobId,
    ]
    let callable = functions.httpsCallable("sendJobEstimateEmail")
    let result = try await callable.call(payload)
    guard let json = result.data as? [String: Any] else {
        print("      [FunctionsManager][sendJobEstimate] Error: Unable to read JSON from function response.")
        throw FireBaseRead.unableToRead
    }
}
}
