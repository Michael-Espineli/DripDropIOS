//
//  Errors.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/25/23.
//

import Foundation

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
