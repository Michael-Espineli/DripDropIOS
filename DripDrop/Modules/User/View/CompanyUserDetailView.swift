    //
    //  CompanyUserDetailView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 1/21/24.
    //

import SwiftUI
import Foundation
import FirebaseFirestore

struct CompanyUserProfileOnboardingItem: Identifiable, Hashable {
    var id: String
    var name: String
    var description: String
    var sortOrder: Int
    var active: Bool
    var isComplete: Bool
    var dateCompleted: Date?
    var completedByName: String
    var completedByUserId: String

    init(id: String, data: [String: Any]) {
        self.id = stringValue(data["id"]) ?? id
        self.name = stringValue(data["name"]) ?? "Onboarding Item"
        self.description = stringValue(data["description"]) ?? ""
        self.sortOrder = intValue(data["sortOrder"]) ?? 0
        self.active = boolValue(data["active"]) ?? true
        self.isComplete = boolValue(data["isComplete"]) ?? false
        self.dateCompleted = dateValue(data["dateCompleted"]) ?? dateValue(data["completedAt"])
        self.completedByName = stringValue(data["completedByName"]) ?? ""
        self.completedByUserId = stringValue(data["completedByUserId"]) ?? ""
    }
}

struct CompanyUserProfileFile: Identifiable, Hashable {
    var id: String
    var name: String
    var contentType: String
    var size: Int
    var createdAt: Date?
    var createdByName: String
    var url: String

    var isImage: Bool {
        contentType.lowercased().hasPrefix("image/")
    }

    init(id: String, data: [String: Any]) {
        self.id = stringValue(data["id"]) ?? id
        self.name = stringValue(data["name"]) ?? stringValue(data["title"]) ?? "Technician File"
        self.contentType = stringValue(data["contentType"]) ?? stringValue(data["type"]) ?? ""
        self.size = intValue(data["size"]) ?? 0
        self.createdAt = dateValue(data["createdAt"]) ?? dateValue(data["uploadedAt"])
        self.createdByName = stringValue(data["createdByName"]) ?? "Management"
        self.url = stringValue(data["downloadUrl"]) ?? stringValue(data["url"]) ?? ""
    }
}

struct CompanyUserProfileActivityItem: Identifiable, Hashable {
    var id: String
    var type: String
    var title: String
    var subtitle: String
    var date: Date
    var systemImage: String
}

private func stringValue(_ value: Any?) -> String? {
    if let value = value as? String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    if let value {
        return String(describing: value)
    }

    return nil
}

private func intValue(_ value: Any?) -> Int? {
    if let value = value as? Int { return value }
    if let value = value as? Double { return Int(value) }
    if let value = value as? NSNumber { return value.intValue }
    if let value = value as? String { return Int(value) }
    return nil
}

private func boolValue(_ value: Any?) -> Bool? {
    if let value = value as? Bool { return value }
    if let value = value as? NSNumber { return value.boolValue }
    if let value = value as? String {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["true", "yes", "1"].contains(normalized) { return true }
        if ["false", "no", "0"].contains(normalized) { return false }
    }

    return nil
}

private func dateValue(_ value: Any?) -> Date? {
    if let value = value as? Date { return value }
    if let value = value as? Timestamp { return value.dateValue() }
    return nil
}

