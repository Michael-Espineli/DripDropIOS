//
//  WorkOffer.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import Foundation

struct WorkOffer: Identifiable, Codable, Hashable {
    var id: String

    var companyId: String

    // Parent job
    var jobId: String
    var jobInternalId: String
    var jobName: String

    // Optional scheduled stop connection
    var serviceStopId: String
    var serviceStopInternalId: String

    // Offer info
    var offerType: WorkOfferType
    var status: WorkOfferStatus
    var title: String
    var description: String

    // Direct offer receiver
    var offeredToUserId: String
    var offeredToUserName: String
    var offeredToWorkerType: WorkerTypeEnum

    // Board posting
    var postedToBoard: Bool
    var boardVisibility: WorkOfferBoardVisibility
    var boardPostId: String
    var boardIds: [String]?
    var boardNames: [String]?
    var boardName: String?
    var boardMemberUserIds: [String]?

    // Scope
    var jobTaskIds: [String]
    var serviceStopTaskIds: [String]

    // Customer / location snapshot
    var customerId: String
    var customerName: String
    var serviceLocationId: String
    var serviceLocationName: String
    var address: Address?

    // Planned schedule
    var proposedStartDate: Date?
    var proposedEndDate: Date?
    var completionDeadlineAt: Date?
    var timelineNotes: String?
    var estimatedMinutes: Int
    var allowsTechnicianSelfScheduling: Bool?
    
    // Pay snapshot / agreement
    var paySource: WorkOfferPaySource
    var offeredAmountCents: Int
    var estimatedLaborCents: Int

    // Audit
    var createdAt: Date
    var createdByUserId: String
    var createdByUserName: String

    var sentAt: Date?
    var postedAt: Date?
    var viewedAt: Date?
    var acceptedAt: Date?
    var rejectedAt: Date?
    var cancelledAt: Date?
    var completedAt: Date?

    var acceptedByUserId: String
    var acceptedByUserName: String

    var rejectionReason: String
    var adminNotes: String
    var workerNotes: String

    // Future-proofing
    var sourceLaborContractId: String
    var externalCompanyId: String
    var externalCompanyName: String
    
    //Service stop Type
    var serviceStopTypeId: String?
    var serviceStopTypeName: String?
    var serviceStopTypeImage: String?
    var serviceStopTypeUseCaseRawValue: String?
    
    var estimatedPayLines: [WorkOfferPayEstimateLine]?
    var estimatedPayTotalCents: Int?
    var estimatedPayNotes: String?

