//
//  Equipment+ProductionDataService+Extension.swift
//  DripDrop
//  EquipmentPart+ProductionDataService+Extension.swift
//  Created by Michael Espineli on 12/5/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage

struct Equipment:Identifiable,Codable,Equatable,Hashable{
    
    var id : String = "com_equ_" + UUID().uuidString
    var name: String
    var type: EquipmentCategory
    var customTypeName: String
    var typeId: String
    var make : String
    var makeId :String //For Universal Equipment Says Custom If Not Selected
    var model : String //
    var modelId :String //For Universal equipment. Says Custom if not selected
    var universalEquipmentId: String
    var manualPdfLink: String
    var dateInstalled : Date?
    var createdAt: Date?
    var status : EquipmentStatus
    var needsService : Bool
    var cleanFilterPressure: Int?
    var currentPressure: Int?

    var lastServiceDate : Date?
    var serviceFrequency : Int? //? Maybe number
    var serviceFrequencyEvery : EquipmentFrequency? //? Time Frequencies
    var nextServiceDate : Date?

    var notes : String
    var customerName : String
    var customerId : String

    var serviceLocationId : String
    var bodyOfWaterId : String
    var photoUrls:[DripDropStoredImage]?
    var isActive:Bool
    var dateUninstalled : Date?
    init(
        id: String,
        name :String,
        type :EquipmentCategory,
        customTypeName: String = "",
        typeId : String,
        make : String,
        makeId : String,
        model : String,
        modelId : String,
        universalEquipmentId: String = "",
        manualPdfLink: String = "",
        dateInstalled  : Date? = nil,
        createdAt: Date? = nil,
        status:EquipmentStatus,
        needsService:Bool,
        cleanFilterPressure : Int? = nil,
        currentPressure : Int? = nil,

        lastServiceDate : Date? = nil,
        serviceFrequency : Int? = nil,
        serviceFrequencyEvery : EquipmentFrequency? = nil,
        nextServiceDate : Date? = nil,
        notes : String,
        
        customerName : String,
        customerId : String,
        serviceLocationId  : String,
        bodyOfWaterId : String,
        photoUrls : [DripDropStoredImage]? = nil,
    
        isActive: Bool,
        dateUninstalled: Date? = nil
    ){
        self.id = id
        self.name = name

        self.type = type
        self.customTypeName = type == .other ? customTypeName : ""
        self.typeId = typeId
        self.make = make
        self.makeId = makeId
        self.model = model
        self.modelId = modelId
        self.universalEquipmentId = universalEquipmentId
        self.manualPdfLink = manualPdfLink
        self.dateInstalled = dateInstalled
        self.createdAt = createdAt
        self.status = status
        
        self.needsService = needsService
        self.cleanFilterPressure = cleanFilterPressure
        self.currentPressure = currentPressure
        self.lastServiceDate = lastServiceDate
        self.serviceFrequency = serviceFrequency
        self.serviceFrequencyEvery = serviceFrequencyEvery
        self.nextServiceDate = nextServiceDate
        self.notes = notes
        self.customerName = customerName
        self.customerId = customerId
        self.serviceLocationId = serviceLocationId
        self.bodyOfWaterId = bodyOfWaterId
        self.photoUrls = photoUrls
        
        self.isActive = isActive
        self.dateUninstalled = dateUninstalled
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"

            case type = "type"
            case customTypeName = "customTypeName"
            case typeId = "typeId"
            case make = "make"
            case makeId = "makeId"
            case model = "model"
            case modelId = "modelId"
            case universalEquipmentId = "universalEquipmentId"
            case manualPdfLink = "manualPdfLink"
            case dateInstalled = "dateInstalled"
            case createdAt = "createdAt"
            case status = "status"
            case needsService = "needsService"
            case cleanFilterPressure = "cleanFilterPressure"
            case currentPressure = "currentPressure"
            
            case lastServiceDate = "lastServiceDate"
            case serviceFrequency = "serviceFrequency"
            case serviceFrequencyEvery = "serviceFrequencyEvery"
            case nextServiceDate = "nextServiceDate"
            case notes = "notes"
            case customerName = "customerName"
            case customerId = "customerId"
            case serviceLocationId = "serviceLocationId"
            case bodyOfWaterId = "bodyOfWaterId"
            case photoUrls = "photoUrls"
            case isActive = "isActive"
            case dateUninstalled = "dateUninstalled"
        }

    private enum LegacyCodingKeys: String, CodingKey {
        case active
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)

        func decodeFlexibleInt(_ key: CodingKeys) -> Int? {
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return value
            }

