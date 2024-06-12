//
//  DBUserManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/27/24.
//


import SwiftUI
import Foundation
import FirebaseFirestoreSwift
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


final class DBUserManager {

    static let shared = DBUserManager()
    private init(){}

    //set the collection and the doucment ready for the manager
    private let userCollection = Firestore.firestore().collection("users")
    
    private func companyUserCollection() -> CollectionReference{
        Firestore.firestore().collection("users")
    }

    private func userDocument(userId:String) -> DocumentReference{
        userCollection.document(userId)

    }
    private func userCompanyDocument(userId:String,companyId:String) -> DocumentReference{
        companyUserCollection().document(userId)

    }

    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func createNewUser(user:DBUser) async throws{
        try userDocument(userId: user.id).setData(from: user,merge: false)
//        try userDocument(userId: user.id).setData(from: user,merge: false)

        print("New User Created")
    }

    func getCurrentUser(userId:String) async throws -> DBUser{
        try await userDocument(userId: userId).getDocument(as: DBUser.self,decoder: decoder)
//        try await userDocument(userId: userId).getDocument(as:DBUser.self)

    }

    
    func loadCurrentUser() async throws -> DBUser{

        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()

        return try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)

    }
    func getOneUser(userId:String) async throws -> DBUser{
        try await userDocument(userId: userId).getDocument(as: DBUser.self,decoder: decoder)
//        try await userDocument(userId: userId).getDocument(as: DBUser.self)

    }
    //for some reason this does not work
    func getAllTechs() async throws ->[DBUser]{
        print("Get all techs")
        
        let techList = try await userCollection
            .getDocuments(as:DBUser.self)
        print(techList)
        return techList
    }
    func getAllCompayTechs(companyId:String) async throws ->[DBUser]{
        return try await companyUserCollection()
//            .whereField("companyId", isEqualTo: companyId)
            .getDocuments(as:DBUser.self)
    }
    func getCurrentTechs(id:String) async throws ->[DBUser]{

        return try await userCollection
            .whereField("position", isEqualTo: "Owner")
            .whereField("id", isEqualTo: id)
            .getDocuments(as:DBUser.self)
    }
//    func findStopsByTech(stops:[ServiceStop],companyId:String,techId:String) async throws->[CompanyUser]{
//        var techsIds:[String] = []
//        var techs:[CompanyUser] = []
//        for stop in stops{
//            let techId = stop.techId
//            if !(techsIds.contains(techId ?? "")){
//                techsIds.append(techId ?? "")
//            }
//        }
//        print("Tech Ids -- Check")
//            if techId != "" {
//                print("id")
//                print(techId)
//                let workingTech = try await userCompanyDocument(userId: techId, companyId: companyId).getDocument(as: CompanyUser.self)
//                print("Found Tech: ")
//                sleep(1)
//                techs.append(workingTech)
//                print(workingTech)
//            } else {
//                print("Found Service Stop With No Tech")
//            }
//
//        print("Techs -- Check")
//
//        return techs
//    }
//    func FindTechs(stops:[ServiceStop],companyId:String) async throws->(techs:[CompanyUser],dict:[CompanyUser:[ServiceStop]]){
//        var techsIds:[String] = []
//        var dict:[CompanyUser:[ServiceStop]] = [CompanyUser(id: "", email: "", photoUrl: "", dateCreated: Date(), firstName: "", lastName: "", companyId: "", displayName: "", position: ""):[]]
//        var techs:[CompanyUser] = []
//        for stop in stops{
//            let techId = stop.techId
//            if !(techsIds.contains(techId ?? "")){
//                techsIds.append(techId ?? "")
//            }
//        }
//        print("Tech Ids -- Check")
//        print(techsIds)
//        for id in techsIds{
//            if id != "" {
//                print("id")
//                print(id)
//
//                let workingTech = try await userCompanyDocument(userId: id, companyId: companyId).getDocument(as: CompanyUser.self)
//
//                print("Found Tech: ")
//                sleep(1)
//                techs.append(workingTech)
//                print(workingTech)
//                var listOfStops:[ServiceStop] = []
//
//                for stop in stops {
//                    if stop.techId == id {
//                        listOfStops.append(stop)
//                    }
//                }
//                dict[workingTech] = listOfStops
//            } else {
//                print("Found Service Stop With No Tech")
//            }
//        }
//        print("Techs -- Check")
//        print(techs)
//        return (techs:techs,dict:dict)
//    }
//
//    func findSpecificTech(techId:String) async throws -> CompanyUser{
//        print("Finding Specific Techs")
//        return try await userDocument(userId: techId).getDocument(as: CompanyUser.self)
//
//    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Company User Storage
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    


}
