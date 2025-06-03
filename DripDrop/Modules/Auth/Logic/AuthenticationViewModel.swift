//
//  AuthenticationViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/16/23.
//

import Foundation

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
        print("User Email >> \(String(describing: authUser.email))")
        print("User Id >> \(String(describing: authUser.uid))")

        let user = try? await DBUserManager.shared.getOneUser(userId: authUser.uid)
        guard let user = user else {
            print("User is false")
            showSignIn = true
            self.isLoading = false
            throw FireBaseRead.unableToRead
        }
        self.user = user
        
        print("User Name >> \(String(describing: user.firstName)) \(String(describing: user.lastName))")
        let accessList = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: user.id)
        print("Received List of \(accessList.count) Companies available to Access")
        var listOfCompanies:[Company] = []
        for access in accessList{
            let company = try await CompanyManager.shared.getCompany(companyId: access.id)// access id is company id
            listOfCompanies.append(company)
        }
        
        self.listOfCompanies = listOfCompanies
        if listOfCompanies.count != 0 {
            if user.recentlySelectedCompany != "" {
                print("User Recently Selected Company \(user.recentlySelectedCompany)")
                if let recentlySelectedCompany = listOfCompanies.first(where: {$0.id == user.recentlySelectedCompany}) {
                    print("Using Recently Selected Company")
                        self.company = recentlySelectedCompany
                } else {
                    print("Using First Company 1")
                    self.company = listOfCompanies.first
                }
            } else {
                print("Using First Company 2")
                self.company = listOfCompanies.first
            }
        }
        
        guard let company = self.company else {
            print("Company is false")

            showSignIn = true
            self.isLoading = false
            throw FireBaseRead.unableToRead
        }
        let companyUser = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: company.id, userId: user.id)
        self.companyUser = companyUser
        
        self.showSignIn = false
        self.isLoading = false
    }
    func signInWithEmail(email:String,password:String) async throws{
        _ = try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }

    func signUpWithEmailAndCreateCompany(email:String,password:String,firstName:String,lastName:String,company:String,position:String,serviceZipCodes:[String],services:[String]) async throws{
        let companyId = UUID().uuidString
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let userId = authDataResult.uid
        sleep(1)
        let user = DBUser(id: userId, email: authDataResult.email ?? "" , photoUrl: authDataResult.photoUrl, dateCreated: Date(),firstName: firstName, lastName: lastName,accountType: "Buisness", exp: 0, recentlySelectedCompany: "")
        
        try await DBUserManager.shared.createNewUser(user: user)
        print("User Created")
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
            services: services
        ))
        
        print("Company Created")
        sleep(1)

        //set up basic Customer Settings
        try await dataService.createFirstCompanyUser(user: user) // Fix later
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

        print("Finished Company Settings Set Up")

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
        let userId = authDataResult.uid
        sleep(1)
        let user = DBUser(id: userId, email: authDataResult.email ?? "", photoUrl: "https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/duck128.jpg?alt=media&token=549d29cd-0565-4fa4-a682-3e0816cd2fdb", dateCreated: Date(),firstName: firstName, lastName: lastName,accountType: "Technician", exp: 0,recentlySelectedCompany: "")
        
        try await dataService.createNewUser(user: user)
        print("User Created")
        //There is no Invite
        //This Technician Has no access to any companies
        sleep(1)
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
