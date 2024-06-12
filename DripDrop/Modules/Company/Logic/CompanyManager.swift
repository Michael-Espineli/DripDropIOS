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
    let ownerId :String?
    let name : String?
    let photoUrl : String?
    let dateCreated : Date?
    init(
        id: String,
        ownerId : String? = nil,
        name : String? = nil,
        photoUrl : String? = nil,
        dateCreated : Date? = nil


    ){
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.photoUrl = photoUrl
        self.dateCreated = dateCreated

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case ownerId = "ownerId"
            case name = "name"
            case photoUrl = "photoUrl"
            case dateCreated = "dateCreated"
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