@MainActor
final class CompanyUserDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var screens: [String] = ["General","Activity","Performance","Onboarding","Files","Permissions"]
    @Published var selectedScreen: String = "General"
    
    @Published private(set) var acceptedInviteList: [Invite] = []
    
    @Published private(set) var pendingInviteList: [Invite] = []
    
    @Published private(set) var companyUsers: [CompanyUser] = []
    
    @Published private(set) var recentServiceStops: [ServiceStop] = []
    @Published private(set) var recentRoutes: [ActiveRoute] = []
    @Published private(set) var recentJobs: [Job] = []
    @Published private(set) var recentStatements: [TechnicianPayStatement] = []
    @Published private(set) var recentJobsCount: Int = 0
    @Published private(set) var specificTech: DBUser? = nil
    @Published private(set) var role: Role? = nil
    @Published private(set) var standrdPermissions: [PermissionModel] = PermissionViewModel().standrdPermissions
    @Published private(set) var onboardingItems: [CompanyUserProfileOnboardingItem] = []
    @Published private(set) var companyUserFiles: [CompanyUserProfileFile] = []
    @Published private(set) var activityErrorMessage: String? = nil
    @Published private(set) var onboardingErrorMessage: String? = nil
    @Published private(set) var filesErrorMessage: String? = nil
    @Published var performaceHistoryList:[PerformaceHistory] = []
    func onLoad(companyId:String,companyUser:CompanyUser) async throws{
        self.specificTech = try await dataService.getOneUser(userId: companyUser.userId)
        self.role = try await dataService.getSpecificRole(companyId: companyId, roleId: companyUser.roleId)
        self.performaceHistoryList = try await dataService.getPerformaceReivewByUserId(companyId: companyId, companyUserId: companyUser.id)
        await loadActivity(companyId: companyId, companyUser: companyUser)
        await loadOnboarding(companyId: companyId, companyUserId: companyUser.id)
        await loadFiles(companyId: companyId, companyUserId: companyUser.id)
    }
    func getPerformaceReivewByUserId(companyId:String,companyUserId:String) async throws {
        self.performaceHistoryList = try await dataService.getPerformaceReivewByUserId(companyId: companyId, companyUserId: companyUserId)
    }
    func getOneTech(techId: String) async throws{
        self.specificTech = try await dataService.getOneUser(userId: techId)
    }

    func loadActivity(companyId:String,companyUser:CompanyUser) async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -180, to: endDate) ?? endDate
        let lookupIds = Set([companyUser.userId, companyUser.id].filter { !$0.isEmpty })
        var errors: [String] = []

        do {
            let serviceStops = try await dataService.getAllServiceStopsBetweenDateByUserId(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate,
                userId: companyUser.userId
            )
            self.recentServiceStops = Array(serviceStops.sorted { $0.serviceDate > $1.serviceDate }.prefix(8))
        } catch {
            errors.append("recent service stops")
            self.recentServiceStops = []
        }

        do {
            let routes = try await dataService.getRecentActiveRouteForTech(
                companyId: companyId,
                techId: companyUser.userId,
                days: 180
            )
            self.recentRoutes = Array(routes.sorted { $0.date > $1.date }.prefix(8))
        } catch {
            errors.append("recent routes")
            self.recentRoutes = []
        }

        do {
            let statements = try await dataService.fetchTechnicianPayStatements(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )
            self.recentStatements = Array(statements
                .filter { lookupIds.contains($0.technicianId) }
                .sorted { statementDate($0) > statementDate($1) }
                .prefix(8)
            )
        } catch {
            errors.append("recent statements")
            self.recentStatements = []
        }

        var jobs: [Job] = []
        let jobIds = Array(Set(recentServiceStops.map(\.jobId).filter { !$0.isEmpty })).prefix(10)

        for jobId in jobIds {
            do {
                let job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
                jobs.append(job)
            } catch {
                errors.append("linked jobs")
            }
        }

        self.recentJobs = Array(jobs.sorted { $0.dateCreated > $1.dateCreated }.prefix(8))
        self.recentJobsCount = recentJobs.count
        self.activityErrorMessage = errors.isEmpty ? nil : "Some activity could not be loaded: \(Array(Set(errors)).sorted().joined(separator: ", "))."
    }

    func loadOnboarding(companyId:String,companyUserId:String) async {
        do {
            let snapshot = try await companyUserDocument(companyId: companyId, companyUserId: companyUserId)
                .collection("onboardingChecklist")
                .getDocuments()

            self.onboardingItems = snapshot.documents
                .map { CompanyUserProfileOnboardingItem(id: $0.documentID, data: $0.data()) }
                .filter(\.active)
                .sorted {
                    if $0.sortOrder == $1.sortOrder {
                        return $0.name < $1.name
                    }

                    return $0.sortOrder < $1.sortOrder
                }
            self.onboardingErrorMessage = nil
        } catch {
            self.onboardingItems = []
            self.onboardingErrorMessage = "Onboarding checklist could not be loaded."
        }
    }

    func loadFiles(companyId:String,companyUserId:String) async {
        do {
            let snapshot = try await companyUserDocument(companyId: companyId, companyUserId: companyUserId)
                .collection("files")
                .getDocuments()

            self.companyUserFiles = snapshot.documents
                .map { CompanyUserProfileFile(id: $0.documentID, data: $0.data()) }
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            self.filesErrorMessage = nil
        } catch {
            self.companyUserFiles = []
            self.filesErrorMessage = "Profile files could not be loaded."
        }
    }

    private func companyUserDocument(companyId:String,companyUserId:String) -> DocumentReference {
        Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("companyUsers")
            .document(companyUserId)
    }

    private func statementDate(_ statement: TechnicianPayStatement) -> Date {
        statement.paidAt ?? statement.approvedAt ?? statement.endDate
    }
    
}
struct CompanyUserDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var techListVM: TechListViewModel

    @StateObject var VM: CompanyUserDetailViewModel

    init(dataService: any ProductionDataServiceProtocol, companyUserId: String) {
        _VM = StateObject(wrappedValue: CompanyUserDetailViewModel(dataService: dataService))
        _companyUserId = State(wrappedValue: companyUserId)
    }

    @State var companyUserId: String

    @State private var showSheet: Bool = false
    @State var showNewPerformaceHistory: Bool = false
    @State var showPerformaceHistory: Bool = false
    @State var showNewWorkContract: Bool = false
    @State var showWorkContractList: Bool = false
    @State var seePermissions: Bool = false

    @State var tech: DBUser? = nil

    private var companyUser: CompanyUser? {
        techListVM.companyUsers.first { $0.id == companyUserId }
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    screenPickerCard
                    selectedContent
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(VM.specificTech == nil ? "Team Member" : "\(VM.specificTech?.firstName ?? "") \(VM.specificTech?.lastName ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button {
                    showSheet.toggle()
                } label: {
                    Text("Edit")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showSheet) {
            if let companyUser {
                EditCompanyUserView(dataService: dataService, tech: companyUser)
            }
        }
        .sheet(isPresented: $seePermissions) {
            if let companyUser {
                CompanyRoleLoadingView(roleId: companyUser.roleId)
            }
        }
        .task {
            do {
                if let companyUser, let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id, companyUser: companyUser)
                } else {
                    print("Company User Error")
                }
            } catch {
                print("Error Getting DetailView")
                print(error)
            }
        }
    }
}

