//
//  Errors.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/25/23.
//

import Foundation
import SwiftUI

enum CustomerError: Error {
    case invalidPhoneNumber
    case invalidAddress
    func errorDescription() -> String {
        switch self {

        case .invalidPhoneNumber:
            return "invalid Phone Number"
        case .invalidAddress:
            return "invalid Address"
        }
    }
}
enum FireBaseRead: Error {
    case unableToRead
}
enum FireBasePublish: Error {
    case unableToPublish
}
enum ServiceLocationError: Error {

    case invalidCustomerId
    case invalidCustomerName
    case invalidNickName

    case invalidStreetAddress
    case invalidCity
    case invalidState
    case invalidZip
    case invalidLatitude
    case invalidLongitude
    
    case invalidContactName
    case invalidContactPhoneNumber
    case invalidContactEmail
    case invalidContactNotes

    
    case invalidGateCode
    case invalidTime
    case bodyOfWaterListEmpty
    
}
enum BodyOfWaterError: Error {

    case invalidCustomerId

}
enum JobError: Error {

    case invalidCustomer
    case invalidServiceLocation
    case invalidAdmin
    case invalidRate
    case invalidLaborCost
    case invalidJobType

}
enum RepairRequestError: Error {

    case invalidCustomer
    case invalidUser
    case invalidStatus
    case noDescription
    case imagesNotLoaded

}
enum MobileDisplayError: Error {

    case noRouteToday
    case invalidUser
    case invalidStatus
    case noDescription
    case semething
    case failedToGetWeather
    case failedToUpload
    case failedToGetServiceStops
}
enum DripDropImageError: Error, LocalizedError {
    case readError
    case decodingError
    case encodingError
    case saveError
    case saveImageError
    case readImageError
    
    var errorDescription: String? {
        switch self {
        case .readError:
            return NSLocalizedString("Could not load MyImage.json, please reinstall the app.", comment: "")
        case .decodingError:
            return NSLocalizedString("There was a problem loading your list of images, please create a new image to start over.", comment: "")
        case .encodingError:
            return NSLocalizedString("Could not save your MyImage data, please reinstall the app.", comment: "")
        case .saveError:
            return NSLocalizedString("Could not save the My Image json file.  Please reinstall the app.", comment: "")
        case .saveImageError:
            return NSLocalizedString("Could not save image.  Please reinstall the app.", comment: "")
        case .readImageError:
            return NSLocalizedString("Could not load image.  Please reinstall the app.", comment: "")
        }
    }
    
    struct ErrorType: Identifiable {
        let id = UUID()
        let error: DripDropImageError
        var message: String {
            error.localizedDescription
        }
        let button = Button("OK", role: .cancel) {}
    }
}

enum AddNewTaskToJobError: Error {

    case noName
    case noTaskType
    case noContractedRate
    case noEstimatedTime
    case noBowSelected
    case noEquipmentSelected
    case noShoppingListItem

    var errorDescription : String {
        switch self {
        case .noName:
            return "No Name Entered"
        case .noTaskType:
            return "No Task Selected"
        
        case .noContractedRate:
            return "No Contracted Rate Entered"
        case .noEstimatedTime:
            return "No Estiamted Time Entered"
        case .noBowSelected:
            return "No Body Of Water Selected"
        case .noEquipmentSelected:
            return "No Equipment Selected"
        case .noShoppingListItem:
            return "No Shopping List Item Selected"
        }
    }
}

enum ToDoError: Error {
    case invalidTechId
    case invalidTitle
    
    func errorDescription() -> String {
        switch self {
        case .invalidTechId:
            return "No Tech Id"
        case .invalidTitle:
            return "No Title"
        }
    }
}
enum RecurringContractError: Error {
    case invalidTechId
    case invalidTitle
    
    func errorDescription() -> String {
        switch self {
        case .invalidTechId:
            return "No Tech Id"
        case .invalidTitle:
            return "No Title"
        }
    }
}
