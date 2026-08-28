//
//  EditCompanyUserView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/19/24.
//

import SwiftUI

struct EditCompanyUserView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject var VM : EditTechViewModel
    
    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser) {
        _VM = StateObject(wrappedValue: EditTechViewModel(dataService: dataService))
        _companyUser = State(wrappedValue: tech)
    }
    
    @State var companyUser:CompanyUser
    
    @State var selectedRole:Role = Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
    
    @State var status: CompanyUserStatus = .active
    @State var workerType: WorkerTypeEnum = .contractor
    @State var active:Bool = false

    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        editHeaderCard
                        assignmentCard
                        userInfoCard
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Edit Team Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveChanges() }
                    }
                    .disabled(!hasChanges)
                }
            }
        }
        .task {
            if let company = masterDataManager.currentCompany{
                do {
                    status = companyUser.status
                    workerType = companyUser.workerType
                    selectedRole.id = companyUser.roleId
                    selectedRole.name = companyUser.roleName
                    try await VM.onFirstLoad(companyId: company.id,userId:companyUser.userId)
                    if !VM.roleList.isEmpty {
                        selectedRole = VM.roleList.first(where: {$0.id == companyUser.roleId}) ?? Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
                    }
                } catch {
                    print("")
                    print("Edit Tech View Error")
                    print(error)
                    print("")

                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private var hasChanges: Bool {
        companyUser.roleId != selectedRole.id ||
        companyUser.status != status ||
        companyUser.workerType != workerType
    }

    private var editHeaderCard: some View {
        HStack(alignment: .top, spacing: 12) {
            userAvatar

            VStack(alignment: .leading, spacing: 5) {
                Text(companyUser.userName.isEmpty ? "Team Member" : companyUser.userName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(companyUser.roleName.isEmpty ? "No role assigned" : companyUser.roleName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Created \(fullDate(date: companyUser.dateCreated))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .editCompanyUserCard(material: true)
    }

    private var assignmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Role & Access", systemImage: "person.badge.key")
                .font(.headline.weight(.semibold))

            VStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Role")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Role", selection: $selectedRole) {
                        Text("Pick Role").tag(Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: ""))
                        ForEach(VM.roleList) { role in
                            Text(role.name).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .editCompanyUserControl()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Worker Type")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Worker Type", selection: $workerType) {
                        ForEach(WorkerTypeEnum.allCases, id: \.self) { type in
                            Text(type.rawValue.isEmpty ? "Not Assigned" : type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .editCompanyUserControl()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Status", selection: $status) {
                        ForEach([CompanyUserStatus.active, .pending, .past], id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .editCompanyUserControl()
            }
        }
        .editCompanyUserCard()
    }

    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Profile", systemImage: "person.text.rectangle")
                .font(.headline.weight(.semibold))

            if let dbuser = VM.user {
                profileRow(title: "Email", value: dbuser.email, systemImage: "envelope")
                profileRow(title: "Bio", value: dbuser.bio ?? "No bio provided.", systemImage: "text.alignleft")
                profileRow(title: "Phone", value: "+(619)490-6830", systemImage: "phone")
            } else {
                Text("Profile details will appear after the user loads.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .editCompanyUserCard()
    }

    @ViewBuilder
    private var userAvatar: some View {
        if let urlString = VM.user?.photoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName:"person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 58, height: 58)
            .clipShape(Circle())
        } else {
            Image(systemName:"person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(width: 58, height: 58)
        }
    }

    private func profileRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func saveChanges() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            try await VM.updateCompanyUser(
                companyId: company.id,
                user: companyUser,
                userId: companyUser.userId,
                userName: companyUser.userName,
                roleId: selectedRole.id,
                roleName: selectedRole.name,
                dateCreated: companyUser.dateCreated,
                status: status,
                workerType: workerType
            )

            companyUser.roleId = selectedRole.id
            companyUser.roleName = selectedRole.name
            companyUser.status = status
            companyUser.workerType = workerType
            alertMessage = "Team member updated."
            showAlert = true
        } catch {
            alertMessage = "Could not update team member."
            showAlert = true
            print(error)
        }
    }
}

private extension View {
    func editCompanyUserCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }

    func editCompanyUserControl() -> some View {
        self
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct EditCompanyUserView_Previews: PreviewProvider {
    static var previews: some View {
        EditCompanyUserView(dataService: MockDataService(), tech:CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor))
    }
}
