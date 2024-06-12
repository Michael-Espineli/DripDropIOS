//
//  AuthenticationManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import Foundation
import FirebaseAuth
import Firebase

struct AuthDataResultModel {
    let uid:String
    let email:String?
    let photoUrl: String?
    let isAnonymous: Bool
    
    init(user: User){
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
        self.isAnonymous = user.isAnonymous
        
    }
}
enum AuthProviderOption:String{
    case email = "password"
}
final class AuthenticationManager {
    
    //the singleton is bad for large apps so watch the Dependency injection video in the swiftfulThinking tutroial
    static let shared = AuthenticationManager()
    private init(){}
    
    private let db = Firestore.firestore()
    
    private let companyCollection = Firestore.firestore().collection("companies")
    
    private func companyDocument(companyId:String)-> DocumentReference{
        companyCollection.document(companyId)
        
    }
    func uploadCompany(company : Company) async throws {
        try companyDocument(companyId: company.id).setData(from:company, merge: false)
    }
    //    func getCompanyByUser(serviceStopId:String) async throws -> ServiceStop{
    //        try await companyDocument(serviceStopId: serviceStopId).getDocument(as: ServiceStop.self)
    //
    //    }
    
    func addNewUser(email:String, password:String) async throws -> AuthDataResultModel{
        print("delete Later 2")
        
        let originalUser = Auth.auth().currentUser!
        
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        print("delete Later 3")
        
        let result = AuthDataResultModel(user: authDataResult.user)
        print("delete Later 4")
        Auth.auth().updateCurrentUser(originalUser, completion: nil)
        
        print("Successfully created : \(result.uid)")
        
        return result
    }
    
    
    func getAuthenticatedUser() throws -> AuthDataResultModel{
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        //        print("User Authenticated")
        return AuthDataResultModel(user: user)
    }
    @discardableResult
    func createUser(email:String, password:String) async throws -> AuthDataResultModel{
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let result = AuthDataResultModel(user: authDataResult.user)
        print("Successfully created : \(result)")
        return result
        
    }
    @discardableResult
    func signInUser(email:String, password:String) async throws -> AuthDataResultModel{
        print("Check Point 2")
        
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        
        print("Check Point 3")
        
        let result = AuthDataResultModel(user: authDataResult.user)
        print("Check Point 4")
        
        print("Successfully Signed In : \(result)")
        return result
    }
    func signOut() throws {
        try Auth.auth().signOut()
        print("Signed out Successfully")
    }
    func resetPassword(email:String) throws {
        try Auth.auth().sendPasswordReset(withEmail: email) { error in
          // ...
        }
    }
    func updateEmail(email:String) throws {
        
        let user = Auth.auth().currentUser
        user?.updateEmail(to: email) { error in
        if error != nil {
            // An error happened
        } else {
           // Email updated.
           }
        }
    }
    
}

//Mark signInAnonymously

extension AuthenticationManager {
    @discardableResult
    func signInAnonymous() async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signInAnonymously()
        return AuthDataResultModel(user: authDataResult.user)
    }
}
