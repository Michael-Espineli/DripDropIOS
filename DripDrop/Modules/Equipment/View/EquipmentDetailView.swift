    //
    //  EquipmentDetailView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //

    import SwiftUI
    import MapKit

    @MainActor
    final class EquipmentDetailViewModel: ObservableObject {
        private var dataService: any ProductionDataServiceProtocol

        init(dataService: any ProductionDataServiceProtocol) {
            self.dataService = dataService
        }

        @Published private(set) var bodiesOfWater: [BodyOfWater] = []
        @Published var loadedImages: [DripDropStoredImage] = []

        @Published var selectedDripDropPhotos: [DripDropImage] = []
        @Published var selectedBOW: BodyOfWater? = nil

        @Published private(set) var serviceHistory: [EquipmentServiceHistory] = []
        @Published private(set) var maintenanceHistory: [EquipmentServiceHistory] = []
        @Published private(set) var repairHistory: [EquipmentServiceHistory] = []
        @Published private(set) var scheduledWork: [EquipmentScheduledWork] = []
        @Published private(set) var outstandingRepairRequests: [RepairRequest] = []
        func getAllBodiesOfWaterByServiceLocation(
            companyId: String,
            serviceLocation: ServiceLocation
        ) async throws {
            self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(
                companyId: companyId,
                serviceLocation: serviceLocation
            )
        }
        func getEquipmentServiceHistory(
            companyId: String,
            equipmentId: String
        ) async throws {
            let history = try await dataService.getEquipmentServiceHistory(
                companyId: companyId,
                equipmentId: equipmentId
            )

            self.serviceHistory = history.sorted { $0.date > $1.date }

            self.maintenanceHistory = history
                .filter { $0.type.rawValue.lowercased() == "maintenance" }
                .sorted { $0.date > $1.date }

            self.repairHistory = history
                .filter { $0.type.rawValue.lowercased() == "repair" }
                .sorted { $0.date > $1.date }
        }
        func getScheduledWorkForEquipment(
            companyId: String,
            equipmentId: String
        ) async throws {
            let work = try await dataService.getEquipmentScheduledWork(
                companyId: companyId,
                equipmentId: equipmentId
            )

            self.scheduledWork = work.sorted {
                let lhs = $0.serviceDate ?? $0.dateCreated
                let rhs = $1.serviceDate ?? $1.dateCreated
                return lhs < rhs
            }
        }
        func getOutstandingRepairRequests(
            companyId: String,
            equipmentId: String
        ) async throws {
            let requests = try await dataService.getAllRepairRequests(companyId: companyId)

            self.outstandingRepairRequests = requests
                .filter { request in
                    request.equipmentId == equipmentId && request.status.isOpenWorkQueueItem
                }
                .sorted { $0.date > $1.date }
        }
        func updatePhotoUrl(companyId: String, equipmentId: String) {
            Task {
                do {
                    for photo in selectedDripDropPhotos {
                        let (path, name) = try await dataService.uploadEquipmentImage(
                            companyId: companyId,
                            equipmentId: equipmentId,
                            image: photo
                        )

                        let storedImage = DripDropStoredImage(
                            id: UUID().uuidString,
                            description: name,
                            imageURL: path
                        )

                        self.loadedImages.append(storedImage)

                        try dataService.updateEquipmentPhotoUrls(
                            companyId: companyId,
                            equipmentId: equipmentId,
                            image: storedImage
                        )
                    }

                    self.selectedDripDropPhotos = []
                } catch {
                    print(error)
                }
            }
        }
    }

    struct EquipmentDetailView: View {
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService: ProductionDataService

        @StateObject var equipmentVM: EquipmentViewModel
        @StateObject var VM: EquipmentDetailViewModel

        @State var equipment: Equipment

        init(dataService: any ProductionDataServiceProtocol, equipment: Equipment) {
            _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
            _VM = StateObject(wrappedValue: EquipmentDetailViewModel(dataService: dataService))
            _equipment = State(wrappedValue: equipment)
        }

        @State var showEditSheet: Bool = false
        @State var showNewPart: Bool = false

        @State var showRecordMaintenance: Bool = false
        @State var showScheduleMaintenanceJob: Bool = false
        @State var showRecordRepair: Bool = false
        @State var showScheduleRepairJob: Bool = false

        @State var showAllHistory: Bool = false
        @State var showMaintenanceHistory: Bool = false
        @State var showRepairHistory: Bool = false

        @State var selectedEquipmentPart: EquipmentPart? = nil
        @State var selectedServiceHistory: EquipmentServiceHistory? = nil

        @State var isLoading: Bool = false

        var activeEquipment: Equipment {
            masterDataManager.selectedEquipment ?? equipment
        }

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                if isLoading {
                    loadingOverlay
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            if UIDevice.isIPhone {
                                VStack(spacing: 14) {
                                    info
                                    outstandingRepairRequestsSection
                                    scheduledWorkSection
                                    serviceHistoryOverviewSection
                                    maintenanceHistorySection
                                    repairHistorySection
                                    photos
                                    partsSection
                                }
                            } else {
                                HStack(alignment: .top, spacing: 14) {
                                    VStack(spacing: 14) {
                                        info
                                        photos
                                    }

                                    VStack(spacing: 14) {
                                        partsSection
                                        outstandingRepairRequestsSection
                                        scheduledWorkSection
                                        serviceHistoryOverviewSection
                                        maintenanceHistorySection
                                        repairHistorySection
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 154)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                equipmentBottomActionBar
            }
            .sheet(isPresented: $showEditSheet) {
                EditEquipmentView(
                    dataService: dataService,
                    equipment: activeEquipment
                )
            }
            .sheet(isPresented: $showNewPart) {
                Text("Add New Part View")
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedEquipmentPart) { part in
                EquipmentPartDetailView(equipmentPart: part)
            }
            .sheet(item: $selectedServiceHistory) { history in
                equipmentServiceHistoryDetailSheet(history)
            }
            .sheet(isPresented: $showRecordMaintenance) {
                RecordEquipmentMaintenanceView(
                    dataService: dataService,
                    equipment: activeEquipment
                ) {
                    Task {
                        await loadEquipmentData()
                    }
                }
            }
            .sheet(isPresented: $showScheduleMaintenanceJob) {
                ScheduleEquipmentMaintenanceJobView(
                    dataService: dataService,
                    equipment: activeEquipment
                ) {
                    Task {
                        await loadEquipmentData()
                    }
                }
            }
            .sheet(isPresented: $showRecordRepair) {
                RecordEquipmentRepairView(
                    dataService: dataService,
                    equipment: activeEquipment
                ) {
                    Task {
                        await loadEquipmentData()
                    }
                }
            }
            .sheet(isPresented: $showScheduleRepairJob) {
                ScheduleEquipmentRepairJobView(
                    dataService: dataService,
                    equipment: activeEquipment
                ) {
                    Task {
                        await loadEquipmentData()
                    }
                }
            }
            .sheet(isPresented: $showAllHistory) {
                historyListSheet(
                    title: "Equipment Service History",
                    systemImage: "clock.arrow.circlepath",
                    items: VM.serviceHistory
                )
            }
            .sheet(isPresented: $showMaintenanceHistory) {
                historyListSheet(
                    title: "Maintenance History",
                    systemImage: "wrench.and.screwdriver",
                    items: VM.maintenanceHistory
                )
            }
            .sheet(isPresented: $showRepairHistory) {
                historyListSheet(
                    title: "Repair History",
                    systemImage: "cross.case",
                    items: VM.repairHistory
                )
            }
            .task {
                await loadEquipmentData()
            }
            .onChange(of: masterDataManager.selectedEquipment) { _ in
                Task {
                    await loadEquipmentData()
                }
            }
            .onChange(of: VM.selectedDripDropPhotos) { _ in
                if let currentCompany = masterDataManager.currentCompany {
                    VM.updatePhotoUrl(
                        companyId: currentCompany.id,
                        equipmentId: activeEquipment.id
                    )
                }
            }
        }

        func loadEquipmentData() async {
            do {
                print("Loading equipment data")
                if let company = masterDataManager.currentCompany {
                    VM.loadedImages = activeEquipment.photoUrls ?? []

                    try await equipmentVM.getAllPartsByEquipment(
                        companyId: company.id,
                        equipmentId: activeEquipment.id
                    )

                    try await VM.getEquipmentServiceHistory(
                        companyId: company.id,
                        equipmentId: activeEquipment.id
                    )
                    try await VM.getScheduledWorkForEquipment(
                        companyId: company.id,
                        equipmentId: activeEquipment.id
                    )
                    try await VM.getOutstandingRepairRequests(
                        companyId: company.id,
                        equipmentId: activeEquipment.id
                    )
                }
            } catch {
                print("Error loading equipment data")
                print(error)
            }
        }

        func getNextServiceDate(lastServiceDate: Date, every: String, frequency: String) -> Date {
            let calendar = Calendar.current
            var date = Date()

            if let repeatingEvery = Int(every) {
                switch frequency {
                case "Day":
                    date = calendar.date(byAdding: .day, value: repeatingEvery, to: lastServiceDate) ?? Date()
                case "Week":
                    let week = repeatingEvery * 7
                    date = calendar.date(byAdding: .day, value: week, to: lastServiceDate) ?? Date()
                case "Month":
                    date = calendar.date(byAdding: .month, value: repeatingEvery, to: lastServiceDate) ?? Date()
                case "Year":
                    date = calendar.date(byAdding: .year, value: repeatingEvery, to: lastServiceDate) ?? Date()
                default:
                    print("None")
                }
            } else {
                print("Error Converting Number")
            }

            return date
        }
    }

    // MARK: - Main Sections

    extension EquipmentDetailView {

        var info: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(activeEquipment.name.isEmpty ? "Equipment" : activeEquipment.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(activeEquipment.type.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let role = masterDataManager.role, role.permissionIdList.contains("64") {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.accentColor.opacity(0.14), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    statusBadge

                    if activeEquipment.needsService {
                        Label("Service Enabled", systemImage: "wrench.and.screwdriver")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                    }

                    Spacer()
                }

                VStack(spacing: 8) {
                    detailRow(title: "Category", value: activeEquipment.type.rawValue, systemImage: "square.grid.2x2")
                    detailRow(title: "Make", value: activeEquipment.make, systemImage: "tag")
                    detailRow(title: "Model", value: activeEquipment.model, systemImage: "cube")
                    detailRow(title: "Date Installed", value: fullDate(date: activeEquipment.dateInstalled), systemImage: "calendar")
                }

                serviceInfoBlock

                if activeEquipment.type == .filter {
                    filterInfoBlock
                }

                notesBlock
            }
            .padding(16)
            
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var partsSection: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Parts", systemImage: "gearshape.2")

                    Spacer()

                    Button {
                        showNewPart.toggle()
                    } label: {
                        Label("Add Part", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if equipmentVM.partList.isEmpty {
                    emptyState(
                        title: "No parts added yet.",
                        message: "Parts installed on this equipment will show here.",
                        systemImage: "gearshape.2"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(equipmentVM.partList) { part in
                            partRow(part)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var maintenanceHistorySection: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Maintenance History", systemImage: "wrench.and.screwdriver")

                    Spacer()

                    Button {
                        showMaintenanceHistory.toggle()
                    } label: {
                        Label("View More", systemImage: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if VM.maintenanceHistory.isEmpty {
                    emptyState(
                        title: "No maintenance history.",
                        message: "Recent maintenance records will appear here.",
                        systemImage: "wrench.and.screwdriver"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(VM.maintenanceHistory.prefix(3))) { item in
                            serviceHistoryRow(item)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var serviceHistoryOverviewSection: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Service History", systemImage: "clock.arrow.circlepath")

                    Spacer()

                    Button {
                        showAllHistory.toggle()
                    } label: {
                        Label("View All", systemImage: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    historyCountPill(
                        title: "All",
                        count: VM.serviceHistory.count,
                        systemImage: "list.bullet.rectangle"
                    )
                    historyCountPill(
                        title: "Maintenance",
                        count: VM.maintenanceHistory.count,
                        systemImage: "wrench.and.screwdriver"
                    )
                    historyCountPill(
                        title: "Repair",
                        count: VM.repairHistory.count,
                        systemImage: "cross.case"
                    )
                }

                if VM.serviceHistory.isEmpty {
                    emptyState(
                        title: "No service history.",
                        message: "Maintenance and repair records will appear here.",
                        systemImage: "clock.arrow.circlepath"
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(VM.serviceHistory.prefix(4)).indices, id: \.self) { index in
                            historyTimelineRow(
                                item: VM.serviceHistory[index],
                                isLast: index == min(VM.serviceHistory.count, 4) - 1
                            )
                        }
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var repairHistorySection: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Repair History", systemImage: "cross.case")

                    Spacer()

                    Button {
                        showRepairHistory.toggle()
                    } label: {
                        Label("View More", systemImage: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if VM.repairHistory.isEmpty {
                    emptyState(
                        title: "No repair history.",
                        message: "Recent repair records will appear here.",
                        systemImage: "cross.case"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(VM.repairHistory.prefix(3))) { item in
                            serviceHistoryRow(item)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var photos: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Photos", systemImage: "photo")

                    Spacer()

                    Text("\(VM.loadedImages.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)

                if !VM.selectedDripDropPhotos.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()

                        Text("Loading Images...")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if VM.loadedImages.isEmpty {
                    emptyState(
                        title: "No Images",
                        message: "Uploaded equipment photos will appear here.",
                        systemImage: "photo.on.rectangle.angled"
                    )
                } else {
                    DripDropStoredImageRow(images: VM.loadedImages)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    // MARK: - Info Blocks

    extension EquipmentDetailView {

        var statusBadge: some View {
            Group {
                switch activeEquipment.status {
                case .operational:
                    Label(activeEquipment.status.displayName, systemImage: "checkmark.circle")
                        .foregroundStyle(Color.poolGreen)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.poolGreen.opacity(0.12), in: Capsule())

                case .nonoperational:
                    Label(activeEquipment.status.displayName, systemImage: "xmark.circle")
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.12), in: Capsule())

                case .needsRepair:
                    Label(activeEquipment.status.displayName, systemImage: "cross.case")
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.12), in: Capsule())

                case .needsMaintenance:
                    Label(activeEquipment.status.displayName, systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(Color.yellow)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.yellow.opacity(0.16), in: Capsule())

                case .replaced:
                    Label(activeEquipment.status.displayName, systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.16), in: Capsule())
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }

        @ViewBuilder
        var serviceInfoBlock: some View {
            if activeEquipment.needsService,
               let serviceDate = activeEquipment.lastServiceDate,
               let every = activeEquipment.serviceFrequencyEvery,
               let frequency = activeEquipment.serviceFrequency,
               let nextServiceDate = activeEquipment.nextServiceDate {

                Divider().opacity(0.35)

                VStack(spacing: 8) {
                    detailRow(
                        title: "Last Service Date",
                        value: fullDate(date: serviceDate),
                        systemImage: "clock.arrow.circlepath"
                    )

                    detailRow(
                        title: "Service Frequency",
                        value: "\(every) \(frequency)",
                        systemImage: "repeat"
                    )

                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(.thinMaterial, in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Next Service Date")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(fullDate(date: nextServiceDate))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text(nextServiceDate > Date() ? "Upcoming" : "Due")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(nextServiceDate > Date() ? Color.poolGreen : Color.red)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                nextServiceDate > Date() ? Color.poolGreen.opacity(0.12) : Color.red.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }

        @ViewBuilder
        var filterInfoBlock: some View {
            Divider().opacity(0.35)

            VStack(spacing: 8) {
                if let cleanPressure = activeEquipment.cleanFilterPressure {
                    detailRow(
                        title: "Clean Pressure",
                        value: "\(String(format: "%.0f", Double(cleanPressure))) PSI",
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    )

                    if let currentPressure = activeEquipment.currentPressure {
                        let difference = Double(Int(currentPressure) - cleanPressure)
                        let dirtyPercent = (difference / 15) * 100

                        detailRow(
                            title: "Dirty",
                            value: "\(String(format: "%.0f", dirtyPercent))%",
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                }

                if let lastServiceDate = activeEquipment.lastServiceDate {
                    detailRow(
                        title: "Last Cleaned",
                        value: shortDate(date: lastServiceDate),
                        systemImage: "sparkles"
                    )
                }

                detailRow(
                    title: "Installed",
                    value: "\(shortDate(date: activeEquipment.dateInstalled)) (\(String(format: "%.1f", numberOfYearsBetween(activeEquipment.dateInstalled, Date()))) years)",
                    systemImage: "calendar"
                )
            }
        }

        var notesBlock: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label("Notes", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(activeEquipment.notes.isEmpty ? "No notes provided." : activeEquipment.notes)
                    .font(.subheadline)
                    .foregroundStyle(activeEquipment.notes.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Bottom Bar

    extension EquipmentDetailView {

        var equipmentBottomActionBar: some View {
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.35)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            showRecordMaintenance.toggle()
                        } label: {
                            bottomActionLabel(
                                title: "Record Maintenance",
                                systemImage: "wrench.and.screwdriver"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showScheduleMaintenanceJob.toggle()
                        } label: {
                            bottomActionLabel(
                                title: "Schedule Maintenance",
                                systemImage: "calendar.badge.plus"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        Button {
                            showRecordRepair.toggle()
                        } label: {
                            bottomActionLabel(
                                title: "Record Repair",
                                systemImage: "cross.case"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showScheduleRepairJob.toggle()
                        } label: {
                            bottomActionLabel(
                                title: "Schedule Repair",
                                systemImage: "calendar.badge.clock"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(.regularMaterial)
            }
        }

        func bottomActionLabel(title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Rows

    extension EquipmentDetailView {

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
                    .frame(width: 28, height: 28)
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

        func partRow(_ part: EquipmentPart) -> some View {
            Button {
                selectedEquipmentPart = part
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(part.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("Install Date: \(fullDate(date: part.date))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
        }

        func serviceHistoryRow(_ item: EquipmentServiceHistory) -> some View {
            Button {
                selectedServiceHistory = item
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: item.type.rawValue.lowercased() == "repair" ? "cross.case" : "wrench.and.screwdriver")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        HStack(spacing: 8) {
                            Text(fullDate(date: item.date))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)

                            if !item.techName.isEmpty {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                Text(item.techName)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Text(item.type.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())

                        if !item.jobId.isEmpty {
                            Image(systemName: "briefcase")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }

        func historyCountPill(title: String, count: Int, systemImage: String) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(count)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        func historyTimelineRow(item: EquipmentServiceHistory, isLast: Bool) -> some View {
            Button {
                selectedServiceHistory = item
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Image(systemName: item.type.rawValue.lowercased() == "repair" ? "cross.case.fill" : "wrench.and.screwdriver.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(item.type.rawValue.lowercased() == "repair" ? Color.red.opacity(0.85) : Color.green.opacity(0.85), in: Circle())

                        if !isLast {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.22))
                                .frame(width: 2, height: 32)
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name.isEmpty ? item.type.rawValue : item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            Text(fullDate(date: item.date))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(item.description.isEmpty ? "No description provided." : item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Text(item.type.rawValue)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)

                            if !item.techName.isEmpty {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                Text(item.techName)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.bottom, isLast ? 0 : 10)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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

        var loadingOverlay: some View {
            ZStack {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()

                    Text("Loading equipment...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(22)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    // MARK: - Sheets

extension EquipmentDetailView {
    
    func historyListSheet(
        title: String,
        systemImage: String,
        items: [EquipmentServiceHistory]
    ) -> some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(title, systemImage: systemImage)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text(activeEquipment.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showAllHistory = false
                            showMaintenanceHistory = false
                            showRepairHistory = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 34, height: 34)
                                .background(.thinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    
                    if items.isEmpty {
                        emptyState(
                            title: "No history found.",
                            message: "History records will appear here after records are added.",
                            systemImage: systemImage
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                serviceHistoryRow(item)
                            }
                        }
                        .padding(16)
                        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
                .padding(14)
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    func equipmentServiceHistoryDetailSheet(_ history: EquipmentServiceHistory) -> some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(history.name)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                Text(history.type.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                selectedServiceHistory = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 34, height: 34)
                                    .background(.thinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        detailRow(title: "Date", value: fullDate(date: history.date), systemImage: "calendar")
                        detailRow(title: "Performed By", value: history.performedBy.rawValue, systemImage: "person.crop.circle")
                        detailRow(title: "Added By", value: history.addedBy.rawValue, systemImage: "person.badge.plus")
                        detailRow(title: "Technician", value: history.techName, systemImage: "person")
                        detailRow(title: "Job Id", value: history.jobId, systemImage: "briefcase")
                        detailRow(title: "Parts Used", value: "\(history.partIds.count)", systemImage: "gearshape.2")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Description", systemImage: "text.alignleft")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            Text(history.description.isEmpty ? "No description provided." : history.description)
                                .font(.subheadline)
                                .foregroundStyle(history.description.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .padding(14)
            }
        }
        .presentationDetents([.medium, .large])
    }
    var scheduledWorkSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Scheduled Work", systemImage: "calendar.badge.clock")
                
                Spacer()
                
                Text("\(VM.scheduledWork.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }
            
            if VM.scheduledWork.isEmpty {
                emptyState(
                    title: "No scheduled work.",
                    message: "Maintenance and repair jobs scheduled for this equipment will show here.",
                    systemImage: "calendar.badge.clock"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.scheduledWork.prefix(5)) { work in
                        equipmentScheduledWorkRow(work)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var outstandingRepairRequestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Outstanding Repair Requests", systemImage: "exclamationmark.triangle")

                Spacer()

                Text("\(VM.outstandingRepairRequests.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.outstandingRepairRequests.isEmpty {
                emptyState(
                    title: "No outstanding repair requests.",
                    message: "Unresolved repair requests tied to this equipment will show here.",
                    systemImage: "exclamationmark.triangle"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.outstandingRepairRequests.prefix(5)) { request in
                        NavigationLink(
                            value: Route.repairRequest(
                                repairRequest: request,
                                dataService: dataService
                            )
                        ) {
                            outstandingRepairRequestRow(request)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func outstandingRepairRequestRow(_ request: RepairRequest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(request.description.isEmpty ? "Repair Request" : request.description)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(request.status.displayName) • \(shortDate(date: request.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    func equipmentScheduledWorkRow(_ work: EquipmentScheduledWork) -> some View {
        EquipmentScheduledWorkRowView(
            dataService: dataService,
            work: work,
            statusColor: statusColor(for:)
        )
    }
    func statusColor(for status: EquipmentScheduledWorkStatus) -> Color {
        switch status {
        case .draft:
            return .secondary
        case .estimatePending:
            return .orange
        case .scheduled:
            return .blue
        case .inProgress:
            return .purple
        case .completed:
            return Color.poolGreen
        case .canceled:
            return .red
        }
    }
}
struct EquipmentScheduledWorkRowView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let work: EquipmentScheduledWork
    let statusColor: (EquipmentScheduledWorkStatus) -> Color

    @State private var job: Job? = nil
    @State private var isLoadingJob: Bool = false
    @State private var didTryLoadJob: Bool = false

    var body: some View {
        Group {
            if let job {
                NavigationLink(
                    value: Route.job(
                        job: job,
                        dataService: dataService
                    )
                ) {
                    rowContent(showChevron: true)
                }
                .buttonStyle(.plain)
            } else {
                rowContent(showChevron: false)
            }
        }
        .task {
            await loadJobIfNeeded()
        }
    }

    var rowContent: some View {
        rowContent(showChevron: false)
    }

    func rowContent(showChevron: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: work.type == .repair ? "cross.case" : "wrench.and.screwdriver")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(work.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(work.description.isEmpty ? work.type.rawValue : work.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(work.status.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusColor(work.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(statusColor(work.status).opacity(0.12), in: Capsule())

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 8) {
                if let serviceDate = work.serviceDate {
                    Label(shortDate(date: serviceDate), systemImage: "calendar")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !work.techName.isEmpty {
                    Label(work.techName, systemImage: "person.crop.circle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !work.jobInternalId.isEmpty {
                    Label(work.jobInternalId, systemImage: "briefcase")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !work.serviceStopInternalId.isEmpty {
                    Label(work.serviceStopInternalId, systemImage: "number")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if isLoadingJob {
                    ProgressView()
                        .scaleEffect(0.65)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func loadJobIfNeeded() async {
        guard !didTryLoadJob else { return }
        guard !work.jobId.isEmpty else { return }
        guard let companyId = masterDataManager.currentCompany?.id else { return }

        didTryLoadJob = true
        isLoadingJob = true

        do {
            self.job = try await dataService.getWorkOrderById(
                companyId: companyId,
                workOrderId: work.jobId
            )
        } catch {
            print("Error loading job for scheduled equipment work")
            print(error)
        }

        isLoadingJob = false
    }
}
