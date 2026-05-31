//
//  Managment.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI
import MapKit
import Firebase
import Charts

struct Managment: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: MyCompanyViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: MyCompanyViewModel(dataService: dataService))
    }

    @State private var showOperations: Bool = false
    @State private var showFinance: Bool = false
    @State private var showManagement: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    if let role = masterDataManager.role {
                        if role.permissionIdList.contains("200") {
                            managementOverview
                        } else {
                            emptyState(
                                title: "No management access.",
                                message: "Your role does not currently include management permissions.",
                                systemImage: "lock.shield"
                            )
                        }
                    } else {
                        emptyState(
                            title: "Loading role.",
                            message: "Management tools will appear after your role permissions load.",
                            systemImage: "person.badge.key"
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

//            if isLoading {
//                loadingOverlay
//            }
        }
        .onAppear {
            if !UIDevice.isIPhone {
                showOperations = true
                showFinance = true
                showManagement = true
            }
        }
        .task {
            await loadManagement()
        }
        .onChange(of: masterDataManager.currentCompany) { _ in
            Task {
                await loadManagement()
            }
        }
        .onChange(of: VM.isLoading) { loading in
            if loading {
                isLoading = loading
            } else {
                withAnimation(.linear(duration: 0.1)) {
                    isLoading = loading
                }
            }
        }
    }

    private func loadManagement() async {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            return
        }

        do {
            try await VM.onLoad(
                companyId: company.id,
                userId: user.id,
                category: "Management"
            )
        } catch {
            print("[Managment][loadManagement]")
            print(error)
        }
    }
}

// MARK: - Main Sections

extension Managment {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: "person.3.sequence")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Management")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(masterDataManager.currentCompany?.name ?? "Manage routes, directory, fleet, vendors, businesses, and company resources.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label(masterDataManager.mainScreenDisplayType.rawValue, systemImage: "rectangle.grid.1x2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                if let role = masterDataManager.role {
                    Label("\(role.permissionIdList.count) Permissions", systemImage: "lock.shield")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
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

    var managementOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Management Overview", systemImage: "slider.horizontal.3")
                Spacer()
            }

            if let role = masterDataManager.role {
                if role.permissionIdList.contains("210") {
                    internalRoutes
                    routeOverview
                }
                
                if role.permissionIdList.contains("260") {
                    users
                }

                if role.permissionIdList.contains("290") {
                    fleet
                }
                
                /*
                 Roll these back in when ready:
                 routeBuilder
                 routeOverview
                 externalRoutes
                 businesses
                 vendors
                 payroll
                 routeSandbox
                */
            }
        }
    }

    var snapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Snapshot", systemImage: "chart.bar")

            Chart(VM.buildActivities) { buildActivity in
                BarMark(
                    x: .value("Date", buildActivity.date, unit: .month),
                    y: .value("Total Count", buildActivity.numberOfUnits)
                )
                .foregroundStyle(by: .value("Name", buildActivity.name))
            }
            .chartForegroundStyleScale([
                "Customers": .blue,
                "Technicians": .orange
            ])
            .frame(height: 220)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Management Cards

extension Managment {

