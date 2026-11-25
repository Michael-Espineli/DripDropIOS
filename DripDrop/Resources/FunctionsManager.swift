//
//  FunctionsManager.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/6/26.
//
//  Functions In FunctionsManager
import Foundation
import SwiftUI
import UIKit
import Combine
import FirebaseAuth
import FirebaseFunctions
import FirebaseFirestore

struct ServiceReportSendResult: Equatable {
    let status: Int
    let account: String
    let category: String
    let customerActionUrl: String
    let claimAccountUrl: String
    let to: String
    let intendedTo: String
    let testMode: Bool

    var wasSent: Bool {
        status == 200 && account.localizedCaseInsensitiveContains("Successfully Sent")
    }

    var emailIsTurnedOff: Bool {
        account.localizedCaseInsensitiveContains("turned off")
    }

    var recipientDisplayText: String {
        if testMode, !intendedTo.isEmpty {
            return "\(to) (test for \(intendedTo))"
        }

        return to
    }

    var userFacingMessage: String {
        if wasSent {
            let recipient = recipientDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
            return recipient.isEmpty ? "Service report sent to the customer." : "Service report sent to \(recipient)."
        }

        if emailIsTurnedOff {
            return "Service report email is turned off in email settings."
        }

        return account.isEmpty ? "Service report request completed." : account
    }
}

struct ServiceAgreementSendResult: Equatable {
    let status: Int
    let message: String
    let agreementUrl: String
    let to: String
    let intendedTo: String
    let additionalEmails: [String]
    let recipientEmails: [String]
    let sentCount: Int
    let testMode: Bool

    var userFacingMessage: String {
        if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        if sentCount > 1 {
            return "Service agreement sent to \(sentCount) recipients."
        }

        let recipient = intendedTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? to : intendedTo
        return recipient.isEmpty ? "Service agreement sent." : "Service agreement sent to \(recipient)."
    }
}

enum RouteMovePayload {
    static func make(companyId: String, stops: [ServiceStop], serviceDate: Date, techId: String) -> [String: Any] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let selected: [[String: Any]] = stops.sorted { $0.id < $1.id }.map { stop in
            var value: [String: Any] = ["id": stop.id, "techId": stop.techId,
                "serviceDateMillis": (stop.serviceDate.timeIntervalSince1970 * 1000).rounded(.towardZero)]
            if let revision = stop.assignmentRevision { value["assignmentRevision"] = revision }
            return value
        }
        return ["companyId": companyId, "action": "oneTime", "techId": techId,
            "serviceDateKey": formatter.string(from: serviceDate), "timeZone": TimeZone.current.identifier, "stops": selected]
    }
}

private actor RouteMoveRequests {
    private var pending: [String: String] = [:]
    func requestId(for key: String) -> String {
        if let existing = pending[key] { return existing }
        let id = UUID().uuidString
        pending[key] = id
        return id
    }
    func finished(_ key: String) { pending.removeValue(forKey: key) }
}

final class FunctionsManager {
        //Starting The App
    private var auth: Auth { Auth.auth() }
    private let functions = Functions.functions()
    private let db = Firestore.firestore()
    private let routeMoveRequests = RouteMoveRequests()
    
    static let shared = FunctionsManager()
    private init(){}
    
    func billingCommand(_ name: String, payload: [String: Any]) async throws -> [String: Any] {
        let commands: Set<String> = ["manageSalesInvoice", "manageStripeInvoice", "manageSalesPayment", "sendSalesPaymentReceipt", "createSavedPaymentSetup", "listSavedPaymentMethods", "chargeSavedInvoice"]
        guard commands.contains(name) else { throw FireBaseRead.unableToRead }
        return try await technicianWorkflow(name, payload: payload)
    }

    func technicianWorkflow(_ name: String, payload: [String: Any]) async throws -> [String: Any] {
        let result = try await functions.httpsCallable(name).call(payload)
        guard let data = result.data as? [String: Any] else { throw FireBaseRead.unableToRead }
        return data
    }

