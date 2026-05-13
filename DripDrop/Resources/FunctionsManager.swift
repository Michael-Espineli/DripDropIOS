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
    func updateServiceStopPermanently(companyId:String,serviceStopList:[ServiceStop],newTech:CompanyUser,newDay:DaysOfWeek){
        let payload: [String: Any] = [
            "companyId": companyId,
            "serviceStopList": serviceStopList,
            "newTech": newTech,
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
    func updateRecurringRouteOrderPermanently(companyId:String, routeId:String, recurringRouteOrder:[recurringRouteOrder],serviceStopOrders:[ServiceStopOrder]){
        let payload: [String: Any] = [
            "companyId": companyId,
            "routeId": routeId,
            "recurringRouteOrder": recurringRouteOrder,
            "serviceStopOrders":serviceStopOrders,
        ]
        
        
        let callable = functions.httpsCallable("updateRecurringRouteOrderPermanently")
        Task{
            do {
                let result = try await callable.call(payload)
                guard let data = result.data as? [String: Any],
                      let companyId = data["companyId"] as? String,
                      !companyId.isEmpty else {
                    throw NSError(domain: "CreateCompany", code: -1, userInfo: [NSLocalizedDescriptionKey: "Company ID not returned from function."])
                }
            } catch {
                print("      [FunctionsManager][updateRecurringRouteOrderPermanently] Error: \(error)")
            }
        }
    }
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
        
        
        let callable2 = functions.httpsCallable("sendservicereportonfinish")
        let result2 = try await callable2.call(payload)
        guard let json = result2.data as? [String: Any] else {
            print("      [FunctionsManager][sendServiceReportOnFinish][2] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
        print("    [FunctionsManager][sendServiceReportOnFinish] Sent Email 1 and 2")

    }
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
                "laborContractId": recurringServiceStop.laborContractId ?? nil,
                "contractedCompanyId": recurringServiceStop.contractedCompanyId ?? nil,
                "mainCompanyId": recurringServiceStop.mainCompanyId ?? nil
                
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
    func deleteRecurringServiceStop(companyId:String, stopId:String) async throws {
        let payload: [String: Any]  = [
            "companyId":companyId,
            "recurringServiceStop":stopId,
        ]
        let callable = functions.httpsCallable("deleteRecurringServiceStop")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][sendServiceReportOnFinish] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
    }
}