    var schemaVersion: Int? = nil
    var revision: Int? = nil
    var workPurpose: String? = nil
    var scopeSnapshot: WorkOfferScope? = nil
    var claims: [WorkOfferClaim]? = nil
    var acceptedTerms: WorkOfferTerms? = nil
    var incentive: WorkOfferIncentive? = nil
    var routeId: String? = nil
    var routeSource: String? = nil
    var routeName: String? = nil
    var routeDate: Date? = nil
    var routeTechId: String? = nil
    var routeServiceStopIds: [String]? = nil
    var remainingStopIds: [String]? = nil
    var routeSplitAllowed: Bool? = nil
    var routeOfferMode: String? = nil
    var workOfferCategory: String? = nil
    var originalTechnicianId: String? = nil
    var coverageReason: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, companyId, jobId, jobInternalId, jobName, serviceStopId, serviceStopInternalId, offerType, status, title, description, offeredToUserId, offeredToUserName, offeredToWorkerType, postedToBoard, boardVisibility, boardPostId, boardIds, boardNames, boardName, boardMemberUserIds, jobTaskIds, serviceStopTaskIds, customerId, customerName, serviceLocationId, serviceLocationName, address, proposedStartDate, proposedEndDate, completionDeadlineAt, timelineNotes, estimatedMinutes, allowsTechnicianSelfScheduling, paySource, offeredAmountCents, estimatedLaborCents, createdAt, createdByUserId, createdByUserName, sentAt, postedAt, viewedAt, acceptedAt, rejectedAt, cancelledAt, completedAt, acceptedByUserId, acceptedByUserName, rejectionReason, adminNotes, workerNotes, sourceLaborContractId, externalCompanyId, externalCompanyName, serviceStopTypeId, serviceStopTypeName, serviceStopTypeImage, serviceStopTypeUseCaseRawValue, estimatedPayLines, estimatedPayTotalCents, estimatedPayNotes, schemaVersion, revision, workPurpose, scopeSnapshot, claims, acceptedTerms, incentive, routeId, routeSource, routeName, routeDate, routeTechId, routeServiceStopIds, remainingStopIds, routeSplitAllowed, routeOfferMode, workOfferCategory, originalTechnicianId, coverageReason
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? ""
        companyId = (try? c.decodeIfPresent(String.self, forKey: .companyId)) ?? ""
        jobId = (try? c.decodeIfPresent(String.self, forKey: .jobId)) ?? ""
        jobInternalId = (try? c.decodeIfPresent(String.self, forKey: .jobInternalId)) ?? ""
        jobName = (try? c.decodeIfPresent(String.self, forKey: .jobName)) ?? ""
        serviceStopId = (try? c.decodeIfPresent(String.self, forKey: .serviceStopId)) ?? ""
        serviceStopInternalId = (try? c.decodeIfPresent(String.self, forKey: .serviceStopInternalId)) ?? ""
        offerType = (try? c.decodeIfPresent(WorkOfferType.self, forKey: .offerType)) ?? .directUser
        status = (try? c.decodeIfPresent(WorkOfferStatus.self, forKey: .status)) ?? .draft
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
        description = (try? c.decodeIfPresent(String.self, forKey: .description)) ?? ""
        offeredToUserId = (try? c.decodeIfPresent(String.self, forKey: .offeredToUserId)) ?? ""
        offeredToUserName = (try? c.decodeIfPresent(String.self, forKey: .offeredToUserName)) ?? ""
        offeredToWorkerType = (try? c.decodeIfPresent(WorkerTypeEnum.self, forKey: .offeredToWorkerType)) ?? .notAssigned
        postedToBoard = (try? c.decodeIfPresent(Bool.self, forKey: .postedToBoard)) ?? false
        boardVisibility = (try? c.decodeIfPresent(WorkOfferBoardVisibility.self, forKey: .boardVisibility)) ?? .contractorsOnly
        boardPostId = (try? c.decodeIfPresent(String.self, forKey: .boardPostId)) ?? ""
        boardIds = try c.decodeIfPresent([String].self, forKey: .boardIds)
        boardNames = try c.decodeIfPresent([String].self, forKey: .boardNames)
        boardName = try c.decodeIfPresent(String.self, forKey: .boardName)
        boardMemberUserIds = try c.decodeIfPresent([String].self, forKey: .boardMemberUserIds)
        jobTaskIds = (try? c.decodeIfPresent([String].self, forKey: .jobTaskIds)) ?? []
        serviceStopTaskIds = (try? c.decodeIfPresent([String].self, forKey: .serviceStopTaskIds)) ?? []
        customerId = (try? c.decodeIfPresent(String.self, forKey: .customerId)) ?? ""
        customerName = (try? c.decodeIfPresent(String.self, forKey: .customerName)) ?? ""
        serviceLocationId = (try? c.decodeIfPresent(String.self, forKey: .serviceLocationId)) ?? ""
        serviceLocationName = (try? c.decodeIfPresent(String.self, forKey: .serviceLocationName)) ?? ""
        address = try c.decodeIfPresent(Address.self, forKey: .address)
        proposedStartDate = try c.decodeIfPresent(Date.self, forKey: .proposedStartDate)
        proposedEndDate = try c.decodeIfPresent(Date.self, forKey: .proposedEndDate)
        completionDeadlineAt = try c.decodeIfPresent(Date.self, forKey: .completionDeadlineAt)
        timelineNotes = try c.decodeIfPresent(String.self, forKey: .timelineNotes)
        estimatedMinutes = (try? c.decodeIfPresent(Int.self, forKey: .estimatedMinutes)) ?? 0
        allowsTechnicianSelfScheduling = try c.decodeIfPresent(Bool.self, forKey: .allowsTechnicianSelfScheduling)
        paySource = (try? c.decodeIfPresent(WorkOfferPaySource.self, forKey: .paySource)) ?? .technicianRate
        offeredAmountCents = (try? c.decodeIfPresent(Int.self, forKey: .offeredAmountCents)) ?? 0
        estimatedLaborCents = (try? c.decodeIfPresent(Int.self, forKey: .estimatedLaborCents)) ?? 0
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date(timeIntervalSince1970: 0)
        createdByUserId = (try? c.decodeIfPresent(String.self, forKey: .createdByUserId)) ?? ""
        createdByUserName = (try? c.decodeIfPresent(String.self, forKey: .createdByUserName)) ?? ""
        sentAt = try c.decodeIfPresent(Date.self, forKey: .sentAt)
        postedAt = try c.decodeIfPresent(Date.self, forKey: .postedAt)
        viewedAt = try c.decodeIfPresent(Date.self, forKey: .viewedAt)
        acceptedAt = try c.decodeIfPresent(Date.self, forKey: .acceptedAt)
        rejectedAt = try c.decodeIfPresent(Date.self, forKey: .rejectedAt)
        cancelledAt = try c.decodeIfPresent(Date.self, forKey: .cancelledAt)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        acceptedByUserId = (try? c.decodeIfPresent(String.self, forKey: .acceptedByUserId)) ?? ""
        acceptedByUserName = (try? c.decodeIfPresent(String.self, forKey: .acceptedByUserName)) ?? ""
        rejectionReason = (try? c.decodeIfPresent(String.self, forKey: .rejectionReason)) ?? ""
        adminNotes = (try? c.decodeIfPresent(String.self, forKey: .adminNotes)) ?? ""
        workerNotes = (try? c.decodeIfPresent(String.self, forKey: .workerNotes)) ?? ""
        sourceLaborContractId = (try? c.decodeIfPresent(String.self, forKey: .sourceLaborContractId)) ?? ""
        externalCompanyId = (try? c.decodeIfPresent(String.self, forKey: .externalCompanyId)) ?? ""
        externalCompanyName = (try? c.decodeIfPresent(String.self, forKey: .externalCompanyName)) ?? ""
        serviceStopTypeId = try c.decodeIfPresent(String.self, forKey: .serviceStopTypeId)
        serviceStopTypeName = try c.decodeIfPresent(String.self, forKey: .serviceStopTypeName)
        serviceStopTypeImage = try c.decodeIfPresent(String.self, forKey: .serviceStopTypeImage)
        serviceStopTypeUseCaseRawValue = try c.decodeIfPresent(String.self, forKey: .serviceStopTypeUseCaseRawValue)
        estimatedPayLines = try c.decodeIfPresent([WorkOfferPayEstimateLine].self, forKey: .estimatedPayLines)
        estimatedPayTotalCents = try c.decodeIfPresent(Int.self, forKey: .estimatedPayTotalCents)
        estimatedPayNotes = try c.decodeIfPresent(String.self, forKey: .estimatedPayNotes)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion)
        revision = try c.decodeIfPresent(Int.self, forKey: .revision)
        workPurpose = try c.decodeIfPresent(String.self, forKey: .workPurpose)
        scopeSnapshot = try c.decodeIfPresent(WorkOfferScope.self, forKey: .scopeSnapshot)
        claims = try c.decodeIfPresent([WorkOfferClaim].self, forKey: .claims)
        acceptedTerms = try c.decodeIfPresent(WorkOfferTerms.self, forKey: .acceptedTerms)
        incentive = try c.decodeIfPresent(WorkOfferIncentive.self, forKey: .incentive)
        routeId = try c.decodeIfPresent(String.self, forKey: .routeId)
        routeSource = try c.decodeIfPresent(String.self, forKey: .routeSource)
        routeName = try c.decodeIfPresent(String.self, forKey: .routeName)
        routeDate = try c.decodeIfPresent(Date.self, forKey: .routeDate)
        routeTechId = try c.decodeIfPresent(String.self, forKey: .routeTechId)
        routeServiceStopIds = try c.decodeIfPresent([String].self, forKey: .routeServiceStopIds)
        remainingStopIds = try c.decodeIfPresent([String].self, forKey: .remainingStopIds)
        routeSplitAllowed = try c.decodeIfPresent(Bool.self, forKey: .routeSplitAllowed)
        routeOfferMode = try c.decodeIfPresent(String.self, forKey: .routeOfferMode)
        workOfferCategory = try c.decodeIfPresent(String.self, forKey: .workOfferCategory)
        originalTechnicianId = try c.decodeIfPresent(String.self, forKey: .originalTechnicianId)
        coverageReason = try c.decodeIfPresent(String.self, forKey: .coverageReason)
    }

    init(
        id: String = WorkOfferIdFactory.workOfferId(),
        companyId: String,
        jobId: String,
        jobInternalId: String,
        jobName: String,
        serviceStopId: String = "",
        serviceStopInternalId: String = "",
        offerType: WorkOfferType,
        status: WorkOfferStatus = .draft,
        title: String,
        description: String,
        offeredToUserId: String = "",
        offeredToUserName: String = "",
        offeredToWorkerType: WorkerTypeEnum = .notAssigned,
        postedToBoard: Bool = false,
        boardVisibility: WorkOfferBoardVisibility = .contractorsOnly,
        boardPostId: String = "",
        boardIds: [String]? = nil,
        boardNames: [String]? = nil,
        boardName: String? = nil,
        boardMemberUserIds: [String]? = nil,
        jobTaskIds: [String],
        serviceStopTaskIds: [String] = [],
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        serviceLocationName: String = "",
        address: Address? = nil,
        proposedStartDate: Date? = nil,
        proposedEndDate: Date? = nil,
        completionDeadlineAt: Date? = nil,
        timelineNotes: String? = nil,
        estimatedMinutes: Int,
        allowsTechnicianSelfScheduling: Bool? = false,
        paySource: WorkOfferPaySource,
        offeredAmountCents: Int,
        estimatedLaborCents: Int,
        createdAt: Date = Date(),
        createdByUserId: String,
        createdByUserName: String,
        sentAt: Date? = nil,
        postedAt: Date? = nil,
        viewedAt: Date? = nil,
        acceptedAt: Date? = nil,
        rejectedAt: Date? = nil,
        cancelledAt: Date? = nil,
        completedAt: Date? = nil,
        acceptedByUserId: String = "",
        acceptedByUserName: String = "",
        rejectionReason: String = "",
        adminNotes: String = "",
        workerNotes: String = "",
        sourceLaborContractId: String = "",
        externalCompanyId: String = "",
        externalCompanyName: String = "",
        serviceStopTypeId: String? = nil,
        serviceStopTypeName: String? = nil,
        serviceStopTypeImage: String? = nil,
        serviceStopTypeUseCaseRawValue: String? = nil,
        estimatedPayLines: [WorkOfferPayEstimateLine]? = nil,
        estimatedPayTotalCents: Int? = nil,
        estimatedPayNotes: String? = nil,
    ) {
        self.id = id
        self.companyId = companyId
        self.jobId = jobId
        self.jobInternalId = jobInternalId
        self.jobName = jobName
        self.serviceStopId = serviceStopId
        self.serviceStopInternalId = serviceStopInternalId
        self.offerType = offerType
        self.status = status
        self.title = title
        self.description = description
        self.offeredToUserId = offeredToUserId
        self.offeredToUserName = offeredToUserName
        self.offeredToWorkerType = offeredToWorkerType
        self.postedToBoard = postedToBoard
        self.boardVisibility = boardVisibility
        self.boardPostId = boardPostId
        self.boardIds = boardIds
        self.boardNames = boardNames
        self.boardName = boardName
        self.boardMemberUserIds = boardMemberUserIds
        self.jobTaskIds = jobTaskIds
        self.serviceStopTaskIds = serviceStopTaskIds
        self.customerId = customerId
        self.customerName = customerName
        self.serviceLocationId = serviceLocationId
        self.serviceLocationName = serviceLocationName
        self.address = address
        self.proposedStartDate = proposedStartDate
        self.proposedEndDate = proposedEndDate
        self.completionDeadlineAt = completionDeadlineAt
        self.timelineNotes = timelineNotes
        self.estimatedMinutes = estimatedMinutes
        self.allowsTechnicianSelfScheduling = allowsTechnicianSelfScheduling
        self.paySource = paySource
        self.offeredAmountCents = offeredAmountCents
        self.estimatedLaborCents = estimatedLaborCents
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
        self.createdByUserName = createdByUserName
        self.sentAt = sentAt
        self.postedAt = postedAt
        self.viewedAt = viewedAt
        self.acceptedAt = acceptedAt
        self.rejectedAt = rejectedAt
        self.cancelledAt = cancelledAt
        self.completedAt = completedAt
        self.acceptedByUserId = acceptedByUserId
        self.acceptedByUserName = acceptedByUserName
        self.rejectionReason = rejectionReason
        self.adminNotes = adminNotes
        self.workerNotes = workerNotes
        self.sourceLaborContractId = sourceLaborContractId
        self.externalCompanyId = externalCompanyId
        self.externalCompanyName = externalCompanyName
        self.serviceStopTypeId = serviceStopTypeId
        self.serviceStopTypeName = serviceStopTypeName
        self.serviceStopTypeImage = serviceStopTypeImage
        self.serviceStopTypeUseCaseRawValue = serviceStopTypeUseCaseRawValue
        
        self.estimatedPayLines = estimatedPayLines
        self.estimatedPayTotalCents = estimatedPayTotalCents
        self.estimatedPayNotes = estimatedPayNotes
        
    }
}

