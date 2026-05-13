//
//  TechInviteListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//

import SwiftUI
import Firebase
import FirebaseFirestore
enum Tab: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    var id: String { rawValue }
    var title: String { rawValue }
}
@MainActor
final class TechInviteListViewModel: ObservableObject{

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    @Published var isLoading: Bool = true
    @Published var invites: [Invite] = []
    @Published var selectedTab: Tab = .pending

    func loadInvites(userEmail: String? = nil) async {
        self.isLoading = true
        defer { self.isLoading = false }
        // If you want invites by email for a tech, query by `email == userEmail` and status.
        // If you want invites by company for a manager, query by `companyId`.
        // Below is an example that uses `email` if available; adjust as needed.

        do {
            let snapshot = try await Firestore.firestore()
                .collection("invites")
                .whereField("email", isEqualTo: userEmail ?? "")
                .whereField("status", isEqualTo: selectedTab.rawValue)
                .getDocuments()

            let fetched: [Invite] = try snapshot.documents.compactMap { doc in
                try doc.data(as: Invite.self)
            }
            
            print("[][loadInvites] Got \(fetched.count) invites")
            self.invites = fetched
        } catch {
            print("[][loadInvites] Error fetching invites: \(error)")
            self.invites = []
        }
    }
    func onAccept(invite: Invite, user:DBUser?) {
        Task{
            guard let user else { return }
            do {
                let userAccess = UserAccess(id: invite.companyId,
                                            companyId: invite.companyId,
                                            companyName: invite.companyName,
                                            roleId: invite.roleId,
                                            roleName: invite.roleName,
                                            dateCreated: Date())
                try await dataService.uploadUserAccess(userId: user.id, companyId: invite.companyId, userAccess: userAccess)
                print("Created Company User Access")

                try await dataService.addCompanyUser(
                    companyId: invite.companyId,
                    companyUser: CompanyUser(
                        id: UUID().uuidString,
                        userId: user.id,
                        userName: user.firstName + " " + user.lastName,
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
                await loadInvites()
            } catch {
                print("[][onAccept] error \(error)")
            }
        }
       
    }
    func onReject(invite: Invite) {
        Task{
            do {
                try await dataService.markInviteAsRejected(invite: invite)
                await loadInvites()
            } catch {
                print("[][onReject] error \(error)")
            }
        }
    }
}
struct TechInviteListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : TechInviteListViewModel
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: TechInviteListViewModel(dataService: dataService))
    }



    // Inject these from your auth/session as needed
    private var userEmail: String?{
        masterDataManager.user?.email
    }
    private var userId: String?{
        masterDataManager.user?.id
    }
    private var user: DBUser?{
        masterDataManager.user
    }

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0) {
                    // Tabs
                HStack(spacing: 8) {
                    ForEach(Tab.allCases) { tab in
                        Button {
                            VM.selectedTab = tab
                            Task { await VM.loadInvites(userEmail:userEmail) }
                        } label: {
                            Text(tab.title)
                                .font(.subheadline).fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(VM.selectedTab == tab ? Color.blue : Color.clear)
                                .foregroundStyle(VM.selectedTab == tab ? Color.white : Color.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(VM.selectedTab == tab ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                    // Content
                Group {
                    if VM.isLoading {
                        LoadingSkeleton()
                            .padding()
                    } else if VM.invites.isEmpty {
                        VStack(spacing: 12) {
                            Text("No \(VM.selectedTab.rawValue) invitations found.") // No Pending invitations found.
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 240)
                    } else {
                        ScrollView {
                            ForEach(VM.invites) { invite in
                                InviteRow(
                                    invite: invite,
                                    isPendingTab: VM.selectedTab == .pending,
                                    onAccept: {
                                        VM.onAccept(invite: invite, user: user)
                                    },
                                    onReject: {
                                        VM.onReject(invite: invite)
                                    }
                                )
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.background)
                                .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
                        )
                    }
                }
                .padding(.top,8)
                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("My Invitations")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await VM.loadInvites(userEmail:userEmail)
        }
    }
}

// MARK: - Components
private struct LoadingSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(width: 160, height: 20)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(width: 220, height: 16)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(width: 80, height: 32)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15))
                )
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }
}

private struct InviteRow: View {
    let invite: Invite
    let isPendingTab: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.companyName)
                        .font(.headline)
                    Text("Sent by: \(invite.firstName) \(invite.lastName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isPendingTab {
                    HStack(spacing: 8) {
                        Button("Accept", action: onAccept)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        Button("Reject", action: onReject)
                            .buttonStyle(.bordered)
                            .tint(.red)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
