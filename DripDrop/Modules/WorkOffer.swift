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
        jobTaskIds: [String],
        serviceStopTaskIds: [String] = [],
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        serviceLocationName: String = "",
        address: Address? = nil,
        proposedStartDate: Date? = nil,
        proposedEndDate: Date? = nil,
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
        self.jobTaskIds = jobTaskIds
        self.serviceStopTaskIds = serviceStopTaskIds
        self.customerId = customerId
        self.customerName = customerName
        self.serviceLocationId = serviceLocationId
        self.serviceLocationName = serviceLocationName
        self.address = address
        self.proposedStartDate = proposedStartDate
        self.proposedEndDate = proposedEndDate
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
}
enum WorkOfferStatus: String, Codable, CaseIterable, Identifiable {
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
        case .draft, .sent, .posted, .viewed:
            return true
        case .accepted, .rejected, .cancelled, .expired, .scheduled, .inProgress, .completed:
            return false
        }
    }

    var isFinal: Bool {
        switch self {
        case .rejected, .cancelled, .expired, .completed:
            return true
        case .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress:
            return false
        }
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
