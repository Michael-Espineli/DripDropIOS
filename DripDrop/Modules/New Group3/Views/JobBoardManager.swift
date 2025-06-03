//
//  JobBoardManager.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import Foundation
import SwiftUI
import MapKit
struct JobBoard : Identifiable, Codable, Hashable{
    var id : String = "JB_" + UUID().uuidString
    var name : String
    var description : String
    var permissionType : JobBoardPermissionType
    var region : String // Update and Figure out how to do 
}

struct JobBoardAccess:Identifiable,Codable,Hashable{
    var id : String = "User_JBA" + UUID().uuidString
    var name : String
    var jobBoardId : String
    var accessType : JobBoardAccessType
}

struct JobPost:Identifiable,Codable,Hashable{
    var id : String = "JP_" + UUID().uuidString
    var boardId : String
    
    var ownerId : String
    var ownerName : String
    var companyId : String
    var companyName : String
    var datePosted : Date
    var ownerType : JobPosterType

    var name : String
    var description : String
    var jobType : JobType
    var tags : [String]
    var rateType : JobRateType
    var rate : Int //Cents
    var status : JobStatus
    var address : Address
    var publicLat : Double
    var publicLng : Double
    var publicLocation : CLLocation{
        CLLocation(latitude: publicLat, longitude: publicLng)
    }
    var photoUrls : [DripDropStoredImage]
    //Add More Details For Job Posting.
    
///    var equipment Optional List
    
    //Needs to be able to convert into A Labor Contract or a Recurring Labor Contract
}

enum JobType : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case oneTime = "One Time"
    case recurring = "Recurring"
}

enum JobPosterType : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case company = "Company"
    case client = "Client"
}

enum JobBoardPermissionType : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case privateAccess = "Private"
    case publicAccess = "Public"
    case inviteOnly = "Invite Only" // Maybe get ride of
}

enum JobBoardAccessType : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case owner = "Owner"
    case posting = "Posting"
    case viewer = "Viewer"
    case saved = "Saved"
}
enum JobRateType : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case negotiable = "Negotiable"
    case takingEstimates = "Taking Estimates"
    case nonNegotiable = "Non Negotiable"
}
enum JobStatus : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case open = "Open"
    case closed = "Closed"
    case inProgress = "In Progress"
}
