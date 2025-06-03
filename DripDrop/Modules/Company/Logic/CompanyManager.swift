//
//  CompanyManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 6/3/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
struct Company:Identifiable, Codable,Equatable,Hashable{
    let id :String
    let ownerId : String
    let ownerName : String
    let name : String
    let photoUrl : String?
    let dateCreated : Date
    let email : String
    let phoneNumber : String
    let verified : Bool
    let serviceZipCodes:[String]
    let services:[String]
    
    init(
        id: String,
        ownerId : String,
        ownerName : String,
        name : String,
        photoUrl : String? = nil,
        dateCreated : Date,
        email : String,
        phoneNumber : String,
        verified : Bool,
        serviceZipCodes : [String],
        services : [String]

    ){
        self.id = id
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.name = name
        self.photoUrl = photoUrl
        self.dateCreated = dateCreated
        self.email = email
        self.phoneNumber = phoneNumber
        self.verified = verified
        self.serviceZipCodes = serviceZipCodes
        self.services = services

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case ownerId = "ownerId"
            case name = "name"
            case ownerName = "ownerName"
            case photoUrl = "photoUrl"
            case dateCreated = "dateCreated"
            case email = "email"
            case phoneNumber = "phoneNumber"
            case verified = "verified"
            case serviceZipCodes = "serviceZipCodes"
            case services = "services"

        }
    static func == (lhs: Company, rhs: Company) -> Bool {
        return lhs.id == rhs.id &&
        lhs.ownerId == rhs.ownerId &&
        lhs.name == rhs.name &&
        lhs.photoUrl == rhs.photoUrl &&
        lhs.dateCreated == rhs.dateCreated
    }
}

final class CompanyManager {
    
    static let shared = CompanyManager()
    private init(){}
    
    private let CompanyCollection = Firestore.firestore().collection("companies")
    
    private func CompanyDocument(companyId:String)-> DocumentReference{
        CompanyCollection.document(companyId)
        
    }
    // CREATE
    func uploadCompany(company : Company) async throws {
        try CompanyDocument(companyId: company.id).setData(from:company, merge: false)
    }
    //READ
    func getAllCompanies() async throws -> [Company]{
        try await CompanyCollection
            .getDocuments(as:Company.self)
    }

    func getCompany(companyId:String) async throws -> Company{
        try await CompanyDocument(companyId: companyId).getDocument(as: Company.self)
    }
    //UPDATE
    func updateCompanyImagePath(user:DBUser,companyId:String,path:String) throws {
        let ref = CompanyDocument(companyId: companyId)
        
         ref.updateData([
            Company.CodingKeys.photoUrl.rawValue: path,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Tech Image List Successfully")
            }
        }
    }

}