    var internalRoutes: some View {
        managementCard(
            title: "Planned Routes",
            subtitle: "Review internal route assignments and route teams.",
            systemImage: "map",
            countText: VM.companyUsers.isEmpty ? nil : "\(VM.companyUsers.count)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.routes(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .companyRouteOverView
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if VM.companyUsers.isEmpty {
                        statRow(
                            title: "Route Users",
                            value: "0",
                            systemImage: "person.3"
                        )
                    } else {
                        ForEach(VM.companyUsers.prefix(6)) { user in
                            statRow(
                                title: user.userName,
                                value: user.roleName,
                                systemImage: "person.crop.circle"
                            )
                        }
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    usersPreview(
                        emptyTitle: "No Route Users",
                        emptyImage: "map"
                    )
                }
            }
        )
    }

    var users: some View {
        managementCard(
            title: "Directory",
            subtitle: "Company users, roles, technicians, employees, and contractors.",
            systemImage: "person.3",
            countText: VM.totalUSers == nil ? nil : "\(VM.totalUSers ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.users(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .users
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let total = VM.totalUSers {
                        statRow(
                            title: "Total Users",
                            value: "\(total)",
                            systemImage: "person.3"
                        )
                    }

                    ForEach(Array(VM.techsByRoles.keys), id: \.self) { key in
                        if let count = VM.techsByRoles[key],
                           count != 0 {
                            statRow(
                                title: key.name,
                                value: "\(count)",
                                systemImage: "person.badge.key"
                            )
                        }
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    usersPreview(
                        emptyTitle: "No Users",
                        emptyImage: "person.slash"
                    )
                }
            }
        )
    }

    var fleet: some View {
        managementCard(
            title: "Fleet",
            subtitle: "Company vehicles, assigned drivers, and fleet resources.",
            systemImage: "car.fill",
            countText: VM.vehicalCount == nil ? nil : "\(VM.vehicalCount ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.fleet(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .fleet
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.vehicalCount {
                        statRow(
                            title: "Vehicles",
                            value: "\(count)",
                            systemImage: "car.fill"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.listOfVehicals.isEmpty {
                        emptyPreviewTile("No Vehicles", systemImage: "car")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.listOfVehicals) { vehicle in
                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.vehicalDetailView(
                                            vehical: vehicle,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: vehicle.nickName,
                                            subtitle: "",
                                            systemImage: "car.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedVehical = vehicle
                                        navigationManager.routes.append(
                                            Route.vehicalDetailView(
                                                vehical: vehicle,
                                                dataService: dataService
                                            )
                                        )
                                    } label: {
                                        previewTile(
                                            title: vehicle.nickName,
                                            subtitle: "",
                                            systemImage: "car.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    var vendors: some View {
        managementCard(
            title: "Vendors",
            subtitle: "Vendor records for parts, chemicals, equipment, and services.",
            systemImage: "building.2",
            countText: VM.venderCount == nil ? nil : "\(VM.venderCount ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.venders(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .vender
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.venderCount {
                        statRow(
                            title: "Vendors",
                            value: "\(count)",
                            systemImage: "building.2"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.listOfVenders.isEmpty {
                        emptyPreviewTile("No Vendors", systemImage: "building.2")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.listOfVenders) { vendor in
                                let name = vendor.name ?? "Vendor"

                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.vender(
                                            vender: vendor,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: name,
                                            subtitle: "",
                                            systemImage: "building.2"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        navigationManager.routes.append(
                                            Route.vender(
                                                vender: vendor,
                                                dataService: dataService
                                            )
                                        )
                                    } label: {
                                        previewTile(
                                            title: name,
                                            subtitle: "",
                                            systemImage: "building.2"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    var businesses: some View {
        managementCard(
            title: "Businesses",
            subtitle: "Partner businesses and B2B relationships.",
            systemImage: "building.columns",
            countText: VM.businesses.isEmpty ? nil : "\(VM.businesses.count)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.businesses(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .businesses
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    statRow(
                        title: "Businesses",
                        value: "\(VM.businesses.count)",
                        systemImage: "building.columns"
                    )
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.businesses.isEmpty {
                        emptyPreviewTile("No Businesses", systemImage: "building.columns")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.businesses) { business in
                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.business(
                                            business: business,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: business.companyName,
                                            subtitle: "",
                                            systemImage: "building.columns"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedCategory = .businesses
                                        masterDataManager.selectedBuisness = business
                                    } label: {
                                        previewTile(
                                            title: business.companyName,
                                            subtitle: "",
                                            systemImage: "building.columns"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }
}

// MARK: - Optional / Future Cards

extension Managment {

    var routeBuilder: some View {
        managementCard(
            title: "Live Route Management",
            subtitle: "Build, review, and manage live service routes.",
            systemImage: "point.topleft.down.curvedto.point.bottomright.up",
            countText: VM.daysAndRoutes.isEmpty ? nil : "\(VM.daysAndRoutes.count)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.routeBuilder(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .routeBuilder
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if VM.daysAndRoutes.isEmpty {
                        statRow(title: "Routes", value: "0", systemImage: "map")
                    } else {
                        ForEach(Array(VM.daysAndRoutes.keys), id: \.self) { key in
                            if let value = VM.daysAndRoutes[key] {
                                statRow(
                                    title: key.rawValue,
                                    value: "\(value)",
                                    systemImage: "calendar"
                                )
                            }
                        }
                    }
                }
            },
            preview: {
                EmptyView()
            }
        )
    }

    var routeOverview: some View {
        managementCard(
            title: "Active Routes",
            subtitle: "Route overview for internal and external teams.",
            systemImage: "map.circle",
            countText: VM.companyUsers.isEmpty ? nil : "\(VM.companyUsers.count)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.companyRouteOverView(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .companyRouteOverView
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    ForEach(VM.companyUsers.prefix(6)) { user in
                        statRow(
                            title: user.userName,
                            value: user.roleName,
                            systemImage: "person.crop.circle"
                        )
                    }
                }
            },
            preview: {
                EmptyView()
            }
        )
    }

    var externalRoutes: some View {
        managementCard(
            title: "External Routes",
            subtitle: "External routes and partner route coverage.",
            systemImage: "map.fill",
            countText: VM.companyUsers.isEmpty ? nil : "\(VM.companyUsers.count)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.externalRouteOverView(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .externalRoutesOverview
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    ForEach(VM.companyUsers.prefix(6)) { user in
                        statRow(
                            title: user.userName,
                            value: user.roleName,
                            systemImage: "person.crop.circle"
                        )
                    }
                }
            },
            preview: {
                EmptyView()
            }
        )
    }

    var routeSandbox: some View {
        managementCard(
            title: "Route Sandbox",
            subtitle: "Experimental route planning area.",
            systemImage: "flask",
            countText: nil,
            seeMore: {
                AnyView(EmptyView())
            },
            stats: {
                EmptyView()
            },
            preview: {
                EmptyView()
            }
        )
    }
}

// MARK: - Reusable Card UI

extension Managment {

    var shouldShowStats: Bool {
        masterDataManager.mainScreenDisplayType == .fullPreview ||
        masterDataManager.mainScreenDisplayType == .preview
    }

    var shouldShowFullPreview: Bool {
        masterDataManager.mainScreenDisplayType == .fullPreview
    }

    var seeMoreLabel: some View {
        Label("See More", systemImage: "arrow.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.poolRed)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.poolRed.opacity(0.10), in: Capsule())
    }

    func managementCard<Stats: View, Preview: View, SeeMore: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        countText: String?,
        @ViewBuilder seeMore: () -> SeeMore,
        @ViewBuilder stats: () -> Stats,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let countText {
                            Text(countText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                seeMore()
            }

            if shouldShowStats {
                stats()
            }

            preview()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func statRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func horizontalPreviewList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                content()
            }
            .padding(.vertical, 2)
        }
    }

    func previewTile(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "-" : title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 142, height: 118)
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    func emptyPreviewTile(_ title: String, systemImage: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading management...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    func usersPreview(
        emptyTitle: String,
        emptyImage: String
    ) -> some View {
        Group {
            if VM.companyUsers.isEmpty {
                emptyPreviewTile(emptyTitle, systemImage: emptyImage)
            } else {
                horizontalPreviewList {
                    ForEach(VM.companyUsers) { user in
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.users(dataService: dataService)) {
                                previewTile(
                                    title: user.userName,
                                    subtitle: user.roleName,
                                    systemImage: "person.3.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                masterDataManager.companyUser = user
                                navigationManager.routes.append(
                                    Route.users(dataService: dataService)
                                )
                            } label: {
                                previewTile(
                                    title: user.userName,
                                    subtitle: user.roleName,
                                    systemImage: "person.3.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    func currency(_ amount: Double) -> String {
        amount.formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }

    func centsCurrency(_ cents: Int) -> String {
        (Double(cents) / 100.0).formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }
}