enum WorkOfferType: String, Codable, CaseIterable, Identifiable {
    case directUser = "Direct User"
    case internalBoard = "Internal Board"
    case externalCompany = "External Company"

    var id: String { rawValue }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .directUser:
            return "person.crop.circle.badge.plus"
        case .internalBoard:
            return "list.bullet.clipboard"
        case .externalCompany:
            return "building.2"
        }
    }
}

struct WorkOfferPayEstimateLine: Identifiable, Codable, Hashable {
    var id: String
    var sourceTaskId: String?
    var source: PayLineItemSource
    var workTypeId: String?
    var workTypeName: String?
    var title: String
    var rateAmountCents: Int
    var rateType: RateType
    var quantity: Double
    var quantityUnit: PayQuantityUnit
    var totalAmountCents: Int
    var calculationStatus: PayCalculationStatus
    var notes: String?
    enum CodingKeys: String, CodingKey { case id, sourceTaskId, source, workTypeId, workTypeName, payTypeId, payTypeName, title, rateAmountCents, rateType, quantity, quantityUnit, totalAmountCents, calculationStatus, notes }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func raw(_ key: CodingKeys) -> String { ((try? c.decode(String.self, forKey: key)) ?? "").filter { $0.isLetter || $0.isNumber }.lowercased() }
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        sourceTaskId = try c.decodeIfPresent(String.self, forKey: .sourceTaskId)
        source = PayLineItemSource.allCases.first { $0.rawValue.lowercased() == raw(.source) } ?? .manualAdjustment
        workTypeId = try c.decodeIfPresent(String.self, forKey: .workTypeId) ?? c.decodeIfPresent(String.self, forKey: .payTypeId)
        workTypeName = try c.decodeIfPresent(String.self, forKey: .workTypeName) ?? c.decodeIfPresent(String.self, forKey: .payTypeName)
        title = (try? c.decode(String.self, forKey: .title)) ?? "Work Pay"
        rateAmountCents = (try? c.decode(Int.self, forKey: .rateAmountCents)) ?? 0
        rateType = RateType.allCases.first { $0.rawValue.lowercased() == raw(.rateType) } ?? .manual
        quantity = (try? c.decode(Double.self, forKey: .quantity)) ?? 1
        quantityUnit = PayQuantityUnit.allCases.first { $0.rawValue.lowercased() == raw(.quantityUnit) } ?? .each
        totalAmountCents = (try? c.decode(Int.self, forKey: .totalAmountCents)) ?? 0
        calculationStatus = PayCalculationStatus.allCases.first { $0.rawValue.lowercased() == raw(.calculationStatus) } ?? .needsReview
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encodeIfPresent(sourceTaskId, forKey: .sourceTaskId); try c.encode(source, forKey: .source)
        try c.encodeIfPresent(workTypeId, forKey: .workTypeId); try c.encodeIfPresent(workTypeName, forKey: .workTypeName); try c.encode(title, forKey: .title)
        try c.encode(rateAmountCents, forKey: .rateAmountCents); try c.encode(rateType, forKey: .rateType); try c.encode(quantity, forKey: .quantity)
        try c.encode(quantityUnit, forKey: .quantityUnit); try c.encode(totalAmountCents, forKey: .totalAmountCents)
        try c.encode(calculationStatus, forKey: .calculationStatus); try c.encodeIfPresent(notes, forKey: .notes)
    }
    init(id: String, sourceTaskId: String?, source: PayLineItemSource, workTypeId: String?, workTypeName: String?, title: String, rateAmountCents: Int, rateType: RateType, quantity: Double, quantityUnit: PayQuantityUnit, totalAmountCents: Int, calculationStatus: PayCalculationStatus, notes: String?) {
        self.id = id
        self.sourceTaskId = sourceTaskId
        self.source = source
        self.workTypeId = workTypeId
        self.workTypeName = workTypeName
        self.title = title
        self.rateAmountCents = rateAmountCents
        self.rateType = rateType
        self.quantity = quantity
        self.quantityUnit = quantityUnit
        self.totalAmountCents = totalAmountCents
        self.calculationStatus = calculationStatus
        self.notes = notes
    }
}
enum WorkOfferStatus: String, Codable, CaseIterable, Identifiable {
    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self)) ?? "Draft"
        self = Self(rawValue: value) ?? .draft
    }

    case pendingApproval = "Pending Approval"
    case acceptancePendingApproval = "Acceptance Pending Approval"
    case draft = "Draft"
    case sent = "Sent"
    case posted = "Posted"
    case viewed = "Viewed"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case cancelled = "Cancelled"
    case expired = "Expired"
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"

    var id: String { rawValue }

    var title: String { rawValue }

    var isOpen: Bool {
        switch self {
        case .pendingApproval, .acceptancePendingApproval, .draft, .sent, .posted, .viewed:
            return true
        case .accepted, .rejected, .cancelled, .expired, .scheduled, .inProgress, .completed:
            return false
        }
    }

    var isFinal: Bool {
        switch self {
        case .rejected, .cancelled, .expired, .completed:
            return true
        case .pendingApproval, .acceptancePendingApproval, .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress:
            return false
        }
    }
}