    func manageWork(companyId: String, offerId: String, action: String, extra: [String: Any] = [:]) async throws -> [String: Any] {
        var payload = extra
        payload["companyId"] = companyId; payload["offerId"] = offerId; payload["action"] = action
        return try await technicianWorkflow("manageTechnicianWork", payload: payload)
    }

    func refreshServiceStopPayroll(companyId: String, serviceStopId: String) async throws {
        _ = try await functions.httpsCallable("refreshServiceStopPayroll").call([
            "companyId": companyId, "serviceStopId": serviceStopId
        ])
    }

    func clearZeroDollarPayrollTasks(companyId: String, lineItemIds: [String]) async throws {
        _ = try await functions.httpsCallable("clearZeroDollarPayrollTasks").call([
            "companyId": companyId, "lineItemIds": lineItemIds
        ])
    }

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
    func moveServiceStops(companyId: String, stops: [ServiceStop], serviceDate: Date, techId: String) async throws {
        var payload = RouteMovePayload.make(companyId: companyId, stops: stops, serviceDate: serviceDate, techId: techId)
        let key = (auth.currentUser?.uid ?? "") + (try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]).base64EncodedString())
        payload["requestId"] = await routeMoveRequests.requestId(for: key)
        let data = try await technicianWorkflow("manageRouteWork", payload: payload)
        guard data["status"] as? Int == 200 else {
            throw NSError(domain: "RouteMove", code: -1, userInfo: [NSLocalizedDescriptionKey: data["error"] as? String ?? "The move was not confirmed."])
        }
        await routeMoveRequests.finished(key)
    }

    func updateServiceStopPermanently(companyId:String,serviceStopList:[ServiceStop],newTech:CompanyUser,newDay:DaysOfWeek) async throws {
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
        
        let data = try await reviewedRecurringChange("updateServiceStopDayPermanently", payload: payload)
        guard data["status"] as? Int == 200, data["companyId"] as? String == companyId else {
            throw NSError(domain: "PermanentRouteMove", code: -1, userInfo: [NSLocalizedDescriptionKey: data["error"] as? String ?? "The permanent move was not confirmed."])
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
    func sendServiceReportOnFinish(
        companyId: String,
        stopId: String,
        serviceReportBaseUrl: String = "https://dripdrop-poolapp.com"
    ) async throws -> ServiceReportSendResult {
        let payload: [String: Any]  = [
            "companyId": companyId,
            "serviceStopId": stopId,
            "serviceReportBaseUrl": serviceReportBaseUrl,
        ]
        
        let callable = functions.httpsCallable("sendServiceReportOnFinish")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][sendServiceReportOnFinish] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }
        print("    [FunctionsManager][sendServiceReportOnFinish] Sent Email \(json)")

        let status = json["status"] as? Int ?? 500
        let account = json["account"] as? String ?? ""
        if status >= 400 {
            let message: String
            if let error = json["error"] as? String {
                message = error
            } else if let error = json["error"] {
                message = "\(error)"
            } else {
                message = "Service report could not be sent."
            }

            throw NSError(
                domain: "SendServiceReport",
                code: status,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        return ServiceReportSendResult(
            status: status,
            account: account,
            category: json["category"] as? String ?? "",
            customerActionUrl: json["customerActionUrl"] as? String ?? "",
            claimAccountUrl: json["claimAccountUrl"] as? String ?? "",
            to: json["to"] as? String ?? "",
            intendedTo: json["intendedTo"] as? String ?? "",
            testMode: json["testMode"] as? Bool ?? false
        )

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
    @discardableResult
    func updateRecurringServiceStop(
        companyId: String,
        recurringServiceStop: RecurringServiceStop,
        syncRoute: Bool = true,
        destinationRouteId: String? = nil,
        futureServiceStopsStartAt: Date? = nil
    ) async throws -> [String: Any] {
        let recurringServiceStopData = try recurringServiceStop.asDictionary()
        let localFutureStart = futureServiceStopsStartAt ?? Calendar.current.startOfDay(for: Date())

        var payload: [String: Any]  = [
            "companyId":companyId,
            "recurringServiceStop":recurringServiceStopData,
            "syncRoute": syncRoute,
            "futureServiceStopsStartAt": ms(localFutureStart),
        ]
        if let destinationRouteId,
           !destinationRouteId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["destinationRouteId"] = destinationRouteId
        }

        return try await reviewedRecurringChange("updateRecurringServiceStop", payload: payload)
    }

    // MARK: updateRecurringServiceStopsRouteAssignment
    @discardableResult
    func updateRecurringServiceStopsRouteAssignment(
        companyId: String,
        recurringServiceStops: [RecurringServiceStop],
        targetDay: DaysOfWeek,
        targetTechId: String,
        targetTechName: String,
        destinationRouteId: String? = nil,
        futureServiceStopsStartAt: Date? = nil
    ) async throws -> [String: Any] {
        let localFutureStart = futureServiceStopsStartAt ?? Calendar.current.startOfDay(for: Date())
        var payload: [String: Any] = [
            "companyId": companyId,
            "recurringServiceStopIds": recurringServiceStops.map(\.id),
            "targetDay": targetDay.rawValue,
            "targetTech": [
                "userId": targetTechId,
                "userName": targetTechName
            ],
            "futureServiceStopsStartAt": ms(localFutureStart)
        ]

        if let destinationRouteId,
           !destinationRouteId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["destinationRouteId"] = destinationRouteId
        }

        return try await reviewedRecurringChange("updateRecurringServiceStopsRouteAssignment", payload: payload)
    }

    private func reviewedRecurringChange(_ name: String, payload: [String: Any]) async throws -> [String: Any] {
        while true {
            let preview = try await verifiedRecurringResponse(name, payload: payload.merging([
                "currentWeekReview": ["action": "preview"]
            ]) { _, review in review })
            if preview["reviewRequired"] as? Bool == false {
                return try await verifiedRecurringResponse(name, payload: payload)
            }
            do {
                return try await CurrentWeekRouteSheet.present(response: preview, save: { review in
                    try await self.verifiedRecurringResponse(name, payload: payload.merging([
                        "currentWeekReview": review
                    ]) { _, value in value })
                })
            } catch is CurrentWeekRouteSheet.RefreshReview {
                continue
            }
        }
    }

    private func verifiedRecurringResponse(_ name: String, payload: [String: Any]) async throws -> [String: Any] {
        let data = try await technicianWorkflow(name, payload: payload)
        let status = data["status"] as? Int
        guard data["success"] as? Bool != false, (status ?? 200) < 400 else {
            throw NSError(domain: "RecurringRouteChange", code: status ?? -1, userInfo: [
                NSLocalizedDescriptionKey: data["error"] as? String ?? "The schedule change was not confirmed."
            ])
        }
        return data
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

    // MARK: sendServiceAgreement
    func sendServiceAgreement(
        companyId: String,
        agreementId: String,
        primaryEmail: String,
        additionalEmails: [String] = [],
        includeInspectionReport: Bool = false,
        agreementBaseUrl: String = "https://dripdrop-poolapp.com"
    ) async throws -> ServiceAgreementSendResult {
        var payload: [String: Any] = [
            "companyId": companyId,
            "agreementId": agreementId,
            "agreementBaseUrl": agreementBaseUrl,
            "primaryEmail": primaryEmail,
            "additionalEmails": additionalEmails,
            "includeInspectionReport": includeInspectionReport
        ]

        if let idToken = try await auth.currentUser?.getIDToken() {
            payload["idToken"] = idToken
        }

        let callable = functions.httpsCallable("sendServiceAgreementEmail")
        let result = try await callable.call(payload)
        guard let json = result.data as? [String: Any] else {
            print("      [FunctionsManager][sendServiceAgreement] Error: Unable to read JSON from function response.")
            throw FireBaseRead.unableToRead
        }

        return ServiceAgreementSendResult(
            status: json["status"] as? Int ?? 500,
            message: json["message"] as? String ?? "",
            agreementUrl: json["agreementUrl"] as? String ?? "",
            to: json["to"] as? String ?? "",
            intendedTo: json["intendedTo"] as? String ?? "",
            additionalEmails: json["additionalEmails"] as? [String] ?? [],
            recipientEmails: json["recipientEmails"] as? [String] ?? [],
            sentCount: json["sentCount"] as? Int ?? 0,
            testMode: json["testMode"] as? Bool ?? false
        )
    }
}

private struct CurrentWeekRouteSheet: View {
    struct RefreshReview: Error {}

    struct Technician: Identifiable {
        let id: String
        let name: String
    }

    struct Visit: Identifiable {
        let id: String
        let date: String
        let technician: String
        let status: String
        let state: String

        var explanation: String {
            switch state {
            case "started": return "Work has started. This visit will stay as scheduled."
            case "coverage": return "Transfer the coverage or pay agreement separately."
            case "previousMove": return "This visit will keep its separately reviewed assignment."
            default: return "The recorded outcome will stay as shown."
            }
        }
    }

    struct Schedule: Identifiable {
        let id: String
        let property: String
        let upcoming: String
        let nextDates: [String]
        let conflict: String
        let visits: [Visit]
    }

    struct Choice: Equatable {
        var action = ""
        var date = ""
        var technician = ""
    }

    let previewId: String
    let week: String
    let dates: [String]
    let technicians: [Technician]
    let schedules: [Schedule]
    let save: ([String: Any]) async throws -> [String: Any]
    let finish: (Result<[String: Any], Error>) -> Void

    @State private var choices: [String: Choice] = [:]
    @State private var lastSubmitted: [String: Choice] = [:]
    @State private var requestId = UUID().uuidString
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var staleReview = false

    private var openVisits: [Visit] {
        schedules.flatMap(\.visits).filter { $0.state == "open" }
    }

    private var canSave: Bool {
        !staleReview && schedules.allSatisfy { $0.conflict.isEmpty } && openVisits.allSatisfy { visit in
            guard let choice = choices[visit.id] else { return false }
            return choice.action == "keep" || (choice.action == "move" && dates.contains(choice.date) && !choice.technician.isEmpty)
        }
    }

    private func binding(_ id: String, _ field: WritableKeyPath<Choice, String>) -> Binding<String> {
        Binding(get: { (choices[id] ?? Choice())[keyPath: field] }, set: { value in
            var choice = choices[id] ?? Choice()
            choice[keyPath: field] = value
            choices[id] = choice
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { Text(week) }
                ForEach(schedules) { schedule in
                    Section(schedule.property) {
                        Text(schedule.upcoming)
                        if !schedule.nextDates.isEmpty {
                            Text(schedule.nextDates.joined(separator: ", ")).font(.footnote)
                        }
                        if !schedule.conflict.isEmpty {
                            Text(schedule.conflict).foregroundStyle(.red)
                        } else if schedule.visits.isEmpty {
                            Text("No visit is due this week.")
                        }
                        ForEach(schedule.visits) { visit in
                            Text("\(visit.date) · \(visit.technician) · \(visit.status)")
                            if visit.state == "open" {
                                Picker("This visit", selection: binding(visit.id, \.action)) {
                                    Text("Choose an option").tag("")
                                    Text("Keep as scheduled").tag("keep")
                                    Text("Move this week").tag("move")
                                }
                                if choices[visit.id]?.action == "move" {
                                    Picker("Date", selection: binding(visit.id, \.date)) {
                                        Text("Select a date").tag("")
                                        ForEach(dates, id: \.self) { Text($0).tag($0) }
                                    }
                                    Picker("Technician", selection: binding(visit.id, \.technician)) {
                                        Text("Select a technician").tag("")
                                        ForEach(technicians) { Text($0.name).tag($0.id) }
                                    }
                                }
                            } else {
                                Text(visit.explanation).font(.footnote)
                            }
                        }
                    }
                }
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                        if staleReview {
                            Button("Refresh review") { finish(.failure(RefreshReview())) }
                        }
                    }
                }
            }
            .disabled(isSaving)
            .navigationTitle("This week’s stops")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { finish(.failure(CancellationError())) }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save change") {
                        Task { await submit() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    @MainActor private func submit() async {
        guard canSave, !isSaving else { return }
        isSaving = true
        errorMessage = ""
        if lastSubmitted != choices { requestId = UUID().uuidString }
        lastSubmitted = choices
        let selected: [[String: String]] = openVisits.compactMap { visit in
            guard let choice = choices[visit.id] else { return nil }
            if choice.action == "keep" { return ["stopId": visit.id, "action": "keep"] }
            return ["stopId": visit.id, "action": "move", "dateKey": choice.date, "techId": choice.technician]
        }
        do {
            let result = try await save(["action": "commit", "previewId": previewId, "requestId": requestId, "choices": selected])
            finish(.success(result))
        } catch {
            errorMessage = error.userFacingMessage
            staleReview = error.localizedDescription.localizedCaseInsensitiveContains("refresh the review")
            isSaving = false
        }
    }

    @MainActor static func present(
        response: [String: Any],
        save: @escaping ([String: Any]) async throws -> [String: Any]
    ) async throws -> [String: Any] {
        guard let id = response["previewId"] as? String, let today = response["today"] as? String,
              let start = response["weekStart"] as? String, let end = response["weekEnd"] as? String,
              let items = response["schedules"] as? [[String: Any]],
              let staff = response["technicians"] as? [[String: String]] else {
            throw FireBaseRead.unableToRead
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard let firstDate = formatter.date(from: today) else { throw FireBaseRead.unableToRead }
        let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDate) }
            .map { formatter.string(from: $0) }.filter { $0 <= end }
        let technicians = staff.compactMap { entry -> Technician? in
            guard let id = entry["id"], let name = entry["name"] else { return nil }
            return Technician(id: id, name: name)
        }
        let schedules = try items.map { schedule -> Schedule in
            guard let id = schedule["id"] as? String, let rows = schedule["visits"] as? [[String: String]] else {
                throw FireBaseRead.unableToRead
            }
            let visits = try rows.map { row -> Visit in
                guard let id = row["id"], let day = row["dateKey"], let state = row["state"] else { throw FireBaseRead.unableToRead }
                return Visit(id: id, date: day, technician: row["technician"] ?? "", status: row["status"] ?? "", state: state)
            }
            let property = [schedule["customer"] as? String, schedule["location"] as? String]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            let upcoming = [response["effectiveDate"] as? String, schedule["nextDay"] as? String, schedule["nextTech"] as? String]
                .compactMap { $0 }.joined(separator: " · ")
            return Schedule(id: id, property: property, upcoming: upcoming, nextDates: schedule["nextDates"] as? [String] ?? [],
                            conflict: schedule["conflict"] as? String ?? "", visits: visits)
        }
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive && $0.windows.contains(where: \.isKeyWindow) }
        guard var presenter = scene?.windows.first(where: \.isKeyWindow)?.rootViewController else {
            throw NSError(domain: "RecurringRouteChange", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "The schedule review couldn’t open. Try again from the route screen."
            ])
        }
        while let shown = presenter.presentedViewController { presenter = shown }
        return try await withCheckedThrowingContinuation { continuation in
            let sheet = CurrentWeekRouteSheet(previewId: id, week: "\(start) – \(end)", dates: dates,
                                             technicians: technicians, schedules: schedules, save: save) { outcome in
                presenter.dismiss(animated: true) { continuation.resume(with: outcome) }
            }
            let controller = UIHostingController(rootView: sheet)
            controller.isModalInPresentation = true
            presenter.present(controller, animated: true)
        }
    }
}
