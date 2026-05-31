    //
    //  CompanyUserDetailView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 1/21/24.
    //

import SwiftUI
import Foundation
@MainActor
final class CompanyUserDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var screens: [String] = ["Info","Work","Money","Review"]
    @Published var selectedScreen: String = "Info"
    
    @Published private(set) var acceptedInviteList: [Invite] = []
    
    @Published private(set) var pendingInviteList: [Invite] = []
    
    @Published private(set) var companyUsers: [CompanyUser] = []
    
    @Published private(set) var recentServiceStops: [ServiceStop] = []
    @Published private(set) var recentJobsCount: Int = 0
    @Published private(set) var specificTech: DBUser? = nil
    @Published private(set) var role: Role? = nil
    @Published var performaceHistoryList:[PerformaceHistory] = []
    func onLoad(companyId:String,companyUser:CompanyUser) async throws{
        self.specificTech = try await dataService.getOneUser(userId: companyUser.userId)
        self.role = try await dataService.getSpecificRole(companyId: companyId, roleId: companyUser.roleId)
        self.performaceHistoryList = MockDataService.mockPerformaceHistory

        self.recentServiceStops = try await dataService.getAllServiceStopsBetweenDateByUserId(companyId: companyUser.userId, startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, endDate: Date(), userId: companyUser.userId)
    }
    func getPerformaceReivewByUserId(companyId:String,companyUserId:String) async throws {
        self.performaceHistoryList = MockDataService.mockPerformaceHistory
    }
    func getOneTech(techId: String) async throws{
        self.specificTech = try await dataService.getOneUser(userId: techId)
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
        case "Info":
            VStack(spacing: 14) {
                personalInfoCard
                companyInfoCard
                overviewCard
            }

        case "Work":
            recentActivityCard
            
            if let companyUser {
                if companyUser.workerType == .employee {
                    hoursWorkedCard
                }
            }

        case "Money":
            if let companyUser,
               let currentCompany = masterDataManager.currentCompany {
                technicianPayrollInfoCard(
                    companyId: currentCompany.id,
                    companyUser: companyUser
                )
            } else {
                emptyState(
                    title: "Payroll unavailable.",
                    message: "Select a company and team member to view payroll.",
                    systemImage: "dollarsign.circle"
                )
            }
            
        case "Review":
            performanceHistoryCard

        default:
            VStack(spacing: 14) {
                personalInfoCard
                companyInfoCard
                overviewCard
            }
        }
    }
}

// MARK: - Info

extension CompanyUserDetailView {

    var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Personal Info", systemImage: "person.text.rectangle")

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
                sectionHeader("Company Info", systemImage: "building.2")

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

    @ViewBuilder
    var roleDetailsButton: some View {
        if let companyUser {
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

// MARK: - Work

extension CompanyUserDetailView {
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
            sectionHeader("Recent Activity", systemImage: "clock.arrow.circlepath")

            VStack(spacing: 8) {
                activitySummaryRow(
                    title: "Service Stops",
                    value: "\(VM.recentServiceStops.count)",
                    subtitle: "Completed or assigned service stops",
                    systemImage: "mappin.and.ellipse"
                )

                activitySummaryRow(
                    title: "Jobs - IP",
                    value: "\(VM.recentJobsCount)",
                    subtitle: "Filter cleans and job work",
                    systemImage: "briefcase"
                )

                activitySummaryRow(
                    title: "Recently Purchased - IP",
                    value: "34 Items",
                    subtitle: "Total: $3,465",
                    systemImage: "cart"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                    .sheet(isPresented: $showNewPerformaceHistory) {
                        AddNewPerformanceHistory(dataService: dataService, companyUser: companyUser)
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
