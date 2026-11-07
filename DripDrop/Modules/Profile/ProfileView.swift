//
//  ProfileView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI
import PhotosUI
struct ProfileView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    private let dataService: any ProductionDataServiceProtocol
    
    @StateObject private var profileVM = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    profile
                    if let company = masterDataManager.currentCompany,
                       let user = masterDataManager.user {
                        ProfilePayoutCard(companyId: company.id, technicianId: user.id, dataService: dataService).id(company.id + user.id)
                            .id(company.id + ":" + user.id)
                    }
                    accountInfo
                    selectedCompany
                    if masterDataManager.isFeatureEnabled(.companyUserProfileHistory) {
                        companyUserHistoryLink
                    }
                    personalVehicleLink
                    settingsLink
                }
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
                .padding(16)
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            try? await profileVM.loadCurrentUser()
        }
        .onChange(of: selectedPhoto) { newValue in
            if let user = masterDataManager.user, let newValue {
                profileVM.saveProfileImage(user: user, item: newValue)
            }
        }
    }

}

@MainActor
final class CompanyUserProfileHistoryViewModel: ObservableObject {
    @Published var routes: [ActiveRoute] = []
    @Published var lineItems: [TechnicianPayLineItem] = []
    @Published var statements: [TechnicianPayStatement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let company: Company
    let companyUser: CompanyUser
    let dataService: any ProductionDataServiceProtocol

    init(
        company: Company,
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.company = company
        self.companyUser = companyUser
        self.dataService = dataService
    }

    var totalMiles: Double {
        routes.reduce(0) { $0 + $1.distanceMiles }
    }

    var totalStops: Int {
        routes.reduce(0) { $0 + $1.finishedStops }
    }

    var totalPayCents: Int {
        lineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    var unpaidPayCents: Int {
        lineItems
            .filter { $0.payStatementId == nil && $0.voidedAt == nil }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -180, to: endDate) ?? endDate

            async let routesTask = dataService.getRecentActiveRouteForTech(
                companyId: company.id,
                techId: companyUser.userId,
                days: 180
            )
            async let lineItemsTask = dataService.fetchTechnicianPayLineItems(
                companyId: company.id,
                startDate: startDate,
                endDate: endDate
            )
            async let statementsTask = dataService.fetchTechnicianPayStatements(
                companyId: company.id,
                startDate: startDate,
                endDate: endDate
            )

            let fetchedRoutes = try await routesTask
            let fetchedLineItems = try await lineItemsTask
            let fetchedStatements = try await statementsTask

            routes = Array(
                fetchedRoutes
                    .filter { $0.date < Date().startOfDay() }
                    .sorted { $0.date > $1.date }
                    .prefix(25)
            )
            lineItems = fetchedLineItems.filter {
                $0.technicianId == companyUser.userId
            }
            statements = fetchedStatements.filter {
                $0.technicianId == companyUser.userId
            }
        } catch {
            errorMessage = error.userFacingMessage
        }
    }
}

struct CompanyUserProfileHistoryView: View {
    @StateObject private var viewModel: CompanyUserProfileHistoryViewModel

