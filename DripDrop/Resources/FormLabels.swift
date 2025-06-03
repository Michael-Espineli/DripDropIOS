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
