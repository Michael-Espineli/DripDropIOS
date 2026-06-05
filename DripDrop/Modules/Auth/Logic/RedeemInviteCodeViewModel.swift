//
//  RedeemInviteCodeViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/29/24.
//

import Foundation
import Foundation
import CoreLocation
import MapKit
import Contacts
@MainActor
final class RedeemInviteCodeViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var errorCode:String = ""
    @Published var showAlert:Bool = false
    @Published var email:String = ""
    @Published var password:String = ""
    @Published var confirmPassword:String = ""
    @Published var firstName:String = ""
    @Published var lastName:String = ""
    @Published var inviteCode:String = "043917E4-362E-4A02-8FD9-ABD0764759E0"
    @Published var company:String = ""
    @Published var companyId:String = ""
    @Published var loggedin:Bool = false

    @Published private(set) var invite: Invite? = nil
    @Published private(set) var position:String = ""
    @Published var isLoading:Bool = false

    func onLoad() async throws{
        
    }
    func signUpWithEmailFromInviteCode(invite:Invite) async throws{
        print("[RedeemInviteCodeViewModel][signUpWithEmailFromInviteCode] ",
              "password: ",password,
              "confirmPassword: ",confirmPassword,
              "firstName: ",firstName,
              "lastName: ",lastName,
              "email: ",email,
        )
        isLoading = true
        if password == "" {
            errorCode = "Password Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if confirmPassword == "" {
            errorCode = "Confirm Password Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if password != confirmPassword {
            errorCode = "Passwords do not Match"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if email == "" {
            print("email: \(email)")
            errorCode = "Email Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if password == "" {
            errorCode = "Password Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if firstName == "" {
            errorCode = "First Name Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if lastName == "" {
            errorCode = "Last Name Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        if company == "" {
            errorCode = "Company Field Empty"
            print(errorCode)
            showAlert = true
            isLoading = false
            throw FireBasePublish.unableToPublish
        }
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let userId = authDataResult.uid
        sleep(1)
        let user = DBUser(id: userId, email: authDataResult.email ?? "", photoUrl: "https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/duck128.jpg?alt=media&token=549d29cd-0565-4fa4-a682-3e0816cd2fdb", dateCreated: Date(),firstName: firstName, lastName: lastName,accountType: "Technician", exp: 0,recentlySelectedCompany: "")
        
        try await DBUserManager.shared.createNewUser(user: user)

        print("User Created")
        try await FunctionsManager.shared.acceptTechInvite(inviteId: invite.id, userId: userId)
        print("Invite Accepted")

        sleep(1)
    }
    func joinCompanyWithInviteCode(invite:Invite) async throws {
        print("User Created")
        try await FunctionsManager.shared.acceptTechInvite(inviteId: invite.id, userId: invite.userId)
        print("Invite Accepted")

        self.inviteCode = ""
        if loggedin {
            self.errorCode = "Successfully Joined Company"

        } else {
            self.errorCode = "Successfully Joined Company, Please Login"
        }
        print(self.errorCode)
        self.showAlert = true
        self.invite = nil
    }
    func getSelectedInvite(inviteId:String) async throws{
        self.invite = try await InviteManager.shared.getSpecificInvite(inviteId: inviteId)
        if let invite = self.invite {
            if invite.status.lowercased() == "accepted" {
                self.inviteCode = ""
                self.errorCode = "Invite Already Accepted"
                print(self.errorCode)
                self.showAlert = true
                self.invite = nil
            }
        }
    }
}