    init(
        company: Company,
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyUserProfileHistoryViewModel(
                company: company,
                companyUser: companyUser,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryTile(
                        title: "Miles",
                        value: Measurement(value: viewModel.totalMiles, unit: UnitLength.miles)
                            .formatted(.measurement(width: .abbreviated, usage: .road)),
                        systemImage: "road.lanes"
                    )
                    summaryTile(
                        title: "Stops",
                        value: "\(viewModel.totalStops)",
                        systemImage: "checklist.checked"
                    )
                    summaryTile(
                        title: "Work Items",
                        value: "\(viewModel.lineItems.count)",
                        systemImage: "wrench.and.screwdriver"
                    )
                    summaryTile(
                        title: "Unpaid",
                        value: centsCurrency(viewModel.unpaidPayCents),
                        systemImage: "dollarsign.circle"
                    )
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            } header: {
                Text(viewModel.company.name)
            }

            Section("Paysheet") {
                NavigationLink {
                    TechnicianPayrollInfoView(
                        companyId: viewModel.company.id,
                        companyUser: viewModel.companyUser,
                        dataService: viewModel.dataService
                    )
                } label: {
                    HStack {
                        Label("Open Paysheet", systemImage: "doc.text.magnifyingglass")
                        Spacer()
                        Text(centsCurrency(viewModel.totalPayCents))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Recent Routes") {
                if viewModel.isLoading && viewModel.routes.isEmpty {
                    ProgressView()
                } else if viewModel.routes.isEmpty {
                    Text("No recent routes found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.routes) { route in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(route.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(route.status.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                Label(route.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                Label("\(route.finishedStops)/\(route.totalStops)", systemImage: "checkmark.circle")
                                Label(
                                    Measurement(value: route.distanceMiles, unit: UnitLength.miles)
                                        .formatted(.measurement(width: .abbreviated, usage: .road)),
                                    systemImage: "road.lanes"
                                )
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("My Work History")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    func summaryTile(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func centsCurrency(_ cents: Int) -> String {
        (Double(cents) / 100.0).formatted(
            .currency(code: "USD")
            .precision(.fractionLength(2))
        )
    }
}

struct PersonalVehicleDetailView: View {
    @Environment(\.locale) private var locale

    let companyUser: CompanyUser
    let companyName: String?

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    summaryCard
                    accessCard

                    if let personalVehicle {
                        detailsCard(personalVehicle)
                    }

                    Color.clear.frame(height: 18)
                }
                .padding(14)
            }
        }
        .navigationTitle("Personal Vehicle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PersonalVehicleDetailView {
    var personalVehicle: PersonalVehicle? {
        companyUser.personalVehicle
    }

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let personalVehicle {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "car.fill")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(Color.poolBlue)
                        .frame(width: 58, height: 58)
                        .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(personalVehicle.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(personalVehicleDescription(personalVehicle))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        vehicleAccessBadge
                    }

                    Spacer(minLength: 0)
                }

                if !companyUser.canUsePersonalRouteVehicle {
                    warningRow("This personal vehicle is saved, but it is not currently enabled for route use.")
                }
            } else {
                emptyState(
                    title: "No personal vehicle saved.",
                    message: "Personal vehicle details will appear here once they are added.",
                    systemImage: "car"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var accessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Route Access", systemImage: "car.2")

            VStack(spacing: 8) {
                detailRow(
                    title: "Allowed Vehicles",
                    value: routeVehicleAccessLabel(companyUser.normalizedRouteVehicleAccess),
                    systemImage: "car.2"
                )

                detailRow(
                    title: "User",
                    value: companyUser.userName,
                    systemImage: "person"
                )

                if let companyName, !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailRow(
                        title: "Company",
                        value: companyName,
                        systemImage: "building.2"
                    )
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func detailsCard(_ personalVehicle: PersonalVehicle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Vehicle Info", systemImage: "info.circle")

            VStack(spacing: 8) {
                detailRow(title: "Nickname", value: optionalValue(personalVehicle.nickName), systemImage: "tag")
                detailRow(title: "Type", value: optionalValue(personalVehicle.vehicalType), systemImage: "car")
                detailRow(title: "Year", value: optionalValue(personalVehicle.year), systemImage: "calendar")
                detailRow(title: "Make", value: optionalValue(personalVehicle.make), systemImage: "wrench.and.screwdriver")
                detailRow(title: "Model", value: optionalValue(personalVehicle.model), systemImage: "car.side")
                detailRow(title: "Color", value: optionalValue(personalVehicle.color), systemImage: "paintpalette")
                detailRow(title: "Plate", value: optionalValue(personalVehicle.plate), systemImage: "number")
                detailRow(title: "Mileage", value: mileageLabel(personalVehicle.miles), systemImage: "gauge.with.dots.needle.bottom.50percent")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var vehicleAccessBadge: some View {
        let color = companyUser.canUsePersonalRouteVehicle ? Color.poolGreen : Color.orange
        let title = companyUser.canUsePersonalRouteVehicle ? "Route Ready" : "Not Route Enabled"

        return Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.13), in: Capsule())
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

                Text(value.isEmpty ? "Not set" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    func warningRow(_ message: String) -> some View {
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

    func personalVehicleDescription(_ vehicle: PersonalVehicle) -> String {
        let description = [
            vehicle.color,
            vehicle.year,
            vehicle.make,
            vehicle.model,
            vehicle.vehicalType
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " ")

        return description.isEmpty ? "Personal Vehicle" : description
    }

    func optionalValue(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func mileageLabel(_ miles: Double?) -> String {
        guard let miles else {
            return ""
        }

        return Measurement(value: miles, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))
    }
}

#Preview {
    ProfileView(dataService: MockDataService())
        .environmentObject(NavigationStateManager())
        .environmentObject(MasterDataManager(dataService: ProductionDataService()))
        .environmentObject(ProductionDataService())
}

private extension ProfileView {
    @MainActor var profile: some View {
        let savedPhotoURL = profileVM.imageUrlString
        let currentUserPhotoURL = masterDataManager.user?.photoUrl
        let photoURL = URL(string: savedPhotoURL ?? currentUserPhotoURL ?? "")
        return HStack(alignment: .center, spacing: 16) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: photoURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Text(initials).font(.title2.weight(.bold)).foregroundStyle(Color.poolBlue)
                                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.white)
                        }
                    }
                    .frame(width: 72, height: 72).clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 3))
                    Image(systemName: "camera.fill").font(.caption2).padding(6)
                        .background(Color.white, in: Circle()).foregroundStyle(Color.poolBlue)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change profile photo")
            VStack(alignment: .leading, spacing: 5) {
                Text("MY PROFILE").font(.caption2.weight(.bold)).tracking(1.5).foregroundStyle(.white.opacity(0.75))
                Text("\(masterDataManager.user?.firstName ?? "") \(masterDataManager.user?.lastName ?? "")")
                    .font(.title2.weight(.bold)).foregroundStyle(.white)
                Text(masterDataManager.user?.email ?? "").font(.caption).foregroundStyle(.white.opacity(0.85))
                    .textSelection(.enabled)
                if let user = masterDataManager.user {
                    Label("Level \(calculateLevel(exp: user.exp).level)", systemImage: "sparkles")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(red: 14/255, green: 36/255, blue: 92/255), in: RoundedRectangle(cornerRadius: 8))
    }

    var initials: String {
        [masterDataManager.user?.firstName, masterDataManager.user?.lastName]
            .compactMap { $0?.first.map(String.init) }.joined().uppercased()
    }

    var accountInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                profileHeading("Account Info", systemImage: "person.crop.circle")
                Spacer(minLength: 8)
                if let user = masterDataManager.user {
                    NavigationLink(value: Route.editUser(user: user, dataService: dataService)) {
                        Text("Edit Profile").font(.caption.weight(.semibold))
                    }
                    .buttonStyle(WorkspaceOutlinedButtonStyle())
                }
            }
            if let user = masterDataManager.user {
                VStack(spacing: 12) {
                    profileDetail("Name", value: "\(user.firstName) \(user.lastName)")
                    Divider()
                    profileDetail("Email", value: user.email)
                    Divider()
                    profileDetail("Phone", value: user.phoneNumber ?? "")
                    Divider()
                    if let dateCreated = user.dateCreated {
                        profileDetail("Member Since", value: dateCreated.formatted(date: .abbreviated, time: .omitted))
                        Divider()
                    }
                    profileDetail("Bio", value: user.bio ?? "")
                }
            }
        }
        .profileCard()
    }

    var selectedCompany: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                profileHeading("Selected Company", systemImage: "building.2")
                Spacer(minLength: 8)
                NavigationLink(value: Route.userSettings(dataService: dataService)) {
                    Text("Change").font(.caption.weight(.semibold))
                }
                .buttonStyle(WorkspaceOutlinedButtonStyle())
            }
            if let company = masterDataManager.currentCompany {
                VStack(spacing: 12) {
                    profileDetail("Company", value: company.name)
                    if let companyUser = masterDataManager.companyUser {
                        Divider()
                        profileDetail("Role", value: companyUser.roleName)
                        Divider()
                        profileDetail("Worker Type", value: companyUser.workerType.rawValue)
                        Divider()
                        profileDetail("Status", value: companyUser.status.rawValue)
                    }
                    Divider()
                    profileDetail("Company Email", value: company.email)
                    Divider()
                    profileDetail("Company Phone", value: company.phoneNumber)
                }
            } else {
                Text("Select a company to see your work history and paysheet.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .profileCard()
    }

    @ViewBuilder var companyUserHistoryLink: some View {
        if let company = masterDataManager.currentCompany, let companyUser = masterDataManager.companyUser {
            NavigationLink {
                CompanyUserProfileHistoryView(company: company, companyUser: companyUser, dataService: dataService)
            } label: {
                profileNavigationRow("My Work History", subtitle: "Past routes, mileage, and completed stops", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder var personalVehicleLink: some View {
        if let companyUser = masterDataManager.companyUser {
            NavigationLink {
                PersonalVehicleDetailView(companyUser: companyUser, companyName: masterDataManager.currentCompany?.name)
            } label: {
                profileNavigationRow("Personal Vehicle", subtitle: companyUser.personalVehicle?.displayName ?? "No personal vehicle saved", systemImage: "car")
            }
            .buttonStyle(.plain)
        }
    }

    var settingsLink: some View {
        NavigationLink(value: Route.userSettings(dataService: dataService)) {
            profileNavigationRow("Settings", subtitle: "Account security and preferences", systemImage: "gearshape")
        }
        .buttonStyle(.plain)
    }

    func profileNavigationRow(_ title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                profileHeading(title, systemImage: systemImage)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }
        .profileCard()
    }

    func profileDetail(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title).font(.caption).foregroundStyle(.secondary).frame(width: 94, alignment: .leading)
            Text(value.isEmpty ? "Not set" : value).font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
        }
    }
}

private func profileHeading(_ title: String, systemImage: String) -> some View {
    Label {
        Text(title).font(.headline)
    } icon: {
        Image(systemName: systemImage).font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.poolBlue).frame(width: 32, height: 32)
            .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }
    .foregroundStyle(.primary)
}

private extension View {
    func profileCard() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

private struct ProfilePayoutCard: View {
    let companyId: String
    let technicianId: String
    let dataService: any ProductionDataServiceProtocol
    @StateObject private var model = OwnPaysheetModel()
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            profileHeading("Payout Snapshot", systemImage: "wallet.pass")
            Text(model.sheet.map { "Last 30 days · " + $0.periodLabel } ?? "Last 30 days").font(.caption).foregroundStyle(.secondary)
            if let error = model.error {
                Text("Pay is unavailable. " + error).font(.caption).foregroundStyle(.red)
                Button("Try Again") { Task { await load() } }.buttonStyle(WorkspaceOutlinedButtonStyle())
            } else {
                OwnPayTotalsView(summary: model.sheet?.summary)
                if let sheet = model.sheet {
                    OwnOlderPayNotice(sheet: sheet)
                    if sheet.summary.reviewCount > 0 { Text("\(sheet.summary.reviewCount) \(sheet.summary.reviewCount == 1 ? "pay item needs" : "pay items need") review.").font(.caption).foregroundStyle(.orange) }
                }
            }
            NavigationLink {
                TechnicianPaysheetView(companyId: companyId).id(companyId + technicianId)
            } label: {
                Text("Open Paysheet").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 32)
            }.buttonStyle(WorkspaceOutlinedButtonStyle())
        }.profileCard().task(id: companyId + technicianId) { await load() }
    }
    @MainActor private func load() async { await model.load(companyId: companyId, summary: true) }
}