            if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
                return Int(value)
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: key) {
                return Int(value)
            }

            return nil
        }

        func normalizeFrequencyUnit(_ value: String) -> EquipmentFrequency? {
            switch value {
            case EquipmentFrequency.daily.rawValue, "Days":
                return .daily
            case EquipmentFrequency.weekly.rawValue, "Weeks":
                return .weekly
            case EquipmentFrequency.monthly.rawValue, "Months":
                return .monthly
            case EquipmentFrequency.yearly.rawValue, "Years":
                return .yearly
            default:
                return EquipmentFrequency(rawValue: value)
            }
        }

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "com_equ_" + UUID().uuidString
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

        let typeRaw = try container.decodeIfPresent(String.self, forKey: .type) ?? EquipmentCategory.autoChlorinator.rawValue
        let storedCustomTypeName = try container.decodeIfPresent(String.self, forKey: .customTypeName) ?? ""
        if let decodedCategory = EquipmentCategory(rawValue: typeRaw) {
            self.type = decodedCategory
            self.customTypeName = decodedCategory == .other ? storedCustomTypeName : ""
        } else {
            self.type = .other
            self.customTypeName = typeRaw
        }

        self.typeId = try container.decodeIfPresent(String.self, forKey: .typeId) ?? ""
        self.make = try container.decodeIfPresent(String.self, forKey: .make) ?? ""
        self.makeId = try container.decodeIfPresent(String.self, forKey: .makeId) ?? ""
        self.model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        self.modelId = try container.decodeIfPresent(String.self, forKey: .modelId) ?? ""
        self.universalEquipmentId = try container.decodeIfPresent(String.self, forKey: .universalEquipmentId) ?? self.modelId
        self.manualPdfLink = try container.decodeIfPresent(String.self, forKey: .manualPdfLink) ?? ""
        self.dateInstalled = try container.decodeIfPresent(Date.self, forKey: .dateInstalled)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)

        let statusRaw = try container.decodeIfPresent(String.self, forKey: .status) ?? EquipmentStatus.operational.rawValue
        self.status = EquipmentStatus(rawValue: statusRaw) ?? .operational

        self.needsService = try container.decodeIfPresent(Bool.self, forKey: .needsService) ?? false
        self.cleanFilterPressure = decodeFlexibleInt(.cleanFilterPressure)
        self.currentPressure = decodeFlexibleInt(.currentPressure)
        self.lastServiceDate = try container.decodeIfPresent(Date.self, forKey: .lastServiceDate)

        let decodedServiceFrequency = decodeFlexibleInt(.serviceFrequency)
        let decodedLegacyFrequency = decodeFlexibleInt(.serviceFrequencyEvery)
        self.serviceFrequency = decodedServiceFrequency ?? decodedLegacyFrequency

        if let rawEvery = try container.decodeIfPresent(String.self, forKey: .serviceFrequencyEvery) {
            self.serviceFrequencyEvery = normalizeFrequencyUnit(rawEvery)
        } else if let rawLegacyEvery = try container.decodeIfPresent(String.self, forKey: .serviceFrequency) {
            self.serviceFrequencyEvery = normalizeFrequencyUnit(rawLegacyEvery)
        } else {
            self.serviceFrequencyEvery = nil
        }

        self.nextServiceDate = try container.decodeIfPresent(Date.self, forKey: .nextServiceDate)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.customerName = try container.decodeIfPresent(String.self, forKey: .customerName) ?? ""
        self.customerId = try container.decodeIfPresent(String.self, forKey: .customerId) ?? ""
        self.serviceLocationId = try container.decodeIfPresent(String.self, forKey: .serviceLocationId) ?? ""
        self.bodyOfWaterId = try container.decodeIfPresent(String.self, forKey: .bodyOfWaterId) ?? ""
        self.photoUrls = try container.decodeIfPresent([DripDropStoredImage].self, forKey: .photoUrls)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
            ?? legacyContainer.decodeIfPresent(Bool.self, forKey: .active)
            ?? true
        self.dateUninstalled = try container.decodeIfPresent(Date.self, forKey: .dateUninstalled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(typeStorageValue, forKey: .type)
        if !customTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try container.encode(customTypeName, forKey: .customTypeName)
        }
        try container.encode(typeId, forKey: .typeId)
        try container.encode(make, forKey: .make)
        try container.encode(makeId, forKey: .makeId)
        try container.encode(model, forKey: .model)
        try container.encode(modelId, forKey: .modelId)
        try container.encode(universalEquipmentId, forKey: .universalEquipmentId)
        try container.encode(manualPdfLink, forKey: .manualPdfLink)
        try container.encodeIfPresent(dateInstalled, forKey: .dateInstalled)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(status, forKey: .status)
        try container.encode(needsService, forKey: .needsService)
        try container.encodeIfPresent(cleanFilterPressure, forKey: .cleanFilterPressure)
        try container.encodeIfPresent(currentPressure, forKey: .currentPressure)
        try container.encodeIfPresent(lastServiceDate, forKey: .lastServiceDate)
        try container.encodeIfPresent(serviceFrequency, forKey: .serviceFrequency)
        try container.encodeIfPresent(serviceFrequencyEvery, forKey: .serviceFrequencyEvery)
        try container.encodeIfPresent(nextServiceDate, forKey: .nextServiceDate)
        try container.encode(notes, forKey: .notes)
        try container.encode(customerName, forKey: .customerName)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(serviceLocationId, forKey: .serviceLocationId)
        try container.encode(bodyOfWaterId, forKey: .bodyOfWaterId)
        try container.encodeIfPresent(photoUrls, forKey: .photoUrls)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(dateUninstalled, forKey: .dateUninstalled)
    }
}

