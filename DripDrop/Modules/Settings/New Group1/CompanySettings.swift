    //
    //  CompanySettings.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 4/25/24.
    //

    import Foundation
    import SwiftUI
    import StripePaymentSheet
    import FirebaseFunctions

    @MainActor
    final class CompanySettingsViewModel: ObservableObject {
        let dataService: any ProductionDataServiceProtocol

        init(dataService: any ProductionDataServiceProtocol) {
            self.dataService = dataService
        }

        @Published private(set) var externalAccountLink: URL? = nil
        @Published private(set) var totalActiveCustomers: Float = 1
        @Published private(set) var currentActiveCustomers: Float = 0

        func onLoad() {
            Task {
                do {
                    self.totalActiveCustomers = 50
                    self.currentActiveCustomers = 25
                } catch {
                    print(error)
                }
            }
        }

        func setUpStripeAccount(company: Company, user: DBUser) {
            Task {
                do {
                    guard let stripeConnectAccountId = company.stripeConnectAccountId, !stripeConnectAccountId.isEmpty else {
                        return
                    }

                    print("--createStripeAccountLink--")

                    let data: [String: Any] = [
                        "companyId": company.id,
                        "accountId": stripeConnectAccountId,
                        "stripeVersion": "2023-10-16",
                    ]

                    let result = try await Functions.functions().httpsCallable("createStripeAccountLink").call(data)

                    guard let json = result.data as? [String: Any] else {
                        print("Failed to Parse JSON")
                        return
                    }

                    guard let accountLink = json["accountLink"] as? String else {
                        print("Failed to Get Account Link")
                        return
                    }

                    guard let url = URL(string: accountLink) else {
                        print("Failed to Make URL")
                        return
                    }

                    self.externalAccountLink = url
                } catch {
                    print(error)
                }
            }
        }
        func basicPayRollSettingsSetUp(companyId:String){
            Task{
                do {
                    try await dataService.ensureCompanyPaySettings(companyId: companyId)
                    
                } catch {
                    print(error)
                }
            }
        }
    }

    struct CompanySettings: View {
        init(dataService: any ProductionDataServiceProtocol) {
            _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
            _AuthVM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
            _VM = StateObject(wrappedValue: CompanySettingsViewModel(dataService: dataService))
        }

        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var customerViewModel: CustomerViewModel

        @StateObject private var VM: CompanySettingsViewModel
        @StateObject private var AuthVM: AuthenticationViewModel
        @StateObject private var companyVM = CompanyViewModel()
        @StateObject private var userAccessVM = UserAccessViewModel()
        @StateObject private var customerVM: CustomerViewModel
        @StateObject var roleVM = RoleViewModel()

        @State var company: Company = Company(
            id: "",
            ownerId: "",
            ownerName: "",
            name: "",
            photoUrl: "",
            dateCreated: Date(),
            email: "",
            phoneNumber: "",
            verified: false,
            serviceZipCodes: [],
            services: [],
            accountType: .free,
            paidUntil: Date(),
            status: .free,
            stripeConnectAccountStatus: .notStarted,
            yelpURL: "",
            websiteURL: ""
        )

        @State var companyIdList: [Company] = []
        @State var showChangeEmailScreen: Bool = false
        @State var isLoading = false

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard

                        if companyIdList.count > 1 {
                            companySwitcherCard
                        }

                        displayPrefrences

                        settings

                        #if DEBUG
                        debugCard
                        #endif
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .foregroundStyle(Color.basicFontText)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    if let user = masterDataManager.user {
                        print("\(user.id)")
                        try await companyVM.getCompaniesByUserAccessList(userId: user.id)
                        print("Success")
                    } else {
                        masterDataManager.showSignInView = true
                    }

                    if companyVM.listOfCompanies.count != 0 {
                        if let selectedCompany = masterDataManager.currentCompany {
                            company = companyVM.listOfCompanies.first(where: { $0.id == selectedCompany.id }) ?? selectedCompany
                            VM.onLoad()
                        }

                        companyIdList = companyVM.listOfCompanies
                    }
                } catch {
                    print("Failed to get User Access List - Page: Settings View")
                }
            }
            .onChange(of: company) { change in
                Task {
                    if let selectedCompany = masterDataManager.currentCompany,
                       let user = masterDataManager.user {
                        if change.id != "" && selectedCompany.id != change.id {
                            masterDataManager.currentCompany = change

                            try await userAccessVM.getUserAccessCompanies(
                                userId: user.id,
                                companyId: company.id
                            )

                            if let access = userAccessVM.userAccess {
                                print("Mobile Home Access >> \(access)")

                                try await roleVM.getSpecificRole(
                                    companyId: company.id,
                                    roleId: access.roleId
                                )

                                if let role = roleVM.role {
                                    masterDataManager.role = role
                                } else {
                                    masterDataManager.showSignInView = true
                                }
                            } else {
                                masterDataManager.showSignInView = true
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Main Sections

    extension CompanySettings {

        var headerCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    companyImage

                    VStack(alignment: .leading, spacing: 5) {
                        Text(company.name.isEmpty ? "Company Settings" : company.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(company.email.isEmpty ? "Manage company preferences, billing, permissions, and setup." : company.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    statusBadge

                    Label(company.accountType.rawValue, systemImage: "creditcard")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())

                    if company.verified {
                        Label("Verified", systemImage: "checkmark.seal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.poolGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.poolGreen.opacity(0.12), in: Capsule())
                    }

                    Spacer()
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var companyImage: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 58, height: 58)

                if let photoUrl = company.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } placeholder: {
                        Image(systemName: "building.2")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                } else {
                    Image(systemName: "building.2")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }

        var statusBadge: some View {
            Text(company.status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(statusColor.opacity(0.12), in: Capsule())
        }

        var statusColor: Color {
            switch company.status {
            case .free:
                return .secondary
            case .paid:
                return Color.poolGreen
            case .unpaid:
                return .red
            default:
                return .secondary
            }
        }

        var companySwitcherCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Current Company", systemImage: "building.2")

                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: Circle())

                    Picker("Company", selection: $company) {
                        ForEach(companyIdList) { company in
                            Text(company.name).tag(company)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }

        var displayPrefrences: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Display Preferences", systemImage: "paintbrush")

                HStack(spacing: 12) {
                    Image(systemName: "rectangle.grid.1x2")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Main Screen Type")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker("Main Screen Type", selection: $masterDataManager.mainScreenDisplayType) {
                            ForEach(MainScreenDisplayType.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }

        var settings: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Company Settings", systemImage: "gearshape")

                if UIDevice.isIPhone {
                    if let role = masterDataManager.role {
                        VStack(spacing: 14) {
                            if role.permissionIdList.contains("890") {
                                settingsSection(
                                    title: "General",
                                    systemImage: "slider.horizontal.3"
                                ) {
                                    if role.permissionIdList.contains("890") {
                                        NavigationLink(value: Route.manageSubscriptions(dataService: dataService)) {
                                            settingsRow(
                                                title: "Manage Subscriptions",
                                                subtitle: "View or update your company plan.",
                                                systemImage: "creditcard"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            if role.permissionIdList.contains(where: ["810", "830", "870"].contains) {
                                settingsSection(
                                    title: "Company",
                                    systemImage: "building.2"
                                ) {
                                    if role.permissionIdList.contains("810") {
                                        NavigationLink(value: Route.companyInfo(dataService: dataService)) {
                                            settingsRow(
                                                title: "Company Information",
                                                subtitle: "Profile, contact, and public company details.",
                                                systemImage: "info.circle"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    if role.permissionIdList.contains("830") {
                                        NavigationLink(value: Route.emailConfiguration(dataService: dataService)) {
                                            settingsRow(
                                                title: "Email Configuration",
                                                subtitle: "Configure outbound email settings.",
                                                systemImage: "envelope"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if role.permissionIdList.contains("870") {
                                        NavigationLink(value: Route.reports(dataService: dataService)) {
                                            settingsRow(
                                                title: "Reports",
                                                subtitle: "View operational and company reports.",
                                                systemImage: "chart.bar"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            if role.permissionIdList.contains(where: [ "820","840", "850", "860"].contains) {
                                settingsSection(
                                    title: "Operations",
                                    systemImage: "building.2"
                                ) {
                                    if role.permissionIdList.contains("820") {
                                        NavigationLink(value: Route.taskGroups(dataService: dataService)) {
                                            settingsRow(
                                                title: "Task Groups",
                                                subtitle: "Manage reusable task templates.",
                                                systemImage: "checklist"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if role.permissionIdList.contains("840") {
                                        NavigationLink(value: Route.readingsAndDosages(dataService: dataService)) {
                                            settingsRow(
                                                title: "Readings And Dosages",
                                                subtitle: "Set up chemistry readings and dosage presets.",
                                                systemImage: "drop"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if role.permissionIdList.contains("850") {
                                        NavigationLink(value: Route.databaseItems(dataService: dataService)) {
                                            settingsRow(
                                                title: "Data Base",
                                                subtitle: "Manage inventory, parts, chemicals, and items.",
                                                systemImage: "shippingbox"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if role.permissionIdList.contains("860") {
                                        NavigationLink(value: Route.userRoles(dataService: dataService)) {
                                            settingsRow(
                                                title: "User Roles",
                                                subtitle: "Edit permissions and access levels.",
                                                systemImage: "person.badge.key"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    NavigationLink(value: Route.jobTemplates(dataService: dataService)) {
                                        settingsRow(
                                            title: "Job Templates",
                                            subtitle: "Reuseable Jobs Templates",
                                            systemImage: "info.circle"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    

                                }
                            }
                            if role.permissionIdList.contains("880") {
                                settingsSection(
                                    title: "Billing",
                                    systemImage: "doc.text"
                                ) {
                                    if role.permissionIdList.contains("880") {
                                        NavigationLink(value: Route.manageTermsTemplates(dataService: dataService)) {
                                            settingsRow(
                                                title: "Terms Templates",
                                                subtitle: "Manage invoice and estimate terms.",
                                                systemImage: "doc.text"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            if role.permissionIdList.contains("420") {
                                settingsSection(
                                    title: "Pay Roll",
                                    systemImage: "doc.text"
                                ) {
                                    NavigationLink(value: Route.payRollSettings(dataService: dataService)) {
                                        settingsRow(
                                            title: "Pay Roll Settings",
                                            subtitle: "Manage payroll settings and pay information.",
                                            systemImage: "doc.text"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        emptyState(
                            title: "No role loaded.",
                            message: "Settings will appear after your role permissions are loaded.",
                            systemImage: "person.badge.key"
                        )
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }

        #if DEBUG
        var debugCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Debug", systemImage: "ladybug")

                TestDataView()
                Button(action: {
                    if let currentCompany = masterDataManager.currentCompany {
                        VM.basicPayRollSettingsSetUp(companyId: currentCompany.id)
                    }
                }, label: {
                    Text("Set up basic Payroll Settings")
                        .modifier(BlueButtonModifier())
                })
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
        #endif
    }

    // MARK: - Reusable UI

    extension CompanySettings {

        func settingsSection<Content: View>(
            title: String,
            systemImage: String,
            @ViewBuilder content: () -> Content
        ) -> some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()
                }

                VStack(spacing: 8) {
                    content()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }

        func settingsRow(
            title: String,
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
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.background.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }

        func emptyState(
            title: String,
            message: String,
            systemImage: String
        ) -> some View {
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
    }
