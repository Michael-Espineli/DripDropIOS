    //
    //  Operations.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 4/2/24.
    //

    import SwiftUI
    import MapKit
    import Firebase
    import Charts

    struct Operations: View {
        @EnvironmentObject var navigationManager: NavigationStateManager
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService: ProductionDataService

        @StateObject var VM: MyCompanyViewModel

        init(dataService: any ProductionDataServiceProtocol) {
            _VM = StateObject(wrappedValue: MyCompanyViewModel(dataService: dataService))
        }

        @State var showOperations: Bool = false
        @State var showFinace: Bool = false
        @State var showManagement: Bool = false

        @State var isLoading: Bool = true

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard

                        if let role = masterDataManager.role {
                            if role.permissionIdList.contains("0") {
                                operations
                            } else {
                                emptyState(
                                    title: "No operations access.",
                                    message: "Your role does not currently include operations permissions.",
                                    systemImage: "lock.shield"
                                )
                            }
                        } else {
                            emptyState(
                                title: "Loading role.",
                                message: "Operations will appear after your role permissions load.",
                                systemImage: "person.badge.key"
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

//                if isLoading {
//                    loadingOverlay
//                }
            }
            .onAppear {
                if !UIDevice.isIPhone {
                    showOperations = true
                    showFinace = true
                    showManagement = true
                }
            }
            .task {
                if let company = masterDataManager.currentCompany,
                   let user = masterDataManager.user {
                    do {
                        try await VM.onLoad(
                            companyId: company.id,
                            userId: user.id,
                            category: "Operations"
                        )
                    } catch {
                        print("[Operations][Task onAppear:onLoad:catch:]")
                        print(error)
                    }
                }
            }
            .onChange(of: masterDataManager.currentCompany) { _ in
                Task {
                    if let company = masterDataManager.currentCompany,
                       let user = masterDataManager.user {
                        do {
                            try await VM.onLoad(
                                companyId: company.id,
                                userId: user.id,
                                category: "Operations"
                            )
                        } catch {
                            print(error)
                        }
                    }
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
    }

    // MARK: - Main Sections

    extension Operations {

        var headerCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                            .frame(width: 58, height: 58)

                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Operations")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(masterDataManager.currentCompany?.name ?? "Review customers, jobs, repair requests, service stops, and equipment.")
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

                    Spacer()
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var operations: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Operations Overview", systemImage: "slider.horizontal.3")

                    Spacer()
                }

                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("10") {
                        customers
                    }

                    if role.permissionIdList.contains("60") {
                        equipment
                    }

                    if role.permissionIdList.contains("20") {
                        jobs
                        offeredWork
                    }

                    if role.permissionIdList.contains("30") {
                        repairRequests
                    }

                    if role.permissionIdList.contains("240") {
                        serviceStops
                    }
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
                    "Jobs": .blue,
                    "Repair Requests": .red,
                    "Items Purchased": .green
                ])
                .frame(height: 220)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    // MARK: - Operations Cards

    extension Operations {

        var customers: some View {
            operationsCard(
                title: "Customers",
                subtitle: "Active residential and commercial accounts.",
                systemImage: "person.2",
                countText: VM.totalCustomers == nil ? nil : "\(VM.totalCustomers ?? 0)",
                seeMore: {
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.customers(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .customers
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                },
                stats: {
                    VStack(spacing: 8) {
                        if let num = VM.totalCustomers {
                            statRow(title: "Total", value: num.description, systemImage: "person.2")
                        }

                        if let num = VM.totalResidentalAccounts {
                            statRow(title: "Residential", value: num.description, systemImage: "house")
                        }

                        if let num = VM.totalComericalAccounts {
                            statRow(title: "Commercial", value: num.description, systemImage: "building.2")
                        }
                    }
                },
                preview: {
                    if shouldShowFullPreview {
                        if VM.customers.isEmpty {
                            emptyPreviewTile("No Customers", systemImage: "person.slash")
                        } else {
                            horizontalPreviewList {
                                ForEach(VM.customers) { datum in
                                    let customerName = datum.displayAsCompany
                                    ? (datum.company ?? "\(datum.firstName) \(datum.lastName)")
                                    : "\(datum.firstName) \(datum.lastName)"

                                    if UIDevice.isIPhone {
                                        NavigationLink(
                                            value: Route.customer(
                                                customer: datum,
                                                dataService: dataService
                                            )
                                        ) {
                                            previewTile(
                                                title: customerName,
                                                subtitle: datum.billingAddress.streetAddress,
                                                systemImage: "person.fill"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            masterDataManager.selectedCategory = .customers
                                            masterDataManager.selectedCustomer = datum
                                        } label: {
                                            previewTile(
                                                title: customerName,
                                                subtitle: datum.billingAddress.streetAddress,
                                                systemImage: "person.fill"
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

        var equipment: some View {
            operationsCard(
                title: "Equipment",
                subtitle: "Installed equipment, repair needs, and service reminders.",
                systemImage: "spigot.fill",
                countText: VM.listOfEquipment.isEmpty ? nil : "\(VM.listOfEquipment.count)",
                seeMore: {
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.equipmentList(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .equipment
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                },
                stats: {
                    VStack(spacing: 8) {
                        statRow(title: "Needs Service", value: "15", systemImage: "wrench.and.screwdriver")
                        statRow(title: "Needs Repair", value: "2", systemImage: "cross.case")
                    }
                },
                preview: {
                    if shouldShowFullPreview {
                        if VM.listOfEquipment.isEmpty {
                            emptyPreviewTile("No Equipment", systemImage: "spigot.fill")
                        } else {
                            horizontalPreviewList {
                                ForEach(VM.listOfEquipment) { datum in
                                    if UIDevice.isIPhone {
                                        NavigationLink(
                                            value: Route.equipmentDetailView(
                                                equipment: datum,
                                                dataService: dataService
                                            )
                                        ) {
                                            previewTile(
                                                title: datum.name,
                                                subtitle: datum.customerName,
                                                systemImage: "spigot.fill"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            masterDataManager.selectedCategory = .equipment
                                            masterDataManager.selectedEquipment = datum
                                        } label: {
                                            previewTile(
                                                title: datum.name,
                                                subtitle: datum.customerName,
                                                systemImage: "spigot.fill"
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

        var jobs: some View {
            operationsCard(
                title: "Jobs",
                subtitle: "Open work orders, estimates, and recently completed jobs.",
                systemImage: "briefcase",
                countText: VM.openJobs == nil ? nil : "\(VM.openJobs ?? 0)",
                seeMore: {
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.jobs(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .jobs
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                },
                stats: {
                    VStack(spacing: 8) {
                        statRow(title: "Open", value: String(VM.openJobs ?? 0), systemImage: "folder")
                        statRow(title: "Recently Finished", value: String(VM.recentlyFinishedJobs ?? 0), systemImage: "checkmark.circle")
                    }
                },
                preview: {
                    if shouldShowFullPreview {
                        if VM.jobs.isEmpty {
                            emptyPreviewTile("No Jobs", systemImage: "briefcase")
                        } else {
                            horizontalPreviewList {
                                ForEach(VM.jobs) { datum in
                                    if UIDevice.isIPhone {
                                        NavigationLink(
                                            value: Route.job(
                                                job: datum,
                                                dataService: dataService
                                            )
                                        ) {
                                            previewTile(
                                                title: datum.internalId.isEmpty ? datum.id : datum.internalId,
                                                subtitle: datum.customerName,
                                                systemImage: "wrench.adjustable.fill"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            masterDataManager.selectedJob = datum
                                            masterDataManager.selectedCategory = .jobs
                                        } label: {
                                            previewTile(
                                                title: datum.internalId.isEmpty ? datum.id : datum.internalId,
                                                subtitle: datum.customerName,
                                                systemImage: "wrench.adjustable.fill"
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

        var offeredWork: some View {
            operationsCard(
                title: "Offered Work",
                subtitle: "Direct offers, internal board posts, and accepted work.",
                systemImage: "list.bullet.clipboard",
                countText: VM.workOffers.isEmpty ? nil : "\(VM.workOffers.openOfferCount)",
                seeMore: {
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.offeredWork(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            NavigationLink(value: Route.offeredWork(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                },
                stats: {
                    VStack(spacing: 8) {
                        statRow(title: "Open", value: "\(VM.workOffers.openOfferCount)", systemImage: "paperplane")
                        statRow(title: "Ready", value: "\(VM.workOffers.acceptedReadyToScheduleCount)", systemImage: "calendar.badge.plus")
                        statRow(title: "Scheduled", value: "\(VM.workOffers.scheduledOfferCount)", systemImage: "checkmark.circle")
                    }
                },
                preview: {
                    if shouldShowFullPreview {
                        if VM.workOffers.isEmpty {
                            emptyPreviewTile("No Offered Work", systemImage: "tray")
                        } else {
                            horizontalPreviewList {
                                ForEach(VM.workOffers.prefix(10)) { offer in
                                    NavigationLink(value: Route.offeredWork(dataService: dataService)) {
                                        previewTile(
                                            title: offer.title.isEmpty ? "Offered Work" : offer.title,
                                            subtitle: offer.customerName,
                                            systemImage: offer.offerType.systemImage
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            )
        }

        var repairRequests: some View {
            operationsCard(
                title: "Repair Requests",
                subtitle: "Customer repair requests waiting for review or action.",
                systemImage: "cross.case",
                countText: VM.listOfRepairRequests.isEmpty ? nil : "\(VM.listOfRepairRequests.count)",
                seeMore: {
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.repairRequestList(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .repairRequest
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                },
                stats: {
                    VStack(spacing: 8) {
                        statRow(title: "Open", value: "8", systemImage: "tray")
                        statRow(title: "In Progress / Scheduled", value: "3", systemImage: "calendar.badge.clock")
                        statRow(title: "Recently Finished", value: "3", systemImage: "checkmark.circle")
                    }
                },
                preview: {
                    if shouldShowFullPreview {
                        if VM.listOfRepairRequests.isEmpty {
                            emptyPreviewTile("No Repairs", systemImage: "cross.case")
                        } else {
                            horizontalPreviewList {
                                ForEach(VM.listOfRepairRequests) { datum in
                                    if UIDevice.isIPhone {
                                        NavigationLink(
                                            value: Route.repairRequest(
                                                repairRequest: datum,
                                                dataService: dataService
                                            )
                                        ) {
                                            previewTile(
                                                title: datum.customerName,
                                                subtitle: datum.description,
                                                systemImage: "wrench.adjustable.fill"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            masterDataManager.selectedRepairRequest = datum
                                            masterDataManager.selectedCategory = .repairRequest
                                        } label: {
                                            previewTile(
                                                title: datum.customerName,
                                                subtitle: datum.description,
                                                systemImage: "wrench.adjustable.fill"
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

        var serviceStops: some View {
            operationsCard(
                title: "Service Stops",
                subtitle: "Upcoming and current route work.",
                systemImage: "mappin.and.ellipse",
                countText: VM.serviceStops.isEmpty ? nil : "\(VM.serviceStops.count)",
                seeMore: {
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.serviceStops(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .serviceStops
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                },
                stats: {
                    VStack(spacing: 8) {
                        if VM.typesAndAmount.isEmpty {
                            statRow(title: "Scheduled", value: "\(VM.serviceStops.count)", systemImage: "calendar")
                        } else {
                            ForEach(Array(VM.typesAndAmount.keys), id: \.self) { key in
                                if let amount = VM.typesAndAmount[key] {
                                    statRow(title: key, value: amount.description, systemImage: "tag")
                                }
                            }
                        }
                    }
                },
                preview: {
                    if shouldShowFullPreview {
                        if VM.serviceStops.isEmpty {
                            emptyPreviewTile("No Service Stops", systemImage: "mappin.slash")
                        } else {
                            horizontalPreviewList {
                                ForEach(VM.serviceStops) { datum in
                                    if UIDevice.isIPhone {
                                        NavigationLink(
                                            value: Route.serviceStop(
                                                serviceStop: datum,
                                                dataService: dataService
                                            )
                                        ) {
                                            previewTile(
                                                title: datum.customerName,
                                                subtitle: shortDate(date: datum.serviceDate),
                                                systemImage: serviceStopIcon(datum.typeImage)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            masterDataManager.selectedCategory = .serviceStops
                                            masterDataManager.selectedServiceStops = datum
                                        } label: {
                                            previewTile(
                                                title: datum.customerName,
                                                subtitle: shortDate(date: datum.serviceDate),
                                                systemImage: serviceStopIcon(datum.typeImage)
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

    // MARK: - Reusable Card UI

    extension Operations {

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

        func operationsCard<Stats: View, Preview: View, SeeMore: View>(
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
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
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

        func horizontalPreviewList<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

                    Text("Loading operations...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(22)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }

        func serviceStopIcon(_ iconName: String) -> String {
            if iconName.isEmpty {
                return "mappin.and.ellipse"
            }

            return iconName
        }
    }