extension Equipment {
    var typeDisplayName: String {
        let customName = customTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if type == .other, !customName.isEmpty {
            return customName
        }
        return type.rawValue
    }

    var typeStorageValue: String {
        typeDisplayName
    }

    var isFilterEquipment: Bool {
        type == .filter || typeDisplayName.localizedCaseInsensitiveContains("filter")
    }

    var dateForGeneratedParts: Date {
        dateInstalled ?? createdAt ?? Date()
    }

    var maintenanceDueDateForFollowUp: Date? {
        guard let lastServiceDate,
              let serviceFrequency,
              serviceFrequency > 0,
              let serviceFrequencyEvery else {
            return nextServiceDate
        }

        return getNextServiceDate(
            lastServiceDate: lastServiceDate,
            frequency: serviceFrequency,
            every: serviceFrequencyEvery
        ) ?? nextServiceDate
    }

    var currentlyNeedsMaintenanceFollowUp: Bool {
        guard needsService, let dueDate = maintenanceDueDateForFollowUp else {
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let followUpWindowEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let dueDay = calendar.startOfDay(for: dueDate)

        return dueDay <= followUpWindowEnd
    }
}

struct UniversalEquipmentSuggestionSyncFlags {
    let isCustomType: Bool
    let isCustomMake: Bool
    let isCustomModel: Bool
}

private let universalEquipmentSuggestionReconciledStatus = "Reconciled"

private func cleanUniversalSuggestionText(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func universalEquipmentSuggestionId(for equipmentId: String) -> String {
    "unv_equ_sug_\(equipmentId)"
}

private func catalogEquipmentId(for equipment: Equipment) -> String {
    let universalEquipmentId = cleanUniversalSuggestionText(equipment.universalEquipmentId)
    if !universalEquipmentId.isEmpty {
        return universalEquipmentId
    }
    return cleanUniversalSuggestionText(equipment.modelId)
}

private func universalEquipmentSuggestionFlags(for equipment: Equipment) -> UniversalEquipmentSuggestionSyncFlags {
    let type = cleanUniversalSuggestionText(equipment.typeStorageValue)
    let make = cleanUniversalSuggestionText(equipment.make)
    let model = cleanUniversalSuggestionText(equipment.model)

    return UniversalEquipmentSuggestionSyncFlags(
        isCustomType: !type.isEmpty && cleanUniversalSuggestionText(equipment.typeId).isEmpty,
        isCustomMake: !make.isEmpty && cleanUniversalSuggestionText(equipment.makeId).isEmpty,
        isCustomModel: !model.isEmpty && catalogEquipmentId(for: equipment).isEmpty
    )
}

private func hasCustomUniversalEquipmentSuggestionValue(_ flags: UniversalEquipmentSuggestionSyncFlags) -> Bool {
    flags.isCustomType || flags.isCustomMake || flags.isCustomModel
}

func syncUniversalEquipmentSuggestion(
    db: Firestore,
    companyId: String,
    equipment: Equipment,
    source: String
) async throws {
    let flags = universalEquipmentSuggestionFlags(for: equipment)

    if hasCustomUniversalEquipmentSuggestionValue(flags) {
        try await queueUniversalEquipmentSuggestion(
            db: db,
            companyId: companyId,
            equipment: equipment,
            source: source,
            flags: flags
        )
        return
    }

    if !catalogEquipmentId(for: equipment).isEmpty {
        try await markUniversalEquipmentSuggestionReconciled(
            db: db,
            equipment: equipment
        )
    }
}

private func queueUniversalEquipmentSuggestion(
    db: Firestore,
    companyId: String,
    equipment: Equipment,
    source: String,
    flags: UniversalEquipmentSuggestionSyncFlags
) async throws {
    let equipmentId = cleanUniversalSuggestionText(equipment.id)
    guard !companyId.isEmpty, !equipmentId.isEmpty else { return }

    let suggestionId = universalEquipmentSuggestionId(for: equipmentId)
    let suggestionRef = db.collection("universalEquipmentSuggestions").document(suggestionId)
    let currentUser = Auth.auth().currentUser

    var payload: [String: Any] = [
        "id": suggestionId,
        "status": "New",
        "source": source,
        "companyId": companyId,
        "companyName": "",
        "createdByUserId": currentUser?.uid ?? "",
        "createdByUserEmail": currentUser?.email ?? "",
        "updatedAt": FieldValue.serverTimestamp(),
        "equipmentId": equipmentId,
        "equipmentName": cleanUniversalSuggestionText(equipment.name),
        "customerId": cleanUniversalSuggestionText(equipment.customerId),
        "customerName": cleanUniversalSuggestionText(equipment.customerName),
        "serviceLocationId": cleanUniversalSuggestionText(equipment.serviceLocationId),
        "bodyOfWaterId": cleanUniversalSuggestionText(equipment.bodyOfWaterId),
        "type": cleanUniversalSuggestionText(equipment.typeStorageValue),
        "typeId": cleanUniversalSuggestionText(equipment.typeId),
        "make": cleanUniversalSuggestionText(equipment.make),
        "makeId": cleanUniversalSuggestionText(equipment.makeId),
        "model": cleanUniversalSuggestionText(equipment.model),
        "modelId": catalogEquipmentId(for: equipment),
        "customCategoryRequested": flags.isCustomType,
        "customMakeRequested": flags.isCustomMake,
        "customModelRequested": flags.isCustomModel,
        "notes": cleanUniversalSuggestionText(equipment.notes),
    ]

    payload["createdAt"] = FieldValue.serverTimestamp()
    payload["createdAtMillis"] = Int(Date().timeIntervalSince1970 * 1000)

    try await suggestionRef.setData(payload, merge: true)
}

private func markUniversalEquipmentSuggestionReconciled(
    db: Firestore,
    equipment: Equipment
) async throws {
    let equipmentId = cleanUniversalSuggestionText(equipment.id)
    let universalEquipmentId = catalogEquipmentId(for: equipment)
    guard !equipmentId.isEmpty, !universalEquipmentId.isEmpty else { return }

    let suggestionRef = db.collection("universalEquipmentSuggestions").document(universalEquipmentSuggestionId(for: equipmentId))
    let currentUser = Auth.auth().currentUser
    try? await suggestionRef.updateData([
        "status": universalEquipmentSuggestionReconciledStatus,
        "reconciledAt": FieldValue.serverTimestamp(),
        "reconciledByUserId": currentUser?.uid ?? "",
        "reconciledByEmail": currentUser?.email ?? "",
        "reconciledEquipmentId": equipmentId,
        "reconciledUniversalEquipmentId": universalEquipmentId,
        "reconciledType": cleanUniversalSuggestionText(equipment.typeStorageValue),
        "reconciledTypeId": cleanUniversalSuggestionText(equipment.typeId),
        "reconciledMake": cleanUniversalSuggestionText(equipment.make),
        "reconciledMakeId": cleanUniversalSuggestionText(equipment.makeId),
        "reconciledModel": cleanUniversalSuggestionText(equipment.model),
        "reconciledModelId": universalEquipmentId,
        "reconciledManualPdfLink": cleanUniversalSuggestionText(equipment.manualPdfLink),
        "updatedAt": FieldValue.serverTimestamp(),
    ])
}

private func syncUniversalEquipmentSuggestionInBackground(
    db: Firestore,
    companyId: String,
    equipmentRef: DocumentReference,
    source: String,
    mutate: @escaping (inout Equipment) -> Void
) {
    Task {
        do {
            var equipment = try await equipmentRef.getDocument(as: Equipment.self)
            mutate(&equipment)
            try await syncUniversalEquipmentSuggestion(
                db: db,
                companyId: companyId,
                equipment: equipment,
                source: source
            )
        } catch {
            print("Error syncing universal equipment suggestion: \(error)")
        }
    }
}
// MARK: - Maybe update
/*struct EquipmentServiceHistory: Identifiable, Codable, Equatable, Hashable {
 var id: String = "com_equ_sh_" + UUID().uuidString
 var name: String
 var type: EquipmentServiceType
 var date: Date
 var description: String
 var performedBy: ServicePerformaceType
 var addedBy: ServiceRecordType
 var techId: String
 var techName: String
 var jobId: String
 var partIds: [String]

 init(
     id: String,
     name: String,
     type: EquipmentServiceType,
     date: Date,
     description: String,
     performedBy: ServicePerformaceType,
     addedBy: ServiceRecordType,
     techId: String,
     techName: String,
     jobId: String,
     partIds: [String]
 ) {
     self.id = id
     self.name = name
     self.type = type
     self.date = date
     self.description = description
     self.performedBy = performedBy
     self.addedBy = addedBy
     self.techId = techId
     self.techName = techName
     self.jobId = jobId
     self.partIds = partIds
 }

 enum CodingKeys: String, CodingKey {
     case id
     case name
     case type
     case date
     case description
     case performedBy
     case addedBy
     case techId
     case techName
     case jobId
     case partIds
 }

 init(from decoder: Decoder) throws {
     let container = try decoder.container(keyedBy: CodingKeys.self)

     self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "com_equ_sh_" + UUID().uuidString
     self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

     let typeRaw = try container.decodeIfPresent(String.self, forKey: .type) ?? "Maintenance"
     self.type = EquipmentServiceType(rawValue: typeRaw) ?? .maintenance

     self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
     self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""

     let performedByRaw = try container.decodeIfPresent(String.self, forKey: .performedBy) ?? ""
     self.performedBy = ServicePerformaceType(rawValue: performedByRaw) ?? .unknown

     let addedByRaw = try container.decodeIfPresent(String.self, forKey: .addedBy) ?? ""
     self.addedBy = ServiceRecordType(rawValue: addedByRaw) ?? .unknown

     self.techId = try container.decodeIfPresent(String.self, forKey: .techId) ?? ""
     self.techName = try container.decodeIfPresent(String.self, forKey: .techName) ?? ""
     self.jobId = try container.decodeIfPresent(String.self, forKey: .jobId) ?? ""
     self.partIds = try container.decodeIfPresent([String].self, forKey: .partIds) ?? []
 }
}*/
struct EquipmentServiceHistory:Identifiable,Codable,Equatable,Hashable{
    
    var id : String = "com_equ_sh_" + UUID().uuidString
    var name: String
    var type: EquipmentServiceType
    var date: Date
    var description: String
    var performedBy: ServicePerformaceType
    var addedBy: ServiceRecordType
    var techId: String
    var techName: String
    var jobId: String
    var partIds: [String]
    init(
        id: String,
        name : String,
        type : EquipmentServiceType,
        date : Date,
        description : String,
        performedBy : ServicePerformaceType,
        addedBy : ServiceRecordType,
        techId:String,
        techName:String,
        jobId : String,
        partIds : [String],
    ){
        self.id = id
        self.name = name
        self.type = type
        self.date = date
        self.description = description
        self.performedBy = performedBy
        self.addedBy = addedBy
        self.techId = techId
        self.techName = techName
        self.jobId = jobId
        self.partIds = partIds
    }
    enum CodingKeys:String, CodingKey {
        case id = "id"
        case name = "name"
        case type = "type"
        case date = "date"
        case description = "description"
        case performedBy = "performedBy"
        case addedBy = "addedBy"
        case techId = "techId"
        case techName = "techName"
        case jobId = "jobId"
        case partIds = "partIds"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "com_equ_sh_" + UUID().uuidString
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

        let typeRaw = try container.decodeIfPresent(String.self, forKey: .type) ?? EquipmentServiceType.maintenance.rawValue
        self.type = EquipmentServiceType(rawValue: typeRaw) ?? .maintenance

        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""

        let performedByRaw = try container.decodeIfPresent(String.self, forKey: .performedBy) ?? ServicePerformaceType.unknown.rawValue
        self.performedBy = ServicePerformaceType(rawValue: performedByRaw) ?? .unknown

        let addedByRaw = try container.decodeIfPresent(String.self, forKey: .addedBy) ?? ServiceRecordType.manual.rawValue
        self.addedBy = ServiceRecordType(rawValue: addedByRaw) ?? .manual

        self.techId = try container.decodeIfPresent(String.self, forKey: .techId) ?? ""
        self.techName = try container.decodeIfPresent(String.self, forKey: .techName) ?? ""
        self.jobId = try container.decodeIfPresent(String.self, forKey: .jobId) ?? ""
        self.partIds = try container.decodeIfPresent([String].self, forKey: .partIds) ?? []
    }
}
struct EquipmentScheduledWork: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var type: EquipmentServiceType
    var serviceDate: Date?
    var techId: String
    var techName: String

    var serviceStopId: String
    var serviceStopInternalId: String

    var jobId: String
    var jobInternalId: String

    var status: EquipmentScheduledWorkStatus
    var description: String
    var dateCreated: Date
    var dateCompleted: Date?

    init(
        id: String = "com_equ_sw_" + UUID().uuidString,
        name: String,
        type: EquipmentServiceType,
        serviceDate: Date? = nil,
        techId: String = "",
        techName: String = "",
        serviceStopId: String = "",
        serviceStopInternalId: String = "",
        jobId: String = "",
        jobInternalId: String = "",
        status: EquipmentScheduledWorkStatus,
        description: String = "",
        dateCreated: Date = Date(),
        dateCompleted: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.serviceDate = serviceDate
        self.techId = techId
        self.techName = techName
        self.serviceStopId = serviceStopId
        self.serviceStopInternalId = serviceStopInternalId
        self.jobId = jobId
        self.jobInternalId = jobInternalId
        self.status = status
        self.description = description
        self.dateCreated = dateCreated
        self.dateCompleted = dateCompleted
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case serviceDate
        case techId
        case techName
        case serviceStopId
        case serviceStopInternalId
        case jobId
        case jobInternalId
        case status
        case description
        case dateCreated
        case dateCompleted
    }
}
enum EquipmentScheduledWorkStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    var id: String { rawValue }

