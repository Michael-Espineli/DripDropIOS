//
//  AuthenticationViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/16/23.
//

import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class AuthenticationViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var showSignIn: Bool = false
    @Published var isLoading: Bool = false
    @Published private(set) var companyUser: CompanyUser? = nil

    @Published private(set) var listOfCompanies: [Company] = []
    @Published private(set) var company: Company? = nil
    
    func onInitialLoad() async throws {
        self.isLoading = true
        self.showSignIn = true
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        print("  [AuthenticationViewModel][onInitialLoad] User Email >> \(String(describing: authUser.email))")
        print("  [AuthenticationViewModel][onInitialLoad] User Id >> \(String(describing: authUser.uid))")

        let user = try? await DBUserManager.shared.getOneUser(userId: authUser.uid)
        guard let user = user else {
            print("User is false")
            showSignIn = true
            self.isLoading = false
            throw FireBaseRead.unableToRead
        }
        self.user = user
        
        print("  [AuthenticationViewModel][onInitialLoad] User Name >> \(String(describing: user.firstName)) \(String(describing: user.lastName))")
        let accessList = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: user.id)
        print("  [AuthenticationViewModel][onInitialLoad] Received List of \(accessList.count) Companies available to Access")
        var listOfCompanies:[Company] = []
        for access in accessList{
            let company = try await CompanyManager.shared.getCompany(companyId: access.id)// access id is company id
            listOfCompanies.append(company)
        }
        print("  [AuthenticationViewModel][onInitialLoad] 1")
        self.listOfCompanies = listOfCompanies
        
        if listOfCompanies.count != 0 {
            if user.recentlySelectedCompany != "" {
                print("  [AuthenticationViewModel][onInitialLoad] User Recently Selected Company \(user.recentlySelectedCompany)")
                if let recentlySelectedCompany = listOfCompanies.first(where: {$0.id == user.recentlySelectedCompany}) {
                    print("  [AuthenticationViewModel][onInitialLoad] Using Recently Selected Company")
                        self.company = recentlySelectedCompany
                } else {
                    print("  [AuthenticationViewModel][onInitialLoad] Using First Company 1")
                    self.company = listOfCompanies.first
                }
            } else {
                print("  [AuthenticationViewModel][onInitialLoad] Do not automatically select company")
            }
        }
        
        print("  [AuthenticationViewModel][onInitialLoad] 2")
        if let company = self.company  {
            if user.id != "" || company.id != ""{
                let companyUser = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: company.id, userId: user.id)
                self.companyUser = companyUser
                self.showSignIn = false
                self.isLoading = false
            }
        } else {
            print("  [AuthenticationViewModel][onInitialLoad] Company is false")
            self.isLoading = false
        }
        
        print("  [AuthenticationViewModel][onInitialLoad] 3")
    }
    func signInWithEmail(email:String,password:String) async throws{
        _ = try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }

    func signUpWithEmailAndCreateCompany(email:String,password:String,firstName:String,lastName:String,company:String,position:String,serviceZipCodes:[String],services:[String]) async throws{
        //Set Up Stripe Connected Account
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let userId = authDataResult.uid
        sleep(1)
        
        let user = DBUser(
            id: userId,
            email: authDataResult.email ?? "" ,
            photoUrl: "https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/duck128.jpg?alt=media&token=549d29cd-0565-4fa4-a682-3e0816cd2fdb",//authDataResult.photoUrl,
            dateCreated: Date(),
            firstName: firstName,
            lastName: lastName,
            accountType: "Company",
            exp: 0,
            recentlySelectedCompany: ""
        )
        
        print("User Created")
        try await dataService.createFirstCompanyUser(user: user) // Fix later
        print("--Set Up Company From Firebase Function--")
        let setUpConnectedAccountCustomerData:[String:Any] = [
            "ownerId": userId,
            "ownerName": "\(firstName) \(lastName)",
            "companyName": company,
            "email": email,
            "phoneNumber": "",
            "zipCodes": serviceZipCodes,
            "services": services
        ]
        print(setUpConnectedAccountCustomerData)
        let result2 = try await Functions.functions().httpsCallable("createCompanyAfterSignUp").call(setUpConnectedAccountCustomerData)
        guard let json2 = result2.data as? [String: Any]  else {
                // Handle error
            print("Failed to Parse JSON")
            return
        }
        print("json2")
        print(json2)
        
        guard
              let status2 = json2["status"] as? String else {
                // Handle error
            print("Failed to Parse JSON")
            return
        }
        print("Create Company After Sign Up result \(status2)")
        print("Finished Company Settings Set Up")
        /*
        var companyId = UUID().uuidString
        //Developer Maybe Remove Later In Production
        if email == "client@test.com" {
            companyId = "Test_123"
        }
        //Create User
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let userId = authDataResult.uid
        sleep(1)
        let user = DBUser(id: userId, email: authDataResult.email ?? "" , photoUrl: authDataResult.photoUrl, dateCreated: Date(),firstName: firstName, lastName: lastName,accountType: "Company", exp: 0, recentlySelectedCompany: "")
        
        //Im prett sure I can get ride of this
//        try await DBUserManager.shared.createNewUser(user: user)
        print("User Created")
        try await dataService.createFirstCompanyUser(user: user) // Fix later
        sleep(1)

        // Create Company
        let ownerName = firstName + " " + lastName
        try await AuthenticationManager.shared.uploadCompany(company: Company(
            id: companyId,
            ownerId: userId,
            ownerName: ownerName,
            name: company,
            photoUrl: nil,
            dateCreated: Date(),
            email: authDataResult.email ?? "",
            phoneNumber: "",
            verified: false,
            serviceZipCodes: serviceZipCodes,
            services: services,
            accountType: .free,
            paidUntil: Date(),
            status: .free,
            stripeConnectAccountStatus: .notStarted
        ))
        
        print("Company Created")
        sleep(1)
        
        
        //set up basic Customer Settings
        print("First Company User Created")
        try await dataService.addCompanyUser(companyId: companyId, companyUser: CompanyUser(id: UUID().uuidString, userId: user.id, userName: firstName + " " + lastName, roleId: "1", roleName: "Owner", dateCreated: Date(), status: .active, workerType: .employee))
        print("Db Created")
        sleep(1)
        
        try await dataService.upLoadStartingCompanySettings(companyId: companyId)
        print("Uploaded Default Company Settings")
        sleep(1)
        
        let trainingList = try await dataService.upLoadIntialWorkOrdersAndReadingsAndDosages(companyId: companyId)
        print("Uploaded generic Readings and Dosages")
        sleep(1)
        
        try await dataService.uploadGenericBillingTempaltes(companyId: companyId)
        print("Uploaded generic Billing Types")
        
        try await dataService.createIntialGenericDataBaseItems(companyId: companyId)
        print("Uploaded generic DataBase Items")
        
        try await dataService.uploadGenericTraingTempaltes(companyId: companyId,templateList: trainingList)
        print("Uploaded generic Training Tempaltes")
        
        //DEVELOPER ADD INITIAL COMPANY ROLES
        try await dataService.upLoadInitialGenericRoles(companyId: companyId)
        print("Uploaded generic Company Roles")
        
        let userAccess = UserAccess(id: companyId,
                                    companyId: companyId,
                                    companyName: company,
                                    roleId: "1",
                                    roleName: "Owner",
                                    dateCreated: Date())
        try await dataService.uploadUserAccess(userId: userId, companyId: companyId, userAccess: userAccess)
        print("User Access Created")
        
        //Set Up Stripe Customer Account - For my billing
        print("--Set Up Stripe Customer Account: For my billing--")
        let createStripeCustomerData:[String:Any] = [
            "name": "\(user.firstName) \(user.lastName)",
            "email": user.email,
            "userId": user.id
        ]
        
        print(createStripeCustomerData)
        let result = try await Functions.functions().httpsCallable("createStripeCustomer").call(createStripeCustomerData)
        
        guard let json = result.data as? [String: Any],
              let status = json["status"] as? String else {
                // Handle error
            print("Failed to Parse JSON")
            return
        }
        print("Create Stripe Customer results \(status)")
        
        
        //Set Up Stripe Connected Account
        print("--Set Up Stripe Connected Account: For client billing--")
        let setUpConnectedAccountCustomerData:[String:Any] = [
            "name": "\(user.firstName) \(user.lastName)",
            "email": user.email,
            "userId": user.id
        ]
        print(setUpConnectedAccountCustomerData)
        let result2 = try await Functions.functions().httpsCallable("createNewStripeAccount").call(setUpConnectedAccountCustomerData)
        guard let json2 = result2.data as? [String: Any],
              let status2 = json2["status"] as? String else {
                // Handle error
            print("Failed to Parse JSON")
            return
        }
        print("Create New Stripe Connected Account result \(status2)")
         I Added Email Configuration Setting to the firebase function and not to this
        print("Finished Company Settings Set Up")
        */
    }
    func signUpWithEmailFromInviteCode(email:String,password:String,firstName:String,lastName:String,company:String,position:String,invite:Invite) async throws{
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let userId = authDataResult.uid
        sleep(1)
        let user = DBUser(id: userId, email: authDataResult.email ?? "", photoUrl: "https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/duck128.jpg?alt=media&token=549d29cd-0565-4fa4-a682-3e0816cd2fdb", dateCreated: Date(),firstName: firstName, lastName: lastName,accountType: "Technician", exp: 0,recentlySelectedCompany: "")
        
        try await DBUserManager.shared.createNewUser(user: user)

        print("User Created")
        let userAccess = UserAccess(id: invite.companyId, 
                                    companyId: invite.companyId,
                                    companyName: invite.companyName,
                                    roleId: invite.roleId,
                                    roleName: invite.roleName,
                                    dateCreated: Date())
        try await dataService.uploadUserAccess(userId: userId, companyId: invite.companyId, userAccess: userAccess)
        print("Created Company User Access")

        try await dataService.addCompanyUser(
            companyId: invite.companyId,
            companyUser: CompanyUser(
                id: UUID().uuidString,
                userId: userId,
                userName: firstName + " " + lastName,
                roleId: invite.roleId,
                roleName: invite.roleName,
                dateCreated: Date(),
                status: .active,
                workerType: .contractor
            )
        )
        print("User Access Created")
        try await dataService.markInviteAsAccepted(invite: invite)
        print("Invite Accepted")

        sleep(1)
    }
    func signUpWithEmailWithOutInviteCode(email:String,password:String,firstName:String,lastName:String) async throws{
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        print("[AuthenticationViewModel][signUpWithEmailWithOutInviteCode] 1")
        let userId = authDataResult.uid
        sleep(1)
        print("[AuthenticationViewModel][signUpWithEmailWithOutInviteCode] authDataResult.uid \(authDataResult.uid)")
        let dbUser = DBUser(
            id: userId,
            email: authDataResult.email ?? "",
            photoUrl: "https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/duck128.jpg?alt=media&token=549d29cd-0565-4fa4-a682-3e0816cd2fdb",
            dateCreated: Date(),
            firstName: firstName,
            lastName: lastName,
            accountType: "Company",
            exp: 0,
            recentlySelectedCompany: ""
        )
        print("[AuthenticationViewModel][signUpWithEmailWithOutInviteCode] 2")
        
        try await dataService.createNewUser(user: dbUser)
        print("[AuthenticationViewModel][signUpWithEmailWithOutInviteCode] User Created")
        //There is no Invite
        //This Technician Has no access to any companies
    }
    func signOut() throws{
        try AuthenticationManager.shared.signOut()
    }
    
    func resetPassword() throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = user.email else {
            print("Email is Optional")
            throw FireBasePublish.unableToPublish
        }
        if isValidEmail(email) {
            print("Is Valid Email")
            try AuthenticationManager.shared.resetPassword(email: email)
        } else {
            print("Is Not Valid Email")
            throw FireBasePublish.unableToPublish
        }
    }
    
    func updateEmail(email:String,confimationEmail:String) throws {
        if email != confimationEmail {
            throw FireBasePublish.unableToPublish
        }
        if isValidEmail(email) {
            try AuthenticationManager.shared.updateEmail(email: email)
        } else {
            print("Is Not Valid Email")
            throw FireBasePublish.unableToPublish
        }
    }
}