extension WorkOffer {
    var sentDate: Date { sentAt ?? postedAt ?? createdAt }

    func containsServiceDate(_ date: Date) -> Bool {
        (proposedStartDate.map { date >= $0 } ?? true) &&
        ((completionDeadlineAt ?? proposedEndDate).map { date <= $0 } ?? true)
    }

    func technicianStatus(for userId: String) -> WorkOfferStatus {
        // A split route can remain posted after this technician finishes their claim.
        if status.isFinal { return status }
        let ownClaims = (claims ?? []).filter { $0.workerId == userId }
        let claim = ownClaims.first { claim in
            guard let status = WorkOfferStatus(rawValue: claim.status) else { return false }
            return !status.isFinal
        } ?? ownClaims.last
        return claim.flatMap { WorkOfferStatus(rawValue: $0.status) } ?? status
    }

    func involvesTechnician(_ userId: String) -> Bool {
        !userId.isEmpty && (offeredToUserId == userId || acceptedByUserId == userId ||
            (claims ?? []).contains { $0.workerId == userId })
    }

    func isCurrentWork(for userId: String) -> Bool {
        guard involvesTechnician(userId) else { return false }
        return [.acceptancePendingApproval, .accepted, .scheduled, .inProgress]
            .contains(technicianStatus(for: userId))
    }