    case draft = "Draft"
    case estimatePending = "Estimate Pending"
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case canceled = "Canceled"
}
extension ProductionDataService {
 
    func EquipmentImageRefrence(companyId:String,id:String)->StorageReference {
        storage
            .child("companies")
            .child(companyId)
            .child("equipment")
            .child(id)
    }
     func equipmentCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/equipment")
    }
    func equipmentDoc(companyId:String,equipmentId:String)-> DocumentReference{
       equipmentCollection(companyId: companyId).document(equipmentId)
   }
    func equipmentServiceHistoryCollection(companyId:String,equipmentId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/equipment/\(equipmentId)/serviceHistory")
   }
    func equipmentServiceHistoryDoc(companyId:String,equipmentId:String,historyId:String)-> DocumentReference{
        equipmentServiceHistoryCollection(companyId: companyId, equipmentId:equipmentId).document(historyId)
  }
    //CREATE
    func uploadEquipment(companyId:String,equipment:Equipment) async throws {
        var equipmentToSave = equipment
        equipmentToSave.createdAt = equipmentToSave.createdAt ?? Date()
        try equipmentCollection(companyId: companyId).document(equipmentToSave.id).setData(from: equipmentToSave, merge: false)
        do {
            try await syncUniversalEquipmentSuggestion(
                db: db,
                companyId: companyId,
                equipment: equipmentToSave,
                source: "iosEquipmentCreate"
            )
        } catch {
            print("Error creating universal equipment suggestion: \(error)")
        }
    }
    func uploadEquipmentHistory(companyId:String,equipmentId:String,history:EquipmentServiceHistory) async throws {
        try equipmentServiceHistoryCollection(companyId: companyId,equipmentId:equipmentId).document(history.id).setData(from:history, merge: false)
    }
    func uploadEquipmentImage(companyId: String,equipmentId:String, image: DripDropImage) async throws ->(path:String, name:String){
        guard let data = image.image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
        let returnedMetaData = try await EquipmentImageRefrence(companyId: companyId, id: equipmentId).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        let urlString = try await Storage.storage().reference(withPath: returnedPath).downloadURL().absoluteString
        return (urlString,returnedName)
    }
    //READ
    func getAllEquipmentCount(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (equipmentList:[Equipment],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            print(" - - - Has Old Doc")
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)
            
        } else {
            print(" - - - Does Not have First Doc")
            
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)
        }
    }
    func getEquipmentSnapShot(companyId:String) async throws -> [Equipment] {
        return try await equipmentCollection(companyId: companyId)
            .limit(to: 10)
            .getDocuments(as:Equipment.self)
    }
    func getAllEquipment(companyId:String) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .getDocuments(as:Equipment.self)
    }
    
    func getAllEquipmentServiceHistory(companyId:String, equipmentId:String) async throws -> [EquipmentServiceHistory] {
        
        return try await equipmentServiceHistoryCollection(companyId: companyId, equipmentId: equipmentId)
            .getDocuments(as:EquipmentServiceHistory.self)
    }
    func getEquipmentByBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .whereField(Equipment.CodingKeys.bodyOfWaterId.rawValue, isEqualTo: bodyOfWater.id)
            .getDocuments(as:Equipment.self)
    }
    //UPDATE
    func updateEquipmentName(companyId:String,equipmentId:String,name:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.name.stringValue:name
        ])
    }
    func updateEquipmentCategory(companyId:String,equipmentId:String,category:EquipmentCategory) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.type.stringValue:category.rawValue
        ])
        syncUniversalEquipmentSuggestionInBackground(
            db: db,
            companyId: companyId,
            equipmentRef: equipmentRef,
            source: "iosEquipmentCategoryEdit"
        ) { equipment in
            equipment.type = category
        }
    }

    func updateEquipmentMake(companyId:String,equipmentId:String,make:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.make.stringValue:make
        ])
        syncUniversalEquipmentSuggestionInBackground(
            db: db,
            companyId: companyId,
            equipmentRef: equipmentRef,
            source: "iosEquipmentMakeEdit"
        ) { equipment in
            equipment.make = make
            equipment.makeId = ""
        }
    }
    func updateEquipmentModel(companyId:String,equipmentId:String,model:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.model.stringValue:model
        ])
        syncUniversalEquipmentSuggestionInBackground(
            db: db,
            companyId: companyId,
            equipmentRef: equipmentRef,
            source: "iosEquipmentModelEdit"
        ) { equipment in
            equipment.model = model
            equipment.modelId = ""
            equipment.universalEquipmentId = ""
        }
    }
    func updateEquipmentCatalogDetails(
        companyId:String,
        equipmentId:String,
        category:EquipmentCategory,
        typeId:String,
        make:String,
        makeId:String,
        model:String,
        modelId:String,
        universalEquipmentId:String,
        manualPdfLink:String
    ) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.type.stringValue: category.rawValue,
            Equipment.CodingKeys.typeId.stringValue: typeId,
            Equipment.CodingKeys.make.stringValue: make,
            Equipment.CodingKeys.makeId.stringValue: makeId,
            Equipment.CodingKeys.model.stringValue: model,
            Equipment.CodingKeys.modelId.stringValue: modelId,
            Equipment.CodingKeys.universalEquipmentId.stringValue: universalEquipmentId,
            Equipment.CodingKeys.manualPdfLink.stringValue: manualPdfLink
        ])
        syncUniversalEquipmentSuggestionInBackground(
            db: db,
            companyId: companyId,
            equipmentRef: equipmentRef,
            source: "iosEquipmentCatalogEdit"
        ) { equipment in
            equipment.type = category
            equipment.typeId = typeId
            equipment.make = make
            equipment.makeId = makeId
            equipment.model = model
            equipment.modelId = modelId
            equipment.universalEquipmentId = universalEquipmentId
            equipment.manualPdfLink = manualPdfLink
        }
    }
    func updateEquipmentDateInstalled(companyId:String,equipmentId:String,dateInstalled:Date?) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        let dateInstalledValue: Any = dateInstalled.map { $0 as Any } ?? FieldValue.delete()
        equipmentRef.updateData([
            Equipment.CodingKeys.dateInstalled.stringValue: dateInstalledValue
        ])
    }
    func updateEquipmentCreatedAt(companyId:String,equipmentId:String,createdAt:Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.createdAt.stringValue: createdAt
        ])
    }
    func updateEquipmentStatus(companyId:String,equipmentId:String,status:EquipmentStatus) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.status.stringValue:status.rawValue
        ])
    }
    func updateEquipmentCleanFilterPressure(companyId:String,equipmentId:String,cleanFilterPressure:Int) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.cleanFilterPressure.stringValue:cleanFilterPressure
        ])
    }
    func updateEquipmentCurrentPressure(companyId:String,equipmentId:String,currentPressure:Int) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.currentPressure.stringValue:currentPressure
        ])
    }
    func updateEquipmentCleanLastServiceDate(companyId:String,equipmentId:String,lastServiceDate:Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.lastServiceDate.stringValue:lastServiceDate
        ])
    }
    func updateEquipmentServiceFrequency(companyId:String,equipmentId:String,serviceFrequency:Int) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.serviceFrequency.stringValue:serviceFrequency
        ])
    }
    func updateEquipmentServiceFrequencyEvery(companyId:String,equipmentId:String,serviceFrequencyEvery:EquipmentFrequency) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.serviceFrequencyEvery.stringValue:serviceFrequencyEvery.rawValue
        ])
    }
    func updateEquipmentNextServiceDate(companyId: String, equipmentId: String, nextServiceDate: Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.nextServiceDate.stringValue:nextServiceDate
        ])
    }
    func updateEquipmentNotes(companyId:String,equipmentId:String,notes:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.notes.stringValue:notes
        ])
    }
    func updateEquipmentIsActive(companyId:String,equipmentId:String,isActive:Bool) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.isActive.stringValue:isActive
        ])
    }
    func updateEquipmentDateUninstalled(companyId:String,equipmentId:String,dateUninstalled:Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.dateUninstalled.stringValue:dateUninstalled
        ])
    }
    func updateEquipmentPhotoUrls(companyId:String,equipmentId:String,image:DripDropStoredImage) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.photoUrls.rawValue: FieldValue.arrayUnion([
                [
                "id":image.id,
                "description":image.description,
                "imageURL":image.imageURL
                ]
            ])
        ])
    }
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws {
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: true)
        do {
            try await syncUniversalEquipmentSuggestion(
                db: db,
                companyId: companyId,
                equipment: equipment,
                source: "iosEquipmentCustomerEdit"
            )
        } catch {
            print("Error syncing universal equipment suggestion: \(error)")
        }
        
    }
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        let createdAt = equipment.createdAt ?? Date()
        let dateInstalledValue: Any = equipment.dateInstalled.map { $0 as Any } ?? FieldValue.delete()
        let cleanFilterPressureValue: Any = equipment.cleanFilterPressure.map { $0 as Any } ?? FieldValue.delete()
        let currentPressureValue: Any = equipment.currentPressure.map { $0 as Any } ?? FieldValue.delete()
        let lastServiceDateValue: Any = equipment.needsService ? (equipment.lastServiceDate.map { $0 as Any } ?? FieldValue.delete()) : FieldValue.delete()
        let serviceFrequencyValue: Any = equipment.needsService ? (equipment.serviceFrequency.map { $0 as Any } ?? FieldValue.delete()) : FieldValue.delete()
        let serviceFrequencyEveryValue: Any = equipment.needsService ? (equipment.serviceFrequencyEvery.map { $0.rawValue as Any } ?? FieldValue.delete()) : FieldValue.delete()
        let nextServiceDateValue: Any = equipment.needsService ? (equipment.maintenanceDueDateForFollowUp.map { $0 as Any } ?? FieldValue.delete()) : FieldValue.delete()
        try await equipmentRef.updateData([
            Equipment.CodingKeys.name.stringValue:equipment.name,
            Equipment.CodingKeys.type.stringValue:equipment.typeStorageValue,
            Equipment.CodingKeys.typeId.stringValue:equipment.typeId,
            Equipment.CodingKeys.make.stringValue:equipment.make,
            Equipment.CodingKeys.makeId.stringValue:equipment.makeId,
            Equipment.CodingKeys.model.stringValue:equipment.model,
            Equipment.CodingKeys.modelId.stringValue:equipment.modelId,
            Equipment.CodingKeys.universalEquipmentId.stringValue:equipment.universalEquipmentId,
            Equipment.CodingKeys.manualPdfLink.stringValue:equipment.manualPdfLink,
            Equipment.CodingKeys.dateInstalled.stringValue: dateInstalledValue,
            Equipment.CodingKeys.createdAt.stringValue: createdAt,
            Equipment.CodingKeys.status.stringValue:equipment.status.rawValue,
            Equipment.CodingKeys.needsService.stringValue:equipment.needsService,
            Equipment.CodingKeys.cleanFilterPressure.stringValue:cleanFilterPressureValue,
            Equipment.CodingKeys.currentPressure.stringValue:currentPressureValue,
            Equipment.CodingKeys.lastServiceDate.stringValue:lastServiceDateValue,
            Equipment.CodingKeys.serviceFrequency.stringValue:serviceFrequencyValue,
            Equipment.CodingKeys.serviceFrequencyEvery.stringValue:serviceFrequencyEveryValue,
            Equipment.CodingKeys.nextServiceDate.stringValue:nextServiceDateValue,
            Equipment.CodingKeys.notes.stringValue:equipment.notes,
            Equipment.CodingKeys.customerName.stringValue:equipment.customerName,
            Equipment.CodingKeys.customerId.stringValue:equipment.customerId,
            Equipment.CodingKeys.serviceLocationId.stringValue:equipment.serviceLocationId,
            Equipment.CodingKeys.bodyOfWaterId.stringValue:equipment.bodyOfWaterId,
        ])
        do {
            try await syncUniversalEquipmentSuggestion(
                db: db,
                companyId: companyId,
                equipment: equipment,
                source: "iosEquipmentEdit"
            )
        } catch {
            print("Error syncing universal equipment suggestion: \(error)")
        }
    }
    //DELETE
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        let subcollections = [
            "parts",
            "serviceHistory",
            "scheduledWork",
            "equipmentMeasurements",
            "equipmentMeasurments"
        ]
        var batch = db.batch()
        var writeCount = 0

        func commitIfNeeded() async throws {
            guard writeCount >= 450 else { return }
            try await batch.commit()
            batch = db.batch()
            writeCount = 0
        }

        func queueDelete(_ reference: DocumentReference) async throws {
            batch.deleteDocument(reference)
            writeCount += 1
            try await commitIfNeeded()
        }

        for collectionName in subcollections {
            let snapshot = try await equipmentRef.collection(collectionName).getDocuments()
            for document in snapshot.documents {
                try await queueDelete(document.reference)
            }
        }

        try await queueDelete(equipmentRef)

        if writeCount > 0 {
            try await batch.commit()
        }
    }
}