private struct ProfilePayoutDetails: View {
    let snapshot: ProfilePayoutSnapshot
    let isLoading: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPaid = false
    @State private var expanded = false
    private var items: [ProfilePayoutWork] { showPaid ? snapshot.paidItems : snapshot.unpaidItems }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            metric("Still to be paid", value: isLoading ? "—" : profilePayoutMoney(snapshot.owedCents), helper: "Calculated pay awaiting payment", tone: .emerald, prominent: true)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 8) { secondaryMetrics }
                VStack(spacing: 8) { secondaryMetrics }
            }
            if !isLoading {
                if snapshot.reviewCount > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(snapshot.reviewCount) \(snapshot.reviewCount == 1 ? "pay item needs" : "pay items need") review", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.weight(.semibold))
                        Text("These amounts are pending and are excluded from the unpaid total.").font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .foregroundStyle(WorkspaceTone.amber.foreground(in: colorScheme))
                    .background(WorkspaceTone.amber.background(in: colorScheme), in: RoundedRectangle(cornerRadius: 8))
                }
                Text("Work & pay").font(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { filters }
                    VStack(spacing: 8) { filters }
                }
                if items.isEmpty {
                    Text(showPaid ? "No work marked paid in this period." : "No unpaid pay recorded in this period.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(expanded ? items : Array(items.prefix(5))) { item in
                        Divider()
                        workRow(item)
                    }
                    if items.count > 5 {
                        Button(expanded ? "Show fewer" : "Show all \(items.count) \(showPaid ? "paid" : "unpaid") items") { expanded.toggle() }
                            .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .slate))
                    }
                }
                Text("$0 pay items are hidden. Missing work or pay? Use Pay Requests to ask for a correction.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private var filters: some View {
        Button { showPaid = false; expanded = false } label: {
            Text("Unpaid (\(snapshot.unpaidItems.count))").fixedSize().frame(maxWidth: .infinity)
        }
        .buttonStyle(WorkspaceOutlinedButtonStyle(tone: showPaid ? .slate : .blue))
        .accessibilityAddTraits(showPaid ? [] : .isSelected)
        Button { showPaid = true; expanded = false } label: {
            Text("Paid (\(snapshot.paidItems.count))").fixedSize().frame(maxWidth: .infinity)
        }
        .buttonStyle(WorkspaceOutlinedButtonStyle(tone: showPaid ? .emerald : .slate))
        .accessibilityAddTraits(showPaid ? .isSelected : [])
    }

    @ViewBuilder private var secondaryMetrics: some View {
        metric("Marked paid", value: isLoading ? "—" : profilePayoutMoney(snapshot.paidCents), helper: "For work in this period", tone: .blue)
        metric("Last payout", value: isLoading ? "—" : snapshot.lastPayoutDate?.formatted(date: .abbreviated, time: .omitted) ?? "None recorded", helper: nil, tone: .slate)
    }

    private func metric(_ title: String, value: String, helper: String?, tone: WorkspaceTone, prominent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Text(value).font(prominent ? .title.weight(.bold) : .headline.weight(.bold))
                .foregroundStyle(tone.foreground(in: colorScheme)).fixedSize(horizontal: false, vertical: true)
            if let helper { Text(helper).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(tone.background(in: colorScheme), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(tone.border(in: colorScheme), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func workRow(_ item: ProfilePayoutWork) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title).font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
            Text(item.completedDate.formatted(date: .abbreviated, time: .omitted) + (item.customer.isEmpty ? "" : " · " + item.customer))
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if !item.needsReview && !item.rateDescription.isEmpty {
                Text(item.rateDescription).font(.caption).foregroundStyle(.secondary)
            }
            if item.isPaid, let paidDate = item.paidDate {
                Text("Paid \(paidDate.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack { workAmount(item); Spacer(); workStatus(item) }
                VStack(alignment: .leading, spacing: 6) { workAmount(item); workStatus(item) }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func workAmount(_ item: ProfilePayoutWork) -> some View {
        Text(item.needsReview ? "Pending" : profilePayoutMoney(item.amountCents))
            .font(.headline).monospacedDigit()
    }

    private func workStatus(_ item: ProfilePayoutWork) -> some View {
        let tone: WorkspaceTone = item.isPaid ? .emerald : item.needsReview ? .amber : .slate
        return Text(item.statusLabel).font(.caption.weight(.semibold))
            .foregroundStyle(tone.foreground(in: colorScheme)).padding(.horizontal, 8).padding(.vertical, 4)
            .background(tone.background(in: colorScheme), in: RoundedRectangle(cornerRadius: 6))
    }
}

private func profilePayoutMoney(_ cents: Int) -> String {
    (Double(cents) / 100).formatted(.currency(code: "USD"))
}

private struct ProfilePayoutWork: Identifiable {
    let lineItem: TechnicianPayLineItem
    let isPaid: Bool
    var id: String { lineItem.id }
    var amountCents: Int { lineItem.totalAmountCents }
    var completedDate: Date { lineItem.completedDate }
    var paidDate: Date? { lineItem.paidAt }
    var needsReview: Bool { !isPaid && [.pending, .needsReview].contains(lineItem.calculationStatus) }
    var title: String {
        firstText([lineItem.taskName, lineItem.workTypeName, lineItem.serviceStopTypeName, lineItem.displayTitle], fallback: "Completed work")
    }
    var customer: String {
        firstText([lineItem.customerName, lineItem.serviceLocationAddress, lineItem.displaySubtitle])
    }
    var statusLabel: String {
        isPaid ? "Marked paid" : needsReview ? "Pay needs review" : lineItem.calculationStatus == .approved ? "Approved · unpaid" : "Unpaid"
    }
    var rateDescription: String {
        if lineItem.source == .manualAdjustment { return "Pay adjustment" }
        if lineItem.rateType == .manual { return "Custom pay" }
        if lineItem.rateType == .percentage { return "\((Double(lineItem.rateAmountCents) / 100).formatted())% rate" }
        guard lineItem.quantity != 0, lineItem.rateAmountCents != 0 else { return "" }
        let hourly = lineItem.rateType == .hourly
        let quantity = hourly && lineItem.quantityUnit == .minutes ? lineItem.quantity / 60 : lineItem.quantity
        let unit: String
        switch lineItem.quantityUnit {
        case .each, .percent: unit = ""
        case .hours: unit = " hr"
        case .minutes: unit = hourly ? " hr" : " min"
        case .bodyOfWater: unit = " pool/spa"
        case .serviceLocation: unit = " location"
        }
        return "\(quantity.formatted(.number.precision(.fractionLength(0...2))))\(unit) × \(profilePayoutMoney(lineItem.rateAmountCents))\(hourly ? "/hr" : "")"
    }

    private func firstText(_ values: [String?], fallback: String = "") -> String {
        values.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty } ?? fallback
    }
}

private struct ProfilePayoutSnapshot {
    let unpaidItems: [ProfilePayoutWork]
    let paidItems: [ProfilePayoutWork]
    let lastPayoutDate: Date?
    var owedCents: Int { unpaidItems.filter { !$0.needsReview }.reduce(0) { $0 + $1.amountCents } }
    var paidCents: Int { paidItems.reduce(0) { $0 + $1.amountCents } }
    var reviewCount: Int { unpaidItems.filter(\.needsReview).count }
    static let empty = ProfilePayoutSnapshot(lineItems: [], statements: [])

    init(lineItems: [TechnicianPayLineItem], statements: [TechnicianPayStatement]) {
        let paidStatements = statements.filter { $0.status != .voided && ($0.status == .paid || $0.paidAt != nil) }
        let paidStatementIds = Set(paidStatements.map(\.id))
        let paidLineIds = Set(paidStatements.flatMap(\.lineItemIds))
        let activeItems = lineItems.filter { $0.voidedAt == nil && $0.calculationStatus != .voided }
        let items = activeItems.map { item in
            ProfilePayoutWork(lineItem: item, isPaid: item.paidAt != nil || item.calculationStatus == .paid || paidStatementIds.contains(item.payStatementId ?? "") || paidLineIds.contains(item.id))
        }.filter { $0.amountCents != 0 || $0.needsReview }.sorted {
            if $0.needsReview != $1.needsReview { return $0.needsReview }
            if $0.completedDate != $1.completedDate { return $0.completedDate > $1.completedDate }
            return $0.id < $1.id
        }
        unpaidItems = items.filter { !$0.isPaid }
        paidItems = items.filter(\.isPaid)
        lastPayoutDate = (activeItems.compactMap(\.paidAt) + paidStatements.map { $0.paidAt ?? $0.endDate }).max()
    }
}