    func isPreviousWork(for userId: String) -> Bool {
        involvesTechnician(userId) && technicianStatus(for: userId).isFinal
    }

    var workOfferHistoryDate: Date {
        ([completedAt, cancelledAt, rejectedAt, acceptedAt, viewedAt, sentAt, postedAt] +
         (claims ?? []).map(\.withdrawnAt))
            .compactMap { $0 }.max() ?? createdAt
    }
}

enum WorkOfferPaySource: String, Codable, CaseIterable, Identifiable {
    case technicianRate = "Technician Rate"
    case offeredAmount = "Offered Amount"
    case taskContractedRates = "Task Contracted Rates"
    case unpaid = "Unpaid"

    var id: String { rawValue }

    var title: String { rawValue }
}

enum WorkOfferBoardVisibility: String, Codable, CaseIterable, Identifiable {
    case employeesOnly = "Employees Only"
    case contractorsOnly = "Contractors Only"
    case employeesAndContractors = "Employees & Contractors"
    case adminsOnly = "Admins Only"

    var id: String { rawValue }

    var title: String { rawValue }
}

enum WorkOfferIdFactory {
    static func workOfferId() -> String {
        "comp_work_offer_" + UUID().uuidString
    }

    static func boardPostId() -> String {
        "comp_work_board_" + UUID().uuidString
    }
}

