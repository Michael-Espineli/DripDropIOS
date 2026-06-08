//
//  InviteViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

enum InviteStatusValue: String, CaseIterable, Identifiable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"

    var id: String { rawValue }

    var title: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    var queryVariants: [String] {
        switch self {
        case .pending:
            return ["pending", "Pending"]
        case .accepted:
            return ["accepted", "Accepted"]
        case .rejected:
            return ["rejected", "Rejected", "declined", "Declined"]
        }
    }

    static func normalized(_ value: String) -> String {
        let status = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if status == "declined" { return rejected.rawValue }
        if status == accepted.rawValue { return accepted.rawValue }
        if status == rejected.rawValue { return rejected.rawValue }
        return pending.rawValue
    }

    static func display(_ value: String) -> String {
        let normalized = normalized(value)
        return normalized.prefix(1).uppercased() + normalized.dropFirst()
    }

    static func variants(for value: String) -> [String] {
        switch normalized(value) {
        case accepted.rawValue:
            return accepted.queryVariants
        case rejected.rawValue:
            return rejected.queryVariants
        default:
            return pending.queryVariants
        }
    }

    static func isPending(_ value: String) -> Bool {
        normalized(value) == pending.rawValue
    }
}

struct Invite:Identifiable,Codable,Equatable,Hashable{
    var id : String
    var userId : String
    var firstName : String
    var lastName : String
    var email : String
    var companyName : String
    var companyId : String
    var roleId : String
    var roleName : String
    var status : String //accepting pending rejected
    var workerType : WorkerTypeEnum //Employee Independent Contractor
    var currentUser : Bool
//Date Created

    var normalizedStatus: String {
        InviteStatusValue.normalized(status)
    }

    var displayStatus: String {
        InviteStatusValue.display(status)
    }

    init(
        id: String,
        userId: String,
        firstName: String,
        lastName: String,
        email: String,
        companyName: String,
        companyId: String,
        roleId: String,
        roleName: String,
        status: String,
        workerType: WorkerTypeEnum,
        currentUser: Bool

    ){
        self.id = id
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.companyName = companyName
        self.companyId = companyId
        self.roleId = roleId
        self.roleName = roleName

        self.status = status
        self.workerType = workerType
        self.currentUser = currentUser

    }
    enum CodingKeys:String, CodingKey {
        case id = "id"
        case userId = "userId"
        case firstName = "firstName"
        case lastName = "lastName"
        case email = "email"
        case companyName = "companyName"
        case companyId = "companyId"
        case roleId = "roleId"
        case roleName = "roleName"
        case status = "status"
        case workerType = "workerType"
        case currentUser = "currentUser"
    }
}

@MainActor
final class InviteViewModel:ObservableObject{
    //----------------------------------------------------
    // INVITE VARIABLES
    //----------------------------------------------------

    @Published private(set) var invite: Invite? = nil
    
    @Published private(set) var inviteList: [Invite] = []
    @Published private(set) var acceptedInviteList: [Invite] = []
    @Published private(set) var pendingInviteList: [Invite] = []

    //----------------------------------------------------
    // CRUD           READ
    //----------------------------------------------------
    func getAllPendingComapnyInvites(companyId:String) async throws{
        self.pendingInviteList = try await InviteManager.shared.getAllCompanyInvites(comapnyId: companyId)
    }
    func getAllAcceptedComapnyInvites(companyId:String) async throws{
        self.acceptedInviteList = try await InviteManager.shared.getAllAcceptedCompanyInvites(comapnyId: companyId)
    }
    func getSelectedInvite(inviteId:String) async throws{
        self.invite = try await InviteManager.shared.getSpecificInvite(inviteId: inviteId)
    }
    //----------------------------------------------------
    // CRUD           CREATE
    //----------------------------------------------------
    func createInvite(invite:Invite) async throws {
        if invite.firstName == "" {
            print("First Name Invalid")
            throw FireBasePublish.unableToPublish
        }
        if invite.roleId == ""{
            print("No Role Selected")
            throw FireBasePublish.unableToPublish
        }
        if invite.lastName == "" {
            print("Last Name Invalid")
            throw FireBasePublish.unableToPublish
        }
        if invite.email == "" {
            print("Email Invalid")
            throw FireBasePublish.unableToPublish
        }
        try await InviteManager.shared.uploadInvite(invite: invite)
    }
    //----------------------------------------------------
    // CRUD           UPDATE
    //----------------------------------------------------
    func markInviteAsAccepted(invite:Invite) async throws {
        try? await InviteManager.shared.markInviteAsAccepted(invite: invite)
    }
}

final class InviteManager {
    static let shared = InviteManager()

    private init(){}
    //----------------------------------------------------
    // INVITE COLLECTIONS AND DOCUMENTS
    //----------------------------------------------------

    private func inviteCollection() -> CollectionReference{
        Firestore.firestore().collection("invites")
    }

    private func inviteDoc(inviteId:String)-> DocumentReference{
        inviteCollection().document(inviteId)
    }
    
    //----------------------------------------------------
    // CRUD           CREATE
    //----------------------------------------------------
    func uploadInvite(invite : Invite) async throws {
        try inviteDoc(inviteId: invite.id)
            .setData(from:invite, merge: true)
    }
    //----------------------------------------------------
    // CRUD           READ
    //----------------------------------------------------
    func getAllCompanyInvites(comapnyId : String) async throws ->[Invite] {
        return try await inviteCollection()
            .whereField(Invite.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            .whereField(Invite.CodingKeys.status.rawValue, in: InviteStatusValue.pending.queryVariants)
            .getDocuments(as:Invite.self)
    }
    func getAllAcceptedCompanyInvites(comapnyId : String) async throws ->[Invite] {
        return try await inviteCollection()
            .whereField(Invite.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            .whereField(Invite.CodingKeys.status.rawValue, in: InviteStatusValue.accepted.queryVariants)
            .getDocuments(as:Invite.self)
    }
    func getSpecificInvite(inviteId : String) async throws ->Invite {
        return try await inviteDoc(inviteId: inviteId)
            .getDocument(as: Invite.self)

    }
    //----------------------------------------------------
    // CRUD           UPDATE
    //----------------------------------------------------
    func markInviteAsAccepted(invite:Invite) async throws {
        let itemRef = inviteDoc(inviteId: invite.id)
        
        // Set the "capital" field of the city 'DC'
        itemRef.updateData([
            Invite.CodingKeys.status.rawValue: InviteStatusValue.accepted.rawValue
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }    }

    //----------------------------------------------------
    // CRUD           DELETE
    //----------------------------------------------------
    
    //----------------------------------------------------
    // CRUD           CREATE
    //----------------------------------------------------

}
