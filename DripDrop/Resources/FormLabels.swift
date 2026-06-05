//
//  FormLabels.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/28/24.
//

import Foundation
import SwiftUI

enum SignInFormLabels {
    case userName
    case password
    case companyName
    case email

}
enum SignUpFormLabels {
    case firstName
    case lastName
    case companyName
    case email
    case password
    case confirmPassword

}

enum NewContactFormLabels {
    case name
    case phoneNumber
    case email
    case notes

}

enum NewCustomerFormLabels {
    case firstName
    case lastName
    case companyName
    case phoneNumber
    case email
    case billingAddressStreetAddress
    case billingAddressCity
    case billingAddressState
    case billingAddressZip
    case serviceLocationMainContactNickName
    case serviceLocationMainContactGateCode
    case dogName
    case estimatedTime
    case contactNotes
    
    case serviceLocationAddressStreetAddress
    case serviceLocationAddressCity
    case serviceLocationAddressState
    case serviceLocationAddressZip
    case serviceLocationMainContactName
    case serviceLocationMainContactPhoneNumber
    case serviceLocationMainContactEmail
    case serviceLocationMainContactNotes

}

enum NewVehicalFormLabels {
    case nickName
    case year
    case make
    case model
    case color
    case plate
    case miles
}

enum NewDataBaseFormLabels {
    case name
    case sku
    case rate
    case sellPrice
    case size
    case color
    case description
}

enum ServiceLocationLabel {
    case nickName
    case serviceLocationAddressStreetAddress
    case serviceLocationAddressCity
    case serviceLocationAddressState
    case serviceLocationAddressZip
    case serviceLocationLongitude
    case serviceLocationLatitude
    
    case estimatedTime
    case gateCode
}

enum ServiceStopOperationStatus: String, Identifiable, Hashable, CaseIterable, Codable{
    case finished = "Finished"
    case notFinished = "Not Finished"
    case skipped = "Skipped"
    var id: String {
        return self.rawValue
    }
}

enum ServiceStopBillingStatus: String, Identifiable, Hashable, CaseIterable, Codable{
    case invoiced = "Invoiced"
    case paid = "Paid"
    case notInvoiced = "Not Invoiced"
    var id: String {
        return self.rawValue
    }
}

enum ServiceStopCategory: String, Identifiable, Hashable, CaseIterable, Codable {
    case route = "Route"
    case job = "Job"
    case jobEstimate = "Job Estimate"
    case serviceAgreementEstimate = "Service Agreement Estimate"
    case customerRelationship = "Customer Relationship"

    var id: String { rawValue }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .route:
            return "point.topleft.down.curvedto.point.bottomright.up"
        case .job:
            return "briefcase"
        case .jobEstimate:
            return "doc.text.magnifyingglass"
        case .serviceAgreementEstimate:
            return "list.clipboard"
        case .customerRelationship:
            return "person.wave.2"
        }
    }

    static func inferred(
        explicitCategory: ServiceStopCategory?,
        typeId: String = "",
        recurringServiceStopId: String,
        jobId: String,
        type: String,
        description: String
    ) -> ServiceStopCategory {
        if let explicitCategory {
            return explicitCategory
        }

        switch typeId.trimmingCharacters(in: .whitespacesAndNewlines) {
        case PayrollSystemSourceIds.recurringServiceStop:
            return .route
        case PayrollSystemSourceIds.jobServiceStop:
            return .job
        case PayrollSystemSourceIds.jobEstimateServiceStop:
            return .jobEstimate
        case PayrollSystemSourceIds.serviceAgreementEstimateServiceStop:
            return .serviceAgreementEstimate
        case PayrollSystemSourceIds.customerRelationshipServiceStop:
            return .customerRelationship
        default:
            break
        }

        if !recurringServiceStopId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .route
        }

        if !jobId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .job
        }

        let searchableText = (type + " " + description)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if searchableText.contains("service agreement") ||
            searchableText.contains("recurring service estimate") ||
            searchableText.contains("new pool") ||
            searchableText.contains("new service") ||
            searchableText.contains("startup") ||
            searchableText.contains("start up") {
            return .serviceAgreementEstimate
        }

        if searchableText.contains("estimate") {
            return .jobEstimate
        }

        return .customerRelationship
    }
}

enum ShoppingListCategory:String,Codable,CaseIterable {
    case personal = "Personal"
    case customer = "Customer"
    case job = "Job"

}

enum ShoppingListSubCategory:String,Codable,CaseIterable {
    case dataBase = "Data Base"
    case chemical = "Chemical"
    case part = "Part"
    case custom = "Custom"
}

enum ShoppingListStatus:String, Codable, CaseIterable, Identifiable {
    var id: String {
        return self.rawValue
    }
    case needToPurchase = "Need to Purchase"
    case purchased = "Purchased"
    case installed = "Installed"
}

enum toDoStatus: String, CaseIterable, Codable {
    case toDo = "To Do"
    case inProgress = "In Progress"
    case finished = "Finished"
    func title() -> String {
        switch self {
        case .toDo:
            return "To Do"
        case .inProgress:
            return "In Progress"
        case .finished:
            return "Finished"
        }
    }
    func color() -> Color {
        switch self {
        case .toDo:
            return .red
        case .inProgress:
            return .yellow
        case .finished:
            return .green
        }
    }
}