extension CompanyUserDetailView {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                profileImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let companyUser {
                        Text(companyUser.roleName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let tech = VM.specificTech {
                        Text(tech.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                if let companyUser {
                    statusBadge(companyUser.status)

                    Label(companyUser.workerType.rawValue, systemImage: "person.crop.circle.badge.checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())

                    Label(fullDate(date: companyUser.dateCreated), systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var profileImage: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: UIDevice.isIPhone ? 72 : 92, height: UIDevice.isIPhone ? 72 : 92)

            if let imageLink = VM.specificTech?.photoUrl,
               let url = URL(string: imageLink) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIDevice.isIPhone ? 66 : 86, height: UIDevice.isIPhone ? 66 : 86)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: UIDevice.isIPhone ? 58 : 76))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: UIDevice.isIPhone ? 58 : 76))
                    .foregroundStyle(.secondary)
            }
        }
    }

    var screenPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Profile Sections", systemImage: "slider.horizontal.3")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VM.screens, id: \.self) { screen in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                VM.selectedScreen = screen
                            }
                        } label: {
                            Text(screen)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(VM.selectedScreen == screen ? .primary : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    VM.selectedScreen == screen ? Color.accentColor.opacity(0.16) : Color.clear,
                                    in: Capsule()
                                )
                                .background(.thinMaterial, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    var selectedContent: some View {
        switch VM.selectedScreen {
        case "General":
            generalContent

        case "Activity":
            activityContent

        case "Performance":
            performanceHistoryCard

        case "Onboarding":
            onboardingContent

        case "Files":
            filesContent

        case "Permissions":
            permissionsContent

        default:
            generalContent
        }
    }
}

// MARK: - General

extension CompanyUserDetailView {

    var generalContent: some View {
        VStack(spacing: 14) {
            personalInfoCard
            companyInfoCard
            accessSnapshotCard
            routeVehicleAccessCard

            if let companyUser,
               let currentCompany = masterDataManager.currentCompany,
               masterDataManager.role?.permissionIdList.contains("420") == true {
                technicianPayrollInfoCard(
                    companyId: currentCompany.id,
                    companyUser: companyUser
                )
            }
        }
    }

    var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("User Information", systemImage: "person.text.rectangle")

            if let tech = VM.specificTech {
                VStack(spacing: 8) {
                    detailRow(title: "First Name", value: tech.firstName, systemImage: "person")
                    detailRow(title: "Last Name", value: tech.lastName, systemImage: "person")
                    detailRow(title: "Email", value: tech.email, systemImage: "envelope")
                    detailRow(title: "Phone Number", value: "+(619)490-6830", systemImage: "phone")

                    if let bio = tech.bio, !bio.isEmpty {
                        notesBlock(title: "Bio", value: bio, systemImage: "text.alignleft")
                    } else {
                        notesBlock(title: "Bio", value: "No bio provided.", systemImage: "text.alignleft")
                    }
                }
            } else {
                emptyState(
                    title: "No user details loaded.",
                    message: "User information will appear here once loaded.",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var companyInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Company Relationship", systemImage: "building.2")

                Spacer()

                roleDetailsButton
            }

            if let companyUser {
                VStack(spacing: 8) {
                    detailRow(title: "Position", value: companyUser.roleName, systemImage: "person.badge.key")
                    detailRow(title: "Date Created", value: fullDate(date: companyUser.dateCreated), systemImage: "calendar")
                    detailRow(title: "Worker Type", value: companyUser.workerType.rawValue, systemImage: "hammer")
                    detailRow(title: "Status", value: companyUser.status.rawValue, systemImage: "circle.dashed")

//                    if companyUser.workerType == .contractor {
//                        notesBlock(
//                            title: "Contractor Company",
//                            value: companyUser.linkedCompanyName? ? "No linked company." : companyUser.linkedCompanyName,
//                            systemImage: "building"
//                        )
//                    }
                }
            } else {
                emptyState(
                    title: "No company user found.",
                    message: "Company details could not be loaded.",
                    systemImage: "building.2"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var accessSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Access Snapshot", systemImage: "person.text.rectangle")

            if let companyUser {
                VStack(spacing: 8) {
                    detailRow(title: "Status", value: companyUser.status.rawValue, systemImage: "circle.dashed")
                    detailRow(title: "Worker Type", value: companyUser.workerType.rawValue, systemImage: "person.crop.circle.badge.checkmark")
                    detailRow(title: "Dashboard Views", value: "Role default", systemImage: "rectangle.grid.2x2")
                    detailRow(title: "Customer Tags", value: "Role default", systemImage: "tag")
                }
            } else {
                emptyState(
                    title: "No access snapshot.",
                    message: "Access details could not be loaded.",
                    systemImage: "person.text.rectangle"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var routeVehicleAccessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Route Vehicle Access", systemImage: "car")

            if let companyUser {
                VStack(spacing: 8) {
                    detailRow(
                        title: "Allowed Vehicles",
                        value: routeVehicleAccessLabel(companyUser.normalizedRouteVehicleAccess),
                        systemImage: "car.2"
                    )

                    if let personalVehicle = companyUser.personalVehicle,
                       companyUser.canUsePersonalRouteVehicle {
                        detailRow(
                            title: "Personal Vehicle",
                            value: personalVehicleDisplayName(personalVehicle),
                            systemImage: "car"
                        )
                        detailRow(
                            title: "Plate",
                            value: personalVehicle.plate ?? "",
                            systemImage: "number"
                        )
                    }
                }
            } else {
                emptyState(
                    title: "No vehicle access.",
                    message: "Vehicle access details could not be loaded.",
                    systemImage: "car"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    var roleDetailsButton: some View {
        if companyUser != nil {
            if UIDevice.isIPhone {
                if let role = VM.role {
                    NavigationLink(value: Route.userRoleDetailView(dataService: dataService, role: role)) {
                        Label("Role", systemImage: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    seePermissions.toggle()
                } label: {
                    Label("Permissions", systemImage: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Contracts", systemImage: "doc.text")

                Spacer()

                Button {
                    showNewWorkContract.toggle()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showNewWorkContract) {
                    ScrollView {
                        Text("AddNewLaborContract")
                    }
                    .presentationDetents([.medium, .large])
                }

                Button {
                    showWorkContractList.toggle()
                } label: {
                    Label("More", systemImage: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showWorkContractList) {
                    RecurringLaborContractListView(dataService: dataService)
                }
            }

            if MockDataService.mockRecurringLaborContracts.isEmpty {
                emptyState(
                    title: "No contracts.",
                    message: "Recurring labor contracts will show here.",
                    systemImage: "doc.text"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(MockDataService.mockRecurringLaborContracts.prefix(3)) { contract in
                        RecurringLaborContractCardView(laborContract: contract)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Permissions

extension CompanyUserDetailView {

    var permissionsContent: some View {
        VStack(spacing: 14) {
            roleInfoSummaryCard
            rolePermissionsCard
        }
    }

    var roleInfoSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Role Info", systemImage: "person.badge.key")

                Spacer()

                roleDetailsButton
            }

            if let companyUser {
                if let role = VM.role {
                    VStack(spacing: 8) {
                        detailRow(
                            title: "Assigned Role",
                            value: role.name.isEmpty ? companyUser.roleName : role.name,
                            systemImage: "tag"
                        )

                        detailRow(
                            title: "Role ID",
                            value: role.id,
                            systemImage: "number"
                        )

                        detailRow(
                            title: "Permissions",
                            value: "\(activePermissionIds.count) of \(VM.standrdPermissions.count)",
                            systemImage: "checklist"
                        )

                        detailRow(
                            title: "Managed Users",
                            value: "\(role.listOfUserIdsToManage.count)",
                            systemImage: "person.2"
                        )

                        notesBlock(
                            title: "Description",
                            value: role.description.isEmpty ? "No role description provided." : role.description,
                            systemImage: "text.alignleft"
                        )
                    }
                } else {
                    emptyState(
                        title: "Role details unavailable.",
                        message: companyUser.roleId.isEmpty ? "No role is assigned to this user." : "The assigned role could not be loaded.",
                        systemImage: "person.badge.key"
                    )
                }
            } else {
                emptyState(
                    title: "No company user found.",
                    message: "Role information could not be loaded.",
                    systemImage: "person.badge.key"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var rolePermissionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Role Permissions", systemImage: "lock.shield")

                Spacer()

                Text("\(activePermissionIds.count) selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.role == nil {
                emptyState(
                    title: "No role permissions found.",
                    message: "Assign or update this user's role to define default permissions.",
                    systemImage: "lock.slash"
                )
            } else if selectedPermissionCategoryGroups.isEmpty && unknownPermissionIds.isEmpty {
                emptyState(
                    title: "No permissions assigned.",
                    message: "This role does not currently grant any catalog permissions.",
                    systemImage: "lock.slash"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(selectedPermissionCategoryGroups) { categoryGroup in
                        permissionCategoryDisplay(categoryGroup)
                    }

                    if !unknownPermissionIds.isEmpty {
                        unknownPermissionDisplay
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var activePermissionIds: [String] {
        PermissionSelectionHelper.normalizeSelection(
            VM.role?.permissionIdList ?? [],
            permissions: VM.standrdPermissions
        )
    }

    var permissionCategoryGroups: [PermissionCategoryGroup] {
        PermissionSelectionHelper.categoryGroups(from: VM.standrdPermissions)
    }

    var selectedPermissionCategoryGroups: [PermissionCategoryGroup] {
        permissionCategoryGroups.filter {
            PermissionSelectionHelper.selectedCount(for: $0, selectedIds: activePermissionIds) > 0
        }
    }

    var unknownPermissionIds: [String] {
        let knownIds = Set(VM.standrdPermissions.map(\.id))
        return activePermissionIds.filter { !knownIds.contains($0) }
    }

    func permissionCategoryDisplay(_ categoryGroup: PermissionCategoryGroup) -> some View {
        let selectedCount = PermissionSelectionHelper.selectedCount(
            for: categoryGroup,
            selectedIds: activePermissionIds
        )

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(categoryGroup.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(selectedCount)/\(categoryGroup.permissions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            VStack(spacing: 8) {
                ForEach(categoryGroup.groups.filter { groupHasSelection($0) }) { group in
                    permissionGroupDisplay(group)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func groupHasSelection(_ group: PermissionSelectionGroup) -> Bool {
        activePermissionIds.contains(group.parent.id) ||
        group.children.contains { activePermissionIds.contains($0.id) }
    }

    func permissionGroupDisplay(_ group: PermissionSelectionGroup) -> some View {
        let parentSelected = activePermissionIds.contains(group.parent.id)
        let selectedChildren = group.children.filter { activePermissionIds.contains($0.id) }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: parentSelected ? "checkmark.circle.fill" : "minus.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(parentSelected ? Color.poolGreen : Color.accentColor)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.parent.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if !group.parent.description.isEmpty {
                        Text(group.parent.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }

            if !selectedChildren.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(selectedChildren) { child in
                        Text(child.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.06), in: Capsule())
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    var unknownPermissionDisplay: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Unknown Permission IDs")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orange)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(unknownPermissionIds, id: \.self) { permissionId in
                    Text(permissionId)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Activity

extension CompanyUserDetailView {
    var activityContent: some View {
        VStack(spacing: 14) {
            recentActivityCard

            if let companyUser, companyUser.workerType == .employee {
                hoursWorkedCard
            }

            activityTimelineCard
        }
    }

    var hoursWorkedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Hours Worked", systemImage: "clock.arrow.circlepath")

            VStack(spacing: 8) {
                activitySummaryRow(
                    title: "Regular Hours",
                    value: "40 Hours",
                    subtitle: "Base Hours and pay rate",
                    systemImage: "mappin.and.ellipse"
                )

                activitySummaryRow(
                    title: "Time and a half",
                    value: "5 Hours",
                    subtitle: "Time worked at x1.5 Hourly Rate",
                    systemImage: "briefcase"
                )

                activitySummaryRow(
                    title: "Double Time",
                    value: "2 Hours",
                    subtitle: "Time worked at x2 Hourly Rate",
                    systemImage: "cart"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Work Activity", systemImage: "clock.arrow.circlepath")

            if let activityErrorMessage = VM.activityErrorMessage {
                warningBlock(activityErrorMessage)
            }

            VStack(spacing: 8) {
                activitySummaryRow(
                    title: "Service Stops",
                    value: "\(VM.recentServiceStops.count)",
                    subtitle: "Latest assigned stops",
                    systemImage: "mappin.and.ellipse"
                )

                activitySummaryRow(
                    title: "Routes",
                    value: "\(VM.recentRoutes.count)",
                    subtitle: "Latest active route records",
                    systemImage: "map"
                )

                activitySummaryRow(
                    title: "Jobs",
                    value: "\(VM.recentJobs.count)",
                    subtitle: "Linked from recent service stops",
                    systemImage: "briefcase"
                )

                activitySummaryRow(
                    title: "Statements",
                    value: "\(VM.recentStatements.count)",
                    subtitle: "Latest payroll statements",
                    systemImage: "doc.text"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var activityTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Recent Activity", systemImage: "list.bullet.rectangle")

            if activityItems.isEmpty {
                emptyState(
                    title: "No recent work activity found.",
                    message: "Work activity will appear after this user is assigned service stops, runs routes, or receives pay statements.",
                    systemImage: "clock.badge.questionmark"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(activityItems) { item in
                        activityTimelineRow(item)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var activityItems: [CompanyUserProfileActivityItem] {
        let serviceStopItems = VM.recentServiceStops.map { stop in
            CompanyUserProfileActivityItem(
                id: "serviceStop-\(stop.id)",
                type: "Service Stop",
                title: serviceStopTitle(stop),
                subtitle: serviceStopSubtitle(stop),
                date: stop.serviceDate,
                systemImage: "mappin.and.ellipse"
            )
        }

        let routeItems = VM.recentRoutes.map { route in
            CompanyUserProfileActivityItem(
                id: "route-\(route.id)",
                type: "Route",
                title: route.name.isEmpty ? "Route" : route.name,
                subtitle: "\(route.status.rawValue) - \(route.finishedStops)/\(route.totalStops) stops",
                date: route.date,
                systemImage: "map"
            )
        }

        let jobItems = VM.recentJobs.map { job in
            CompanyUserProfileActivityItem(
                id: "job-\(job.id)",
                type: "Job",
                title: job.internalId.isEmpty ? job.type : "Job #\(job.internalId)",
                subtitle: [job.customerName, job.operationStatus.rawValue, job.billingStatus.rawValue]
                    .filter { !$0.isEmpty }
                    .joined(separator: " - "),
                date: job.dateCreated,
                systemImage: "briefcase"
            )
        }

        let statementItems = VM.recentStatements.map { statement in
            CompanyUserProfileActivityItem(
                id: "statement-\(statement.id)",
                type: "Pay Statement",
                title: statement.statementReference ?? "Pay Statement",
                subtitle: "\(moneyFromCents(statement.totalCents)) - \(statement.status.rawValue)",
                date: statement.paidAt ?? statement.approvedAt ?? statement.endDate,
                systemImage: "doc.text"
            )
        }

        return Array((serviceStopItems + routeItems + jobItems + statementItems)
            .sorted { $0.date > $1.date }
            .prefix(16)
        )
    }

    func activityTimelineRow(_ item: CompanyUserProfileActivityItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.type)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)

                    Text(shortDate(date: item.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func activitySummaryRow(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Onboarding

extension CompanyUserDetailView {

    var onboardingContent: some View {
        VStack(spacing: 14) {
            onboardingStatsCard
            onboardingChecklistCard
        }
    }

    var onboardingStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Onboarding Summary", systemImage: "checklist")

            VStack(spacing: 8) {
                activitySummaryRow(
                    title: "Checklist Items",
                    value: "\(VM.onboardingItems.count)",
                    subtitle: "Copied to user",
                    systemImage: "checklist"
                )

                activitySummaryRow(
                    title: "Completed",
                    value: "\(completedOnboardingItems.count)",
                    subtitle: "Marked done",
                    systemImage: "checkmark.circle"
                )

                activitySummaryRow(
                    title: "Remaining",
                    value: "\(openOnboardingItems.count)",
                    subtitle: "Still open",
                    systemImage: "clock"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var onboardingChecklistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Onboarding Checklist", systemImage: "clipboard")

            if let onboardingErrorMessage = VM.onboardingErrorMessage {
                warningBlock(onboardingErrorMessage)
            }

            if VM.onboardingItems.isEmpty {
                emptyState(
                    title: "No onboarding checklist copied yet.",
                    message: "Copy the company template on web to start tracking this user's setup items.",
                    systemImage: "clipboard"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.onboardingItems) { item in
                        onboardingItemRow(item)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var completedOnboardingItems: [CompanyUserProfileOnboardingItem] {
        VM.onboardingItems.filter(\.isComplete)
    }

    var openOnboardingItems: [CompanyUserProfileOnboardingItem] {
        VM.onboardingItems.filter { !$0.isComplete }
    }

    func onboardingItemRow(_ item: CompanyUserProfileOnboardingItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(item.isComplete ? Color.poolGreen : Color.secondary)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.isComplete ? .secondary : .primary)
                    .strikethrough(item.isComplete)
                    .lineLimit(2)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Text(onboardingStatusText(item))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.isComplete ? Color.poolGreen : Color.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Files

extension CompanyUserDetailView {

    var filesContent: some View {
        VStack(spacing: 14) {
            filesStatsCard
            savedFilesCard
        }
    }

    var filesStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("File Summary", systemImage: "paperclip")

            VStack(spacing: 8) {
                activitySummaryRow(
                    title: "Files",
                    value: "\(VM.companyUserFiles.count)",
                    subtitle: "Saved to profile",
                    systemImage: "paperclip"
                )

                activitySummaryRow(
                    title: "Photos",
                    value: "\(photoFileCount)",
                    subtitle: "\(documentFileCount) document\(documentFileCount == 1 ? "" : "s")",
                    systemImage: "photo"
                )

                activitySummaryRow(
                    title: "Storage",
                    value: fileSizeText(totalFileBytes),
                    subtitle: "Uploaded file size",
                    systemImage: "externaldrive"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var savedFilesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Saved Files", systemImage: "folder")

            if let filesErrorMessage = VM.filesErrorMessage {
                warningBlock(filesErrorMessage)
            }

            if VM.companyUserFiles.isEmpty {
                emptyState(
                    title: "No files attached.",
                    message: "Uploaded technician documents and photos will appear here.",
                    systemImage: "folder"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.companyUserFiles) { file in
                        profileFileRow(file)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var photoFileCount: Int {
        VM.companyUserFiles.filter(\.isImage).count
    }

    var documentFileCount: Int {
        VM.companyUserFiles.count - photoFileCount
    }

    var totalFileBytes: Int {
        VM.companyUserFiles.reduce(0) { $0 + $1.size }
    }

    func profileFileRow(_ file: CompanyUserProfileFile) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: file.isImage ? "photo" : "doc.text")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(file.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(fileTypeLabel(file)) - \(fileSizeText(file.size))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Uploaded \(shortDate(date: file.createdAt)) by \(file.createdByName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if let url = URL(string: file.url), !file.url.isEmpty {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.12), in: Circle())
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Money

extension CompanyUserDetailView {

    var moneyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Money", systemImage: "dollarsign.circle")

            VStack(spacing: 8) {
                moneyRow(title: "Work Done and Not Billed", value: "$304.76", systemImage: "clock.badge.exclamationmark")
                moneyRow(title: "Money Due", value: "$1,642.76", systemImage: "creditcard")
                moneyRow(title: "Recently Paid", value: "$3,278.76", systemImage: "checkmark.circle")
                moneyRow(title: "Year To Date", value: "$48,642.76", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func moneyRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    //Rate Sheet
    var rateSheetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Rate Sheet", systemImage: "dollarsign.circle")

            VStack(spacing: 8) {
                moneyRow(title: "Work Done and Not Billed", value: "$304.76", systemImage: "clock.badge.exclamationmark")
                moneyRow(title: "Money Due", value: "$1,642.76", systemImage: "creditcard")
                moneyRow(title: "Recently Paid", value: "$3,278.76", systemImage: "checkmark.circle")
                moneyRow(title: "Year To Date", value: "$48,642.76", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    //Hourly
    var payCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Pay Details", systemImage: "dollarsign.circle")

            VStack(spacing: 8) {
                moneyRow(title: "Hourly Wage", value: "$30.00", systemImage: "clock.badge.exclamationmark")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Reviews

extension CompanyUserDetailView {

    var performanceHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let companyUser {
                HStack {
                    sectionHeader("Performance History", systemImage: "star.bubble")

                    Spacer()

                    Button {
                        showNewPerformaceHistory.toggle()
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showNewPerformaceHistory, onDismiss: {
                        Task {
                            await reloadPerformanceHistory()
                        }
                    }) {
                        AddNewPerformanceHistory(dataService: dataService, companyUser: companyUser)
                            .presentationDetents([.large])
                    }

                    Button {
                        showPerformaceHistory.toggle()
                    } label: {
                        Label("More", systemImage: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showPerformaceHistory) {
                        PerformaceHistoryList(dataService: dataService, companyUser: companyUser)
                            .presentationDetents([.large])
                    }
                }

                if VM.performaceHistoryList.isEmpty {
                    emptyState(
                        title: "No performance history.",
                        message: "Reviews and notes will show here.",
                        systemImage: "star.bubble"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(VM.performaceHistoryList.prefix(5)) { performace in
                            PerformanceHistoryCardView(performanceHistory: performace)
                        }
                    }
                }
            } else {
                emptyState(
                    title: "No user selected.",
                    message: "Performance history could not be loaded.",
                    systemImage: "star.bubble"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @MainActor
    private func reloadPerformanceHistory() async {
        guard let companyUser,
              let company = masterDataManager.currentCompany else { return }

        do {
            try await VM.getPerformaceReivewByUserId(companyId: company.id, companyUserId: companyUser.id)
        } catch {
            print("Error refreshing performance history")
            print(error)
        }
    }
}

// MARK: - Reusable UI

extension CompanyUserDetailView {

    var displayName: String {
        if let tech = VM.specificTech {
            let fullName = "\(tech.firstName) \(tech.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            return fullName.isEmpty ? "Team Member" : fullName
        }

        if let companyUser {
            return companyUser.userName.isEmpty ? "Team Member" : companyUser.userName
        }

        return "Team Member"
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func detailRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
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
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func notesBlock(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    func statusBadge(_ status: CompanyUserStatus) -> some View {
        let color: Color = {
            switch status {
            case .active:
                return Color.poolGreen
            case .pending:
                return Color.orange
            case .past:
                return Color.red
            }
        }()

        return Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12), in: Capsule())
    }

    func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func warningBlock(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func routeVehicleAccessLabel(_ value: String) -> String {
        switch value {
        case "personal":
            return "Personal vehicle"
        case "both":
            return "Company or personal"
        default:
            return "Company vehicle"
        }
    }

    func personalVehicleDisplayName(_ vehicle: PersonalVehicle) -> String {
        vehicle.displayName
    }

    func serviceStopTitle(_ stop: ServiceStop) -> String {
        if let jobName = stop.jobName?.trimmingCharacters(in: .whitespacesAndNewlines), !jobName.isEmpty {
            return jobName
        }

        let type = stop.type.trimmingCharacters(in: .whitespacesAndNewlines)
        return type.isEmpty ? "Service Stop" : type
    }

    func serviceStopSubtitle(_ stop: ServiceStop) -> String {
        [stop.customerName, stop.operationStatus.rawValue, stop.billingStatus.rawValue]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }

    func moneyFromCents(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0"
    }

    func onboardingStatusText(_ item: CompanyUserProfileOnboardingItem) -> String {
        guard item.isComplete else { return "Open" }

        var status = "Completed"
        if let dateCompleted = item.dateCompleted {
            status += " \(shortDate(date: dateCompleted))"
        }
        if !item.completedByName.isEmpty {
            status += " by \(item.completedByName)"
        }

        return status
    }

    func fileSizeText(_ bytes: Int) -> String {
        guard bytes > 0 else { return "0 KB" }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.includesCount = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func fileTypeLabel(_ file: CompanyUserProfileFile) -> String {
        if file.isImage {
            return "Photo"
        }

        let contentType = file.contentType.lowercased()
        if contentType == "application/pdf" {
            return "PDF"
        }
        if contentType.contains("image") {
            return "Photo"
        }

        let fileExtension = URL(fileURLWithPath: file.name).pathExtension.uppercased()
        return fileExtension.isEmpty ? "File" : fileExtension
    }

    var payrollInfoSummaryTitle: String {
        if let companyUser {
            switch companyUser.workerType {
            case .contractor:
                return "Contractor Payroll"
            case .employee:
                return "Employee Payroll"
            case .notAssigned:
                return "Payroll"
            }
        }

        return "Payroll"
    }

    func technicianPayrollInfoCard(
        companyId: String,
        companyUser: CompanyUser
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(payrollInfoSummaryTitle, systemImage: "dollarsign.circle")

            VStack(spacing: 8) {
                NavigationLink {
                    TechnicianPayrollInfoView(
                        companyId: companyId,
                        companyUser: companyUser,
                        dataService: dataService
                    )
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.text.rectangle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(.thinMaterial, in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Payroll Info")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("View pay lines, statements, current rates, and rate history.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                if companyUser.workerType == .contractor {
                    Text("Contractors can use pay statements as invoice-style summaries once approved or paid.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if companyUser.workerType == .employee {
                    Text("Employees can use this page to review approved and paid payroll records.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Assign this team member a worker type before payroll can be calculated reliably.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