struct WorkOfferScope: Codable, Hashable {
    var tasks: [WorkOfferScopeItem] = []
    var services: [WorkOfferScopeItem] = []
    var products: [WorkOfferScopeItem] = []
    var stops: [WorkOfferScopeItem] = []
    enum CodingKeys: String, CodingKey { case tasks, services, products, stops }
    init(from decoder: Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        tasks=(try? c.decode([WorkOfferScopeItem].self,forKey:.tasks)) ?? []
        services=(try? c.decode([WorkOfferScopeItem].self,forKey:.services)) ?? []
        products=(try? c.decode([WorkOfferScopeItem].self,forKey:.products)) ?? []
        stops=(try? c.decode([WorkOfferScopeItem].self,forKey:.stops)) ?? []
    }
}
struct WorkOfferScopeItem: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var description: String?
    var status: String?
    var quantity: Double?
    var equipmentName: String?
    var estimatedTime: Int?
    enum CodingKeys: String, CodingKey { case id, name, itemName, dbItemName, type, description, status, quantity, equipmentName, estimatedTime, customerName }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? ""
        name = (try? c.decode(String.self, forKey: .name)) ?? (try? c.decode(String.self, forKey: .itemName)) ?? (try? c.decode(String.self, forKey: .dbItemName)) ?? (try? c.decode(String.self, forKey: .customerName)) ?? (try? c.decode(String.self, forKey: .type)) ?? "Work item"
        description = try? c.decode(String.self, forKey: .description)
        status = try? c.decode(String.self, forKey: .status)
        quantity = (try? c.decode(Double.self, forKey: .quantity)) ?? (try? c.decode(String.self, forKey: .quantity)).flatMap(Double.init)
        equipmentName = try? c.decode(String.self, forKey: .equipmentName)
        estimatedTime = (try? c.decode(Int.self, forKey: .estimatedTime)) ?? (try? c.decode(String.self, forKey: .estimatedTime)).flatMap(Int.init)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(status, forKey: .status); try c.encodeIfPresent(quantity, forKey: .quantity)
        try c.encodeIfPresent(equipmentName, forKey: .equipmentName); try c.encodeIfPresent(estimatedTime, forKey: .estimatedTime)
    }
}
struct WorkOfferIncentive: Codable, Hashable { var type: String; var amountCents: Int?; var percentage: Double?; var notes: String? }
struct WorkOfferTerms: Codable, Hashable { var workerId: String; var workerName: String?; var paySource: String; var fixedAmountCents: Int?; var baseCents: Int?; var totalCents: Int?; var revision: Int? }
struct WorkOfferClaim: Codable, Hashable, Identifiable { var id: String; var workerId: String; var workerName: String; var stopIds: [String]; var taskIds: [String]; var status: String; var serviceStopId: String?; var agreement: WorkOfferTerms; var withdrawnAt: Date?; var withdrawalReason: String? }
