//
//  ServiceStopDetailView3.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//
//  Office/management detail view. The technician field version is ServiceStopDetailView2.

import SwiftUI

struct ServiceStopDetailView3: View {
    init(
        dataService: any ProductionDataServiceProtocol,
        serviceStop: ServiceStop
    ) {
        _VM = StateObject(
            wrappedValue: ServiceStopDetailViewModel(dataService: dataService)
        )
        _serviceStop = State(wrappedValue: serviceStop)
    }

    @StateObject private var VM: ServiceStopDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService

    @State private var serviceStop: ServiceStop?
    @State private var stopData: StopData = StopData(
        id: "",
        date: Date(),
        serviceStopId: "",
        readings: [],
        dosages: [],
        observation: [],
        bodyOfWaterId: "",
        customerId: "",
        serviceLocationId: "",
        userId: "",
        equipmentMeasurements: []
    )

    @State private var title: String = "Service Stop"
    @State private var selectedTab: OfficeServiceStopDetailTab = .overview
    @State private var showEditSheet: Bool = false
    @State private var isSaving: Bool = false
    @State private var isDeleting: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    @State private var editServiceDate: Date = Date()
    @State private var editTechnicianId: String = ""
    @State private var editDescription: String = ""
    @State private var editEstimatedDuration: Int = 0
    @State private var editOperationStatus: ServiceStopOperationStatus = .notFinished
    @State private var editBillingStatus: ServiceStopBillingStatus = .notInvoiced

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if let stop = serviceStop {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard(stop)
                        metricStrip(stop)
                        tabPicker
                        tabContent(stop)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 40)
                }
            } else {
                ContentUnavailableView(
                    "Service stop unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The selected service stop could not be loaded.")
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let stop = serviceStop {
                    Menu {
                        Button {
                            prepareEditState(from: stop)
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(isDeleting)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Service stop actions")
                }
            }
        }
        .confirmationDialog(
            "Delete this service stop?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if let stop = serviceStop {
                Button(isDeleting ? "Deleting..." : "Delete Service Stop", role: .destructive) {
                    deleteServiceStop(stop)
                }
                .disabled(isDeleting)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete the service stop and its task/readings history. This cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            if let stop = serviceStop {
                editSheet(stop)
            }
        }
        .alert("Service Stop", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .environmentObject(VM)
        .task { await load() }
    }
}

// MARK: - Load

extension ServiceStopDetailView3 {
    private func load() async {
        guard
            let company = masterDataManager.currentCompany,
            let user = masterDataManager.user,
            let serviceStop
        else { return }

        title = serviceStop.customerName

        do {
            try await VM.onInitalLoad(
                companyId: company.id,
                serviceStop: serviceStop,
                userId: user.id
            )

            if let received = VM.stopData {
                stopData = received
            } else if let firstBodyOfWater = VM.bodiesOfWater.first {
                stopData = StopData(
                    id: UUID().uuidString,
                    date: serviceStop.serviceDate,
                    serviceStopId: serviceStop.id,
                    readings: [],
                    dosages: [],
                    observation: [],
                    bodyOfWaterId: firstBodyOfWater.id,
                    customerId: serviceStop.customerId,
                    serviceLocationId: serviceStop.serviceLocationId,
                    userId: user.id,
                    equipmentMeasurements: []
                )
            }
        } catch {
            alertMessage = "Unable to load all service stop details."
            showAlert = true
            print("ServiceStopDetailView3 load error", error)
        }
    }
}

// MARK: - Main UI

