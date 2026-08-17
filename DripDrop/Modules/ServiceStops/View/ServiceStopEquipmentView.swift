//
//  ServiceStopEquipmentView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI

struct ServiceStopEquipmentView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    
    let serviceStop: ServiceStop
    @Binding var stopData: StopData
    
    @State private var addNewEquipment: Bool = false
    
    private var equipmentList: [Equipment] {
        VM.listOfEquipment.filter { $0.bodyOfWaterId == VM.selectedBOW?.id }
    }
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                bodyOfWaterPicker
                ScrollView(showsIndicators: false) {
                    equipmentSection
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .padding(.top)
        }
        .task {
            ensureBodyOfWaterSelection()
            if let currentCompany = masterDataManager.currentCompany,
               let BOW = VM.selectedBOW {
                try? await VM.getAllEquipmentFromBodyOfWater(
                    companyId: currentCompany.id,
                    bodyOfWater: BOW
                )
            }
        }
        .onChange(of: VM.bodiesOfWater) { _ in
            ensureBodyOfWaterSelection()
        }
        .onChange(of: VM.selectedBOW) { BOW in
            if let BOW {
                Task {
                    if serviceStop.otherCompany,
                       serviceStop.contractedCompanyId != "" {
                        try? await VM.getAllEquipmentFromBodyOfWater(
                            companyId: serviceStop.contractedCompanyId,
                            bodyOfWater: BOW
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Body Of Water Picker

extension ServiceStopEquipmentView {
    
    var bodyOfWaterPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "drop.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 32, height: 32)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Equipment Water")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(VM.selectedBOW?.name.isEmpty == false ? VM.selectedBOW?.name ?? "Select Water" : "Select Water")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if VM.bodiesOfWater.isEmpty {
                        Text("No Bodies of Water")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 220, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(VM.bodiesOfWater) { bodyOfWater in
                            equipmentBodyOfWaterChip(bodyOfWater)
                        }
                    }
                }
                .padding(.trailing, 10)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func equipmentBodyOfWaterChip(_ bodyOfWater: BodyOfWater) -> some View {
        let isSelected = VM.selectedBOW?.id == bodyOfWater.id

        return Button {
            VM.selectedBOW = bodyOfWater
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(bodyOfWater.name.isEmpty ? "Unnamed Water" : bodyOfWater.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(equipmentBodyOfWaterMetaText(bodyOfWater))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.82) : Color.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minWidth: 126, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.poolGreen : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.poolGreen : Color(.separator).opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func equipmentBodyOfWaterMetaText(_ bodyOfWater: BodyOfWater) -> String {
        let gallons = bodyOfWater.gallons.trimmingCharacters(in: .whitespacesAndNewlines)
        let material = bodyOfWater.material.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            gallons.isEmpty ? "" : "\(gallons) gal",
            material,
        ].filter { !$0.isEmpty }

        return parts.isEmpty ? "No details" : parts.joined(separator: " · ")
    }

    @MainActor
    private func ensureBodyOfWaterSelection() {
        guard !VM.bodiesOfWater.isEmpty else { return }

        if let selected = VM.selectedBOW,
           VM.bodiesOfWater.contains(where: { $0.id == selected.id }) {
            return
        }

        VM.selectedBOW = VM.bodiesOfWater.first
    }
}

// MARK: - Equipment Section

extension ServiceStopEquipmentView {
    
    var equipmentSection: some View {
        VStack(spacing: 16) {
            
            if let BOW = VM.selectedBOW {
                
                ForEach(equipmentList) { datum in
                    EquipmentCard(
                        serviceStop: serviceStop,
                        equipmentId: datum.id,
                        stopData: $stopData
                    )
                }
                
                Button {
                    addNewEquipment.toggle()
                } label: {
                    HStack {
                        Spacer()
                        Text("Add New Equipment")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                }
                .sheet(isPresented: $addNewEquipment) {
                    AddEquipmentView(dataService: dataService, bodyOfWater: BOW)
                }
            }
        }
    }
}

// MARK: - Equipment Card

struct EquipmentCard: View {
    
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    
    let serviceStop: ServiceStop
    let equipmentId: String
    @Binding var stopData: StopData
    
    @State private var pressure: String = ""
    @State private var showEquipment: Bool = false
    @State private var equipmentStatus: EquipmentStatus = .operational
    @State private var showEquipmentStatus: Bool = false
    @State private var isSavingObservation: Bool = false
    @State private var observationMessage: String? = nil
    @State private var showRepairRequestSheet: Bool = false
    @State private var showJobSheet: Bool = false
    @State private var showPartApprovalSheet: Bool = false
    @State private var showRecordMaintenanceSheet: Bool = false
    @State private var showRecordRepairSheet: Bool = false
    @State private var showObservationAlert: Bool = false
    @FocusState private var pressureFieldFocused: Bool
    
    private var equipment: Equipment? {
        VM.listOfEquipment.first { $0.id == equipmentId }
    }

    private var needsTechnicianAttention: Bool {
        guard let equipment else { return false }
        return equipment.currentlyNeedsMaintenanceFollowUp ||
        equipmentStatus == .needsRepair ||
        equipmentStatus == .needsMaintenance ||
        equipmentStatus == .nonoperational
    }
    
    var body: some View {
        if let equipment {
            
            VStack(alignment: .leading, spacing: 14) {
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(equipment.name)
                            .font(.headline)
                        
                        Text("\(equipment.type.rawValue) • \(equipment.make) \(equipment.model)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    NavigationLink(
                        value: Route.equipmentDetailView(
                            equipment: equipment,
                            dataService: dataService
                        )
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                if needsTechnicianAttention {
                    technicianAttentionBanner(equipment: equipment)
                }

                // Status Row
                HStack {
                    Button {
                        showEquipmentStatus.toggle()
                    } label: {
                        Text(equipmentStatus.displayName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.15))
//                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()

                    equipmentActionsMenu
                }

                if let observationMessage {
                    equipmentFeedbackMessage(observationMessage)
                }

                // Filter Section
                if equipment.type == .filter {
                    filterSection(equipment: equipment)
                }

                if equipment.needsService {
                    serviceScheduleSection(equipment: equipment)
                }
                
                // Info Section
                infoSection(equipment: equipment)
            }
            .ddCard()
            .sheet(isPresented: $showEquipment) {
                EditEquipmentView(dataService: dataService, equipment: equipment)
            }
            .sheet(isPresented: $showEquipmentStatus) {
                EquipmentStatusPicker(
                    dataService: dataService,
                    status: $equipmentStatus
                )
                .presentationDetents([.fraction(0.3), .fraction(0.5)])
            }
            .sheet(isPresented: $showRepairRequestSheet) {
                AddNewRepairRequest(
                    dataService: dataService,
                    isPresented: $showRepairRequestSheet,
                    customer: nil,
                    equipment: equipment,
                    description: "Repair request for \(equipment.name)"
                )
            }
            .sheet(isPresented: $showJobSheet) {
                AddNewJobView(
                    dataService: dataService,
                    customerId: equipment.customerId,
                    equipment: equipment
                )
            }
            .sheet(isPresented: $showPartApprovalSheet) {
                ServiceStopPartApprovalSheet(
                    dataService: dataService,
                    serviceStop: serviceStop,
                    equipment: equipment,
                    onCreated: { }
                )
            }
            .sheet(isPresented: $showRecordMaintenanceSheet) {
                RecordEquipmentMaintenanceView(
                    dataService: dataService,
                    equipment: equipment
                ) {
                    setObservationMessage("Maintenance recorded.", showAlert: true)
                }
            }
            .sheet(isPresented: $showRecordRepairSheet) {
                RecordEquipmentRepairView(
                    dataService: dataService,
                    equipment: equipment
                ) {
                    setObservationMessage("Repair recorded.", showAlert: true)
                }
            }
            .alert("Equipment Update", isPresented: $showObservationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(observationMessage ?? "")
            }
            .toolbar {
                if pressureFieldFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            pressureFieldFocused = false
                        }
                    }
                }
            }
            .onAppear {
                equipmentStatus = equipment.status
                if let measurement = stopData.equipmentMeasurements.first(where: { $0.equipmentId == equipment.id }) {
                    pressure = String(measurement.poundForcePerSquareInch ?? 0)
                }
            }
            .onChange(of: equipmentStatus) { status in
                guard status != equipment.status,
                      let currentCompany = masterDataManager.currentCompany else { return }

                do {
                    try VM.updateEquipmentStatus(
                        companyId: currentCompany.id,
                        serviceStop: serviceStop,
                        equipmentId: equipment.id,
                        status: status
                    )
                } catch {
                    setObservationMessage("Could not update equipment status.", showAlert: true)
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch equipmentStatus {
        case .operational: return .blue
        case .nonoperational: return .red
        case .needsRepair: return .orange
        case .needsMaintenance: return .yellow
        case .replaced: return .gray
        }
    }
    
    @ViewBuilder
    private var equipmentActionsMenu: some View {
        Menu {
            Button {
                showEquipment = true
            } label: {
                Label("Edit Equipment", systemImage: "square.and.pencil")
            }

            Divider()

            Button {
                showRepairRequestSheet = true
            } label: {
                Label("Repair Request", systemImage: "wrench.and.screwdriver")
            }

            Button {
                showJobSheet = true
            } label: {
                Label("Schedule Job", systemImage: "calendar.badge.plus")
            }

            Button {
                showPartApprovalSheet = true
            } label: {
                Label("Part Approval", systemImage: "checkmark.seal")
            }

            Divider()

            Button {
                showRecordMaintenanceSheet = true
            } label: {
                Label("Record Maintenance", systemImage: "wrench.and.screwdriver.fill")
            }

            Button {
                showRecordRepairSheet = true
            } label: {
                Label("Record Repair", systemImage: "cross.case.fill")
            }
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.poolBlue.opacity(0.12), in: Capsule())
                .foregroundStyle(Color.poolBlue)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func equipmentFeedbackMessage(_ message: String) -> some View {
        Text(message)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSuccessMessage(message) ? Color.poolGreen : Color.poolRed)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func filterSection(equipment: Equipment) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Filter Pressure")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 7) {
                        TextField("0", text: $pressure)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline.monospacedDigit())
                            .focused($pressureFieldFocused)
                            .frame(minWidth: 54, maxWidth: 86)

                        Text("PSI")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(pressureFieldFocused ? Color.poolBlue : Color(.separator).opacity(0.55), lineWidth: pressureFieldFocused ? 1.5 : 1)
                    )
                }
                .layoutPriority(1)

                Button {
                    Task { await addEquipmentObservation(equipment: equipment) }
                } label: {
                    HStack(spacing: 7) {
                        if isSavingObservation {
                            ProgressView()
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }

                        Text(isSavingObservation ? "Saving" : "Add Equipment Observation")
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(width: 136)
                    .frame(minHeight: 52)
                    .background(Color.poolBlue.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(Color.poolBlue)
                }
                .buttonStyle(.plain)
                .disabled(isSavingObservation)
            }

            if let cleanPressure = equipment.cleanFilterPressure {
                
                Divider()
                
                HStack {
                    Text("Clean Pressure")
                    Spacer()
                    Text("\(Int(cleanPressure)) PSI")
                }
                .font(.footnote)
                
                HStack {
                    Text("Dirty Level")
                    Spacer()
                    
                    let current = Int(pressure) ?? equipment.currentPressure ?? 0
                    let difference = Double(current) - Double(cleanPressure)
                    let percent = (difference / 15) * 100
                    
                    Text("\(String(format: "%.0f", percent))%")
                }
                .font(.footnote)
            }
            
            HStack {
                Text("Last Cleaned")
                Spacer()
                Text(shortDate(date: equipment.lastServiceDate))
            }
            .font(.footnote)

        }
    }

    @ViewBuilder
    private func serviceScheduleSection(equipment: Equipment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Label("Regular Service", systemImage: "calendar.badge.clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if equipment.currentlyNeedsMaintenanceFollowUp {
                    Text("Due")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }

            if let frequency = equipment.serviceFrequency,
               let every = equipment.serviceFrequencyEvery {
                serviceScheduleRow("Frequency", "\(frequency) \(every.rawValue)\(frequency == 1 ? "" : "s")")
            }

            serviceScheduleRow("Last Serviced", shortDate(date: equipment.lastServiceDate))

            if let nextServiceDate = equipment.maintenanceDueDateForFollowUp {
                serviceScheduleRow("Next Service", shortDate(date: nextServiceDate))
            } else {
                serviceScheduleRow("Next Service", "Not set")
            }
        }
        .font(.footnote)
    }

    private func serviceScheduleRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private func infoSection(equipment: Equipment) -> some View {
        VStack(spacing: 6) {
            Divider()
            

            HStack {
                Text("Installed")
                Spacer()
                if let dateInstalled = equipment.dateInstalled {
                    Text(shortDate(date: dateInstalled))
                    Text("(\(String(format: "%.1f", numberOfYearsBetween(dateInstalled, Date()))) yrs)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not set")
                        .foregroundColor(.secondary)
                }
            }
        }
        .font(.footnote)
    }

    @ViewBuilder
    private func technicianAttentionBanner(equipment: Equipment) -> some View {
        let title = technicianAttentionTitle(for: equipment)
        let detail = technicianAttentionDetail(for: equipment)
        let tint = technicianAttentionTint()

        HStack(alignment: .top, spacing: 10) {
            Image(systemName: technicianAttentionIcon(for: equipment))
                .foregroundStyle(tint)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func technicianAttentionTitle(for equipment: Equipment) -> String {
        switch equipmentStatus {
        case .needsMaintenance:
            return "Needs Maintenance"
        case .needsRepair:
            return "Needs Repair"
        case .nonoperational:
            return "Non-Operational"
        case .replaced:
            return "Replaced"
        case .operational:
            return equipment.currentlyNeedsMaintenanceFollowUp ? "Maintenance Due Soon" : "Equipment Needs Attention"
        }
    }

    private func technicianAttentionDetail(for equipment: Equipment) -> String {
        switch equipmentStatus {
        case .needsMaintenance:
            return maintenanceTimingText(for: equipment)
        case .needsRepair:
            return "Repair is needed. Create a repair request or schedule a job for this equipment."
        case .nonoperational:
            return "Equipment is not operational. Repair or replace it before normal service."
        case .replaced:
            return "Equipment has been replaced."
        case .operational:
            if equipment.currentlyNeedsMaintenanceFollowUp {
                return maintenanceTimingText(for: equipment)
            }
            return equipment.status.displayName
        }
    }

    private func technicianAttentionIcon(for equipment: Equipment) -> String {
        switch equipmentStatus {
        case .needsMaintenance:
            return "wrench.and.screwdriver"
        case .needsRepair, .nonoperational:
            return "exclamationmark.triangle.fill"
        case .replaced:
            return "arrow.triangle.2.circlepath"
        case .operational:
            return equipment.currentlyNeedsMaintenanceFollowUp ? "calendar.badge.clock" : "exclamationmark.triangle.fill"
        }
    }

    private func technicianAttentionTint() -> Color {
        switch equipmentStatus {
        case .needsMaintenance, .needsRepair:
            return .orange
        case .nonoperational:
            return .red
        case .replaced:
            return .gray
        case .operational:
            return .orange
        }
    }

    private func maintenanceTimingText(for equipment: Equipment) -> String {
        guard let nextServiceDate = equipment.maintenanceDueDateForFollowUp else {
            return "Maintenance is required. No due date is set."
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: nextServiceDate)
        let daysOverdue = calendar.dateComponents([.day], from: dueDay, to: today).day ?? 0

        if daysOverdue > 0 {
            return "Maintenance overdue by \(maintenanceIntervalText(for: daysOverdue)). Due \(shortDate(date: nextServiceDate))."
        } else if daysOverdue == 0 {
            return "Maintenance due today."
        } else {
            return "Maintenance due in \(maintenanceIntervalText(for: abs(daysOverdue))). Due \(shortDate(date: nextServiceDate))."
        }
    }

    private func maintenanceIntervalText(for days: Int) -> String {
        if days >= 60 {
            return pluralized(max(1, days / 30), unit: "month")
        } else if days >= 14 {
            return pluralized(max(1, days / 7), unit: "week")
        }

        return pluralized(max(1, days), unit: "day")
    }

    private func pluralized(_ value: Int, unit: String) -> String {
        "\(value) \(unit)\(value == 1 ? "" : "s")"
    }

    private func targetCompanyId() -> String? {
        if serviceStop.otherCompany, let mainCompanyId = serviceStop.mainCompanyId {
            return mainCompanyId
        }

        return masterDataManager.currentCompany?.id
    }

    private func isSuccessMessage(_ message: String) -> Bool {
        [
            "Equipment reading added.",
            "Maintenance recorded.",
            "Repair recorded."
        ].contains(message)
    }

    private func setObservationMessage(_ message: String, showAlert: Bool = false) {
        observationMessage = message
        showObservationAlert = showAlert
    }

    private func addEquipmentObservation(equipment: Equipment) async {
        let trimmedPressure = pressure.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pressureValue = Int(trimmedPressure) else {
            setObservationMessage("Enter a valid PSI reading.", showAlert: true)
            return
        }

        guard let companyId = targetCompanyId() else {
            setObservationMessage("No company selected.", showAlert: true)
            return
        }

        isSavingObservation = true
        observationMessage = nil

        var nextStatus = equipmentStatus
        if let cleanPressure = equipment.cleanFilterPressure,
           pressureValue - cleanPressure >= 15 {
            nextStatus = .needsMaintenance
            equipmentStatus = nextStatus
        }

        let measurement = EquipmentMeasurements(
            id: UUID().uuidString,
            equipmentId: equipment.id,
            date: Date(),
            status: nextStatus,
            poundForcePerSquareInch: pressureValue,
            revolutionsPerMinute: nil
        )

        do {
            stopData.equipmentMeasurements.removeAll { $0.equipmentId == equipment.id }
            stopData.equipmentMeasurements.append(measurement)

            try await VM.createEquipmentMeasurment(
                companyId: companyId,
                equipmentId: equipment.id,
                measurment: measurement
            )
            try dataService.updateEquipmentCurrentPressure(
                companyId: companyId,
                equipmentId: equipment.id,
                currentPressure: pressureValue
            )

            if nextStatus != equipment.status {
                try VM.updateEquipmentStatus(
                    companyId: companyId,
                    serviceStop: serviceStop,
                    equipmentId: equipment.id,
                    status: nextStatus
                )
            }

            VM.EquipmentReadings[equipment] = measurement
            setObservationMessage("Equipment reading added.", showAlert: true)
        } catch {
            setObservationMessage("Could not save equipment observation.", showAlert: true)
        }

        isSavingObservation = false
    }
}
private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddSectionTitle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}


/*
    struct ServiceStopEquipmentView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel

    let serviceStop:ServiceStop
    @Binding var stopData : StopData

    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date()
    )
    @State var addNewEquipment:Bool = false

    private var equipmentList: [Equipment] {
        VM.listOfEquipment.filter( {$0.bodyOfWaterId == VM.selectedBOW?.id})
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing:0){
                bodyOfWaterPicker
                ScrollView{
                    equipmentCheckUp
                }
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
            }
        }
        .fontDesign(.monospaced)
        .task {
            if let currentCompany = masterDataManager.currentCompany, let BOW = VM.selectedBOW {
                Task{
                    do {
                        try await VM.getAllEquipmentFromBodyOfWater(companyId: currentCompany.id, bodyOfWater: BOW)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: VM.selectedBOW, perform: { BOW in
            if let currentCompany = masterDataManager.currentCompany, let BOW {
                Task{
                    do {
                        if serviceStop.otherCompany {
                            if serviceStop.contractedCompanyId != "" {
                                try await VM.getAllEquipmentFromBodyOfWater(companyId: serviceStop.contractedCompanyId, bodyOfWater: BOW)
                            }
                        }
                        
                    } catch {
                        print(error)
                    }
                }
            }
        })
    }
    }
    extension ServiceStopEquipmentView {
    var bodyOfWaterPicker: some View {
        HStack(spacing: 0){
            ScrollView(.horizontal,showsIndicators: false){
                HStack{
                    if VM.bodiesOfWater.isEmpty {
                        Text("No Bodies of Water")
                    } else {
                        ForEach(VM.bodiesOfWater) { BOW in
                            Button(action: {
                                VM.selectedBOW = BOW
                            }, label: {
                                HStack(spacing: 6) {
                                    Image(systemName: VM.selectedBOW == BOW ? "drop.fill" : "drop")
                                    Text("\(BOW.name)")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Group {
                                        if VM.selectedBOW == BOW {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.poolGreen)
                                        } else {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.gray.opacity(0.4))
                                        }
                                    }
                                )
                                .foregroundStyle(VM.selectedBOW == BOW ? Color.white : Color.primary)
                            })
                            .padding(.horizontal,4)
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
            .padding(8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    var equipmentCheckUp: some View {
        VStack{
            
            if let BOW = VM.selectedBOW {
                Rectangle()
                    .frame(height: 1)
                ForEach(equipmentList) { datum in
                    serviceStopEquipmentCheck( serviceStop: serviceStop,equipmentId: datum.id, stopData: $stopData)
                    Rectangle()
                        .frame(height: 1)
                }
                Button(action: {
                    addNewEquipment.toggle()
                }, label: {
                    HStack{
                        Text("Add New Equipment")
                    }
                    .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $addNewEquipment, onDismiss: {
                    print("On Dismiss of New Equipment")
                }, content: {
                    AddEquipmentView(dataService: dataService, bodyOfWater: BOW)
                })
            }
        }
    }
    }

    struct serviceStopEquipmentCheck: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel

    @State var serviceStop:ServiceStop
    @State var equipmentId:String
    @Binding var stopData : StopData

    @State var qualityCheck:Bool = false
    @State var pressure:String = ""
    @State var showEquipment:Bool = false

    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var equipmentStatus:EquipmentStatus = .operational
    @State var showEquipmentStatus:Bool = false
    @FocusState var pressureInput:Bool
    private var equipment:Equipment? {
        VM.listOfEquipment.first { $0.id == equipmentId }
    }
    var body: some View {
        if let equipment {
            VStack{
                HStack{
                    Button(action: {
                        showEquipment.toggle()
                    }, label: {
                        Text("Edit")
                            .modifier(AddButtonModifier())
                    })
                    .padding(.leading,8)
                    .sheet(isPresented: $showEquipment, content: {
                        EditEquipmentView(dataService: dataService, equipment: equipment)
                    })
                    Spacer()
                    Text("\(equipment.name)")
                    Spacer()
                    NavigationLink(value: Route.equipmentDetailView(equipment: equipment, dataService: dataService), label: {
                        HStack{
                            Text("Details")
                            Image(systemName: "chevron.right")
                        }
                        .modifier(RedLinkModifier())
                    })
                }
                Divider()
                HStack{
                    Text("\(equipment.type.rawValue)")
                    Text("\(equipment.make)")
                    Text("\(equipment.model)")
                    Spacer()
                }
                HStack{
                    Button(action: {
                        showEquipmentStatus.toggle()
                    }, label: {
                        switch equipmentStatus {
                        case .operational:
                            Text(equipmentStatus.displayName)
                                .modifier(BlueButtonModifier())
                        case .nonoperational:
                            Text(equipmentStatus.displayName)
                                .modifier(DismissButtonModifier())
                        case .needsRepair:
                            Text(equipmentStatus.displayName)
                                .modifier(OrangeButtonModifier())
                        case .needsMaintenance:
                            Text(equipmentStatus.displayName)
                                .modifier(YellowButtonModifier())
                        case .replaced:
                            Text(equipmentStatus.displayName)
                                .modifier(DismissButtonModifier())
                        }
                    })
                    .sheet(isPresented: $showEquipmentStatus, content: {
                        EquipmentStatusPicker(dataService: dataService, status: $equipmentStatus)
                            .presentationDetents([.fraction(0.3),.fraction(0.5)])
                    })
                    Spacer()
                }
                if equipment.type == .filter {
                    HStack{
                        Text("Pressure: ")
                        TextField(
                            "Pressure",
                            text: $pressure
                        )
                        .keyboardType(.decimalPad)
                        .foregroundColor(Color.poolBlack)
                        .modifier(TextFieldModifier())
                        .focused($pressureInput)
                        Button(action: {
                            qualityCheck.toggle()
                        },
                               label: {
                            Image(systemName: qualityCheck ? "checkmark.square.fill" : "square")
                                .modifier(SubmitButtonModifier())
                        })
                    }
                    .modifier(ListButtonModifier())
                    .modifier(OutLineButtonModifier())
                }
                
                graphicView
            }
            .padding(10)
            
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
            .onAppear(perform: {
                equipmentStatus = equipment.status
                if let measurement = stopData.equipmentMeasurements.first(where: {$0.equipmentId == equipment.id}) {
                    pressure = String(measurement.poundForcePerSquareInch ?? 0)
                } else {
                    pressure = ""
                }
            })
            .onChange(of: equipmentStatus, perform: { status in
                if status != equipment.status {
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            print("Updating Equipment Status: \(status)")
                            try VM.updateEquipmentStatus(companyId: currentCompany.id, serviceStop: serviceStop, equipmentId: equipment.id, status: status)
                        } catch {
                            print("Error")
                            print(error)
                        }
                    }
                } else {
                    print("Status Is Same As Received")
                }
            })
            .onChange(
                of: pressure,
                perform: { datum in
                    Task{
                        if equipment.type == .filter  {
                            if datum != "" {
                                if datum.isNumber {
                                    print("Add Update")
                                    if let company = masterDataManager.currentCompany {
                                        do {
                                            let measurement = EquipmentMeasurements(
                                                id: UUID().uuidString,
                                                equipmentId: equipment.id,
                                                date: Date(),
                                                status: equipmentStatus,
                                                poundForcePerSquareInch: Int(datum)
                                            )
                                            if let currentPressure = equipment.currentPressure{
                                                let difference = Int(datum)! - currentPressure
                                                if difference > 15 {
                                                    equipmentStatus = .needsMaintenance
                                                }
                                            }
                                            stopData.equipmentMeasurements.removeAll(where: { $0.equipmentId == equipment.id })
                                            stopData.equipmentMeasurements.append(measurement)
                                            
                                            if serviceStop.otherCompany {
                                                if let mainCompanyId = serviceStop.mainCompanyId {
                                                    
                                                    try await VM.createEquipmentMeasurment(
                                                        companyId: mainCompanyId,
                                                        equipmentId: equipment.id,
                                                        measurment: measurement
                                                    )
                                                }
                                            } else {
                                                try await VM.createEquipmentMeasurment(
                                                    companyId: company.id,
                                                    equipmentId: equipment.id,
                                                    measurment: measurement
                                                )
                                            }
                                            VM.EquipmentReadings[equipment] = measurement
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                })
        }
    }
    }

    extension serviceStopEquipmentCheck {
    var graphicView: some View {
        
        VStack{
            if let equipment {
                if equipment.type == .filter {
                    
                    if let cleanPressure  = equipment.cleanFilterPressure  {
                        HStack{
                            Text("Clean Preasures: ")
                                .bold()
                            Spacer()
                            Text("\(String(format: "%.0f", Double(cleanPressure ))) PSI")
                        }
                        if pressure == "" {
                            if let currentPressure = equipment.currentPressure {
                                let difference = Double(Int(currentPressure) - cleanPressure)
                                HStack{
                                    Text("Dirty: ")
                                        .bold()
                                    Spacer()
                                    Text("\(String(format: "%.0f",(difference/15)*100)) %")
                                }
                            }
                        } else {
                            let difference = Double(( Int(pressure) ?? 0) - cleanPressure)
                            HStack{
                                Text("Dirty: ")
                                    .bold()
                                Spacer()
                                Text("\(String(format: "%.0f",(difference/15)*100)) %")
                            }
                        }
                    }
                    Divider()
                    HStack{
                        Text("Last Cleaned: ")
                            .bold()
                        Spacer()
                        Text(shortDate(date:equipment.lastServiceDate))
                    }
                    HStack{
                        Text("Installed: ")
                            .bold()
                        Spacer()
                        if let dateInstalled = equipment.dateInstalled {
                            Text(shortDate(date: dateInstalled))
                            Text("(\(String(format: "%.1f", numberOfYearsBetween(dateInstalled, Date()))) years)")
                                .font(.footnote)
                        } else {
                            Text("Not set")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
            }
        }
    }
}
*/
