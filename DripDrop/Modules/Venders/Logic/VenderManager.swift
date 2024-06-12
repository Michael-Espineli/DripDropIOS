//
//  StoreManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
struct Vender:Identifiable, Codable,Hashable,Equatable{

    var id: String
    var name :String?
    var email : String?
    var address : Address
    var phoneNumber : String?
    
    init(
        id: String,
        name :String? = nil,
        email : String? = nil,
        address : Address,
        phoneNumber: String? = nil

    ){
        self.id = id
        self.name = name
        self.email = email
        self.address = address
        self.phoneNumber = phoneNumber
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"
            case email = "email"
            case address = "address"
            case phoneNumber = "phoneNumber"
        }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(email)
        hasher.combine(phoneNumber)

    }
    
    static func == (lhs: Vender, rhs: Vender) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.email == rhs.email &&
        lhs.phoneNumber == rhs.phoneNumber


    }
}

final class StoreManager {
    
    static let shared = StoreManager()
    private init(){}
    
    //       COLLECTION
    private func StoreCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/venders/vender")
    }
    //       DOCUMENT

    private func StoreDocument(storeId:String,companyId:String)-> DocumentReference{
        StoreCollection(companyId: companyId).document(storeId)
        
    }
    //       CREATE
    func uploadStore(companyId:String,store : Vender) async throws {

        return try StoreDocument(storeId: store.id, companyId: companyId).setData(from:store, merge: false)
    }
    func updateStore(companyId:String,store:Vender,name:String,streetAddress:String,city:String,state:String,zip:String) throws {
        
        let ref = StoreCollection(companyId: companyId).document(store.id)
        ref.updateData([
            "address": [
                "StreetAddress": streetAddress,
                "City": city,
                "State": state,
                "Zip": zip
            ],
            "name":name

        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Billing Status Successfully")
            }
        }
    }

    //        READ

    func getAllStores(companyId:String) async throws -> [Vender]{
        return try await StoreCollection(companyId: companyId)
            .getDocuments(as:Vender.self)

    }
    func getSingleStore(companyId:String,storeId:String) async throws -> Vender{
        
        return try await StoreDocument(storeId: storeId, companyId: companyId).getDocument(as: Vender.self)
        
    }
}