extension ServiceStopDetailView3 {
    private func headerCard(_ stop: ServiceStop) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.poolBlue.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: stop.typeImage.isEmpty ? "mappin.and.ellipse" : stop.typeImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.poolBlue)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(stop.customerName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(stop.jobName?.isEmpty == false ? stop.jobName ?? stop.type : stop.type)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        statusChip(stop.operationStatus.rawValue, color: operationStatusColor(stop.operationStatus))
                        statusChip(stop.billingStatus.rawValue, color: billingStatusColor(stop.billingStatus))
                    }
                }

                Spacer()

                Button {
                    prepareEditState(from: stop)
                    showEditSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 38, height: 38)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit service stop")
            }

            Divider().opacity(0.35)

            VStack(alignment: .leading, spacing: 10) {
                detailLine(
                    icon: "calendar",
                    title: "Scheduled",
                    value: fullDateAndDay(date: stop.serviceDate)
                )
                detailLine(
                    icon: "mappin.and.ellipse",
                    title: "Location",
                    value: displayAddress(VM.location?.address ?? stop.address)
                )
                detailLine(
                    icon: "person.crop.circle",
                    title: "Technician",
                    value: stop.tech.isEmpty ? "Unassigned" : stop.tech
                )
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func metricStrip(_ stop: ServiceStop) -> some View {
        LazyVGrid(columns: metricColumns, spacing: 10) {
            metricCard(
                title: "Estimated",
                value: displayMinAsMinAndHour(min: stop.estimatedDuration),
                icon: "clock"
            )
            metricCard(
                title: "Actual",
                value: actualDurationText(stop),
                icon: "timer"
            )
            metricCard(
                title: "Tasks",
                value: "\(VM.taskList.count)",
                icon: "checklist"
            )
            metricCard(
                title: "Photos",
                value: "\(VM.loadedImages.count)",
                icon: "photo.on.rectangle"
            )
        }
    }

    private var tabPicker: some View {
        Picker("Section", selection: $selectedTab) {
            ForEach(OfficeServiceStopDetailTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func tabContent(_ stop: ServiceStop) -> some View {
        switch selectedTab {
        case .overview:
            overviewContent(stop)
        case .work:
            workContent(stop)
        case .water:
            waterContent
        case .photos:
            photosContent
        }
    }

    private func overviewContent(_ stop: ServiceStop) -> some View {
        VStack(spacing: 14) {
            scheduleSection(stop)
            locationSection(stop)
            serviceDescriptionSection(stop)
            linkedRecordsSection(stop)
        }
    }

    private func workContent(_ stop: ServiceStop) -> some View {
        VStack(spacing: 14) {
            taskSection(stop)
            observationsSection
        }
    }

    private var waterContent: some View {
        VStack(spacing: 14) {
            waterEquipmentSection
            equipmentSection
        }
    }

    private var photosContent: some View {
        photosSection
    }
}

// MARK: - Sections

extension ServiceStopDetailView3 {
    private func scheduleSection(_ stop: ServiceStop) -> some View {
        sectionCard(title: "Schedule", systemImage: "calendar.badge.clock") {
            VStack(spacing: 12) {
                infoRow(icon: "calendar", label: "Service Date", value: fullDateAndDay(date: stop.serviceDate))
                infoRow(icon: "play.circle", label: "Start", value: optionalDateText(stop.startTime))
                infoRow(icon: "stop.circle", label: "End", value: optionalDateText(stop.endTime))
                infoRow(icon: "clock", label: "Estimated Duration", value: displayMinAsMinAndHour(min: stop.estimatedDuration))
                infoRow(icon: "tag", label: "Stop Type", value: stop.type)
            }
        }
    }

    private func locationSection(_ stop: ServiceStop) -> some View {
        sectionCard(title: "Customer & Location", systemImage: "person.text.rectangle") {
            VStack(spacing: 12) {
                if let location = VM.location {
                    infoRow(icon: "house", label: "Location", value: location.nickName.isEmpty ? location.customerName : location.nickName)
                    infoRow(icon: "mappin.and.ellipse", label: "Address", value: displayAddress(location.address))
                    infoRow(icon: "key", label: "Gate Code", value: blankAware(location.gateCode))
                    infoRow(icon: "person", label: "Main Contact", value: blankAware(location.mainContact.name))
                    infoRow(icon: "phone", label: "Phone", value: blankAware(location.mainContact.phoneNumber))
                    infoRow(icon: "envelope", label: "Email", value: blankAware(location.mainContact.email))
                    infoRow(icon: "note.text", label: "Location Notes", value: blankAware(location.notes ?? ""))
                    infoRow(icon: "text.bubble", label: "Contact Notes", value: blankAware(location.mainContact.notes ?? ""))
                } else {
                    infoRow(icon: "mappin.and.ellipse", label: "Address", value: displayAddress(stop.address))
                    infoRow(icon: "person", label: "Customer", value: stop.customerName)
                }
            }
        }
    }

    private func serviceDescriptionSection(_ stop: ServiceStop) -> some View {
        let noteText = (stop.serviceNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        return sectionCard(title: "Planned Work", systemImage: "text.alignleft") {
            VStack(alignment: .leading, spacing: 12) {
                Text(blankAware(stop.description))
                    .font(.subheadline)
                    .foregroundStyle(stop.description.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !noteText.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Service Notes", systemImage: "text.bubble")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(noteText)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func linkedRecordsSection(_ stop: ServiceStop) -> some View {
        sectionCard(title: "Linked Records", systemImage: "link") {
            VStack(spacing: 12) {
                infoRow(icon: "number", label: "Service Stop", value: stop.internalId.isEmpty ? stop.id : stop.internalId)
                infoRow(icon: "doc.text", label: "Work Order", value: blankAware(stop.jobName ?? stop.jobId))
                infoRow(icon: "repeat", label: "Recurring Stop", value: blankAware(stop.recurringServiceStopId))
                infoRow(icon: "building.2", label: "Company", value: blankAware(stop.companyName))
            }
        }
    }

    private func taskSection(_ stop: ServiceStop) -> some View {
        sectionCard(title: "Tasks", systemImage: "checklist") {
            ServiceStopTaskView(
                dataService: dataService,
                taskList: $VM.taskList,
                serviceStopId: stop.id
            )
            .frame(minHeight: 220)
        }
    }

    private var observationsSection: some View {
        sectionCard(title: "Observations", systemImage: "eye") {
            if stopData.observation.isEmpty {
                emptyState(
                    title: "No observations recorded.",
                    systemImage: "text.bubble"
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(stopData.observation, id: \.self) { observation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.poolGreen)
                                .padding(.top, 2)

                            Text(observation)
                                .font(.subheadline)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var waterEquipmentSection: some View {
        sectionCard(title: "Water Readings & Dosages", systemImage: "drop") {
            waterRecap
        }
    }

    private var equipmentSection: some View {
        sectionCard(title: "Equipment", systemImage: "wrench.and.screwdriver") {
            if VM.listOfEquipment.isEmpty {
                emptyState(
                    title: "No equipment linked to this service location.",
                    systemImage: "wrench.and.screwdriver"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(VM.listOfEquipment) { equipment in
                        HStack(spacing: 12) {
                            Image(systemName: "wrench.adjustable")
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.secondary)
                                .background(.thinMaterial, in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(equipment.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(equipment.status.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var photosSection: some View {
        sectionCard(title: "Photos", systemImage: "photo.on.rectangle") {
            if VM.loadedImages.isEmpty {
                emptyState(
                    title: "No photos uploaded for this stop.",
                    systemImage: "photo"
                )
            } else {
                DripDropStoredImageRow(images: VM.loadedImages)
            }
        }
    }
}

// MARK: - Edit

extension ServiceStopDetailView3 {
    private func prepareEditState(from stop: ServiceStop) {
        editServiceDate = stop.serviceDate
        editTechnicianId = stop.techId
        editDescription = stop.description
        editEstimatedDuration = max(stop.estimatedDuration, 0)
        editOperationStatus = stop.operationStatus
        editBillingStatus = stop.billingStatus
    }

    private func editSheet(_ stop: ServiceStop) -> some View {
        NavigationStack {
            Form {
                Section("Schedule") {
                    DatePicker("Service Date", selection: $editServiceDate, displayedComponents: .date)

                    Picker("Technician", selection: $editTechnicianId) {
                        if VM.companyUsers.isEmpty || !VM.companyUsers.contains(where: { $0.userId == stop.techId }) {
                            Text(stop.tech.isEmpty ? "Unassigned" : stop.tech).tag(stop.techId)
                        }

                        ForEach(VM.companyUsers) { user in
                            Text(user.userName).tag(user.userId)
                        }
                    }

                    Stepper(value: $editEstimatedDuration, in: 0...720, step: 5) {
                        HStack {
                            Text("Estimated")
                            Spacer()
                            Text(displayMinAsMinAndHour(min: editEstimatedDuration))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Status") {
                    Picker("Operation", selection: $editOperationStatus) {
                        ForEach(ServiceStopOperationStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Picker("Billing", selection: $editBillingStatus) {
                        ForEach(ServiceStopBillingStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Planned Work") {
                    TextEditor(text: $editDescription)
                        .frame(minHeight: 130)
                }
            }
            .navigationTitle("Edit Service Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditSheet = false
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving" : "Save") {
                        saveEdits(originalStop: stop)
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveEdits(originalStop: ServiceStop) {
        guard let company = masterDataManager.currentCompany, let user = masterDataManager.user else {
            alertMessage = "Missing company or user context."
            showAlert = true
            return
        }

        let selectedUser = selectedCompanyUser(fallbackStop: originalStop)

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                let typeFields = ServiceStopTypeFields(
                    typeId: originalStop.typeId,
                    type: originalStop.type,
                    typeImage: originalStop.typeImage
                )

                try await dataService.updateScheduledJobServiceStop(
                    companyId: company.id,
                    serviceStop: originalStop,
                    serviceDate: editServiceDate,
                    companyUser: selectedUser,
                    description: editDescription,
                    estimatedDuration: editEstimatedDuration,
                    manualPayOverrideCents: originalStop.manualPayOverrideCents,
                    manualPayOverrideNotes: originalStop.manualPayOverrideNotes,
                    serviceStopTypeFields: typeFields
                )

                if editOperationStatus != originalStop.operationStatus {
                    try await VM.updateServicestopOperationStatus(
                        companyId: company.id,
                        currentUserId: user.id,
                        stop: originalStop,
                        operationStatus: editOperationStatus
                    )
                }

                if editBillingStatus != originalStop.billingStatus {
                    try await dataService.updateServicestopBillingStatus(
                        companyId: company.id,
                        serviceStop: originalStop,
                        billingStatus: editBillingStatus
                    )
                }

                var updatedStop = originalStop
                updatedStop.serviceDate = editServiceDate
                updatedStop.techId = selectedUser.userId
                updatedStop.tech = selectedUser.userName
                updatedStop.description = editDescription
                updatedStop.estimatedDuration = editEstimatedDuration
                updatedStop.operationStatus = editOperationStatus
                updatedStop.billingStatus = editBillingStatus

                serviceStop = updatedStop
                title = updatedStop.customerName
                showEditSheet = false
                alertMessage = "Service stop updated."
                showAlert = true
            } catch {
                alertMessage = "Unable to update this service stop."
                showAlert = true
                print("ServiceStopDetailView3 save error", error)
            }
        }
    }

    private func deleteServiceStop(_ stop: ServiceStop) {
        guard let company = masterDataManager.currentCompany else {
            alertMessage = "Missing company context."
            showAlert = true
            return
        }

        Task {
            isDeleting = true
            defer { isDeleting = false }

            do {
                try await dataService.deleteServiceStop(companyId: company.id, serviceStop: stop)
                dismiss()
            } catch {
                alertMessage = "Unable to delete this service stop."
                showAlert = true
                print("ServiceStopDetailView3 delete error", error)
            }
        }
    }

    private func selectedCompanyUser(fallbackStop: ServiceStop) -> CompanyUser {
        if let selected = VM.companyUsers.first(where: { $0.userId == editTechnicianId }) {
            return selected
        }

        return CompanyUser(
            id: fallbackStop.techId,
            userId: fallbackStop.techId,
            userName: fallbackStop.tech.isEmpty ? "Unassigned" : fallbackStop.tech,
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .employee
        )
    }
}

// MARK: - Water Recap

extension ServiceStopDetailView3 {
    @ViewBuilder
    private var waterRecap: some View {
        if VM.bodiesOfWater.isEmpty {
            emptyState(
                title: "No bodies of water linked to this location.",
                systemImage: "drop"
            )
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VM.bodiesOfWater) { bow in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(bow.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            ChemReadingRecap(
                                dataService: dataService,
                                templates: VM.readingTemplates,
                                BOW: bow
                            )

                            ChemDosageRecap(
                                dataService: dataService,
                                templates: VM.dosageTemplates,
                                BOW: bow
                            )
                        }
                        .frame(width: 210)
                        .padding(12)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }
}

// MARK: - Reusable UI

extension ServiceStopDetailView3 {
    private var metricColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.systemBackground).opacity(0.92))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private func sectionCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.poolBlue)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            content()
        }
        .padding(16)
        .background(cardBackground)
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 30, height: 30)
                .background(Color.poolBlue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(cardBackground)
    }

    private func detailLine(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(value == "Not provided" ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private func statusChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func emptyState(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Formatting

extension ServiceStopDetailView3 {
    private func displayAddress(_ address: Address) -> String {
        "\(address.streetAddress) \(address.city), \(address.state) \(address.zip)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func optionalDateText(_ date: Date?) -> String {
        guard let date else { return "Not recorded" }
        return shortDateAndTime(date: date)
    }

    private func actualDurationText(_ stop: ServiceStop) -> String {
        if let start = stop.startTime, let end = stop.endTime {
            return displayMinAsMinAndHour(min: minBetween(start: start, end: end))
        }

        if stop.duration > 0 {
            return displayMinAsMinAndHour(min: stop.duration)
        }

        return "Not recorded"
    }

    private func blankAware(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not provided" : value
    }

    private func operationStatusColor(_ status: ServiceStopOperationStatus) -> Color {
        switch status {
        case .finished:
            return .poolGreen
        case .skipped:
            return .orange
        case .notFinished:
            return .poolBlue
        }
    }

    private func billingStatusColor(_ status: ServiceStopBillingStatus) -> Color {
        switch status {
        case .paid:
            return .poolGreen
        case .invoiced:
            return .poolBlue
        case .notInvoiced:
            return .secondary
        }
    }
}

private enum OfficeServiceStopDetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case work = "Work"
    case water = "Water"
    case photos = "Photos"

    var id: String { rawValue }
}
