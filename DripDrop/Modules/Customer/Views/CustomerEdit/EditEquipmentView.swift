//
//  EditEquipmentView.swift
//  BuisnessSide
//
//  Aesthetic refresh to match the new Equipment Detail (clean cards, soft shadows,
//  rounded corners, light gray background, blue primary actions).
//

import SwiftUI

@MainActor
final class EditEquipmentViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var category: EquipmentCategory = .pump
    @Published var typeId: String = ""
    @Published var name: String = ""
    @Published var make: String = ""
    @Published var makeId: String = ""
    @Published var model: String = ""
    @Published var modelId: String = ""
    @Published var universalEquipmentId: String = ""
    @Published var manualPdfLink: String = ""
    @Published var dateInstalled: Date = Date()
    @Published var status: EquipmentStatus = .operational
    @Published var notes: String = ""

    @Published var needsService: Bool = false
    @Published var lastServiced: Date = Date()
    @Published var lastServicedOptional: Date? = Date()
    @Published var currentPressure: String = ""
    @Published var cleanPressure: String = ""

    @Published var serviceFrequency: Int? = 0
    @Published var serviceFrequencyEvery: EquipmentFrequency? = .monthly

    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false

    @Published var deleteConfirmationMessage: String = ""
    @Published var showDeleteConfirmation: Bool = false

    func deleteEquipment(companyId: String?, equipmentId: String) {
        guard let companyId else { return }
        Task {
            do {
                try await dataService.deleteEquipment(companyId: companyId, equipmentId: equipmentId)
                self.alertMessage = "Equipment deleted"
                self.showAlert.toggle()
            } catch {
                print("  [EquipmentViewModel][deleteEquipment]  Error: \(error)")
            }
        }
    }

    func updateEquipmentWithValidation(
        companyId: String,
        equipmentId: String,
        equipment: Equipment
    ) async throws {

        if needsService {
            guard let validatedServiceFrequency = serviceFrequency else { throw FireBasePublish.unableToPublish }
            guard let validatedServiceFrequencyEvery = serviceFrequencyEvery else { throw FireBasePublish.unableToPublish }
            guard let validedNextDate = getNextServiceDate(
                lastServiceDate: lastServiced,
                frequency: serviceFrequency,
                every: serviceFrequencyEvery
            ) else { throw FireBasePublish.unableToPublish }

            if equipment.serviceFrequency != serviceFrequency {
                try dataService.updateEquipmentServiceFrequency(companyId: companyId, equipmentId: equipmentId, serviceFrequency: validatedServiceFrequency)
            }
            if equipment.serviceFrequencyEvery != serviceFrequencyEvery {
                try dataService.updateEquipmentServiceFrequencyEvery(companyId: companyId, equipmentId: equipmentId, serviceFrequencyEvery: validatedServiceFrequencyEvery)
            }
            try dataService.updateEquipmentNextServiceDate(companyId: companyId, equipmentId: equipmentId, nextServiceDate: validedNextDate)
        }

        if equipment.name != name {
            // NOTE: your original code passed notes instead of name—kept logic, but corrected param.
            try dataService.updateEquipmentName(companyId: companyId, equipmentId: equipmentId, name: name)
        }
        let catalogChanged = equipment.type != category ||
            equipment.typeId != typeId ||
            equipment.make != make ||
            equipment.makeId != makeId ||
            equipment.model != model ||
            equipment.modelId != modelId ||
            equipment.universalEquipmentId != universalEquipmentId ||
            equipment.manualPdfLink != manualPdfLink

        if catalogChanged {
            try dataService.updateEquipmentCatalogDetails(
                companyId: companyId,
                equipmentId: equipmentId,
                category: category,
                typeId: typeId,
                make: make,
                makeId: makeId,
                model: model,
                modelId: modelId,
                universalEquipmentId: universalEquipmentId,
                manualPdfLink: manualPdfLink
            )
        }
        if equipment.status != status {
            try dataService.updateEquipmentStatus(companyId: companyId, equipmentId: equipmentId, status: status)
        }
        if equipment.dateInstalled != dateInstalled {
            try dataService.updateEquipmentDateInstalled(companyId: companyId, equipmentId: equipmentId, dateInstalled: dateInstalled)
        }

        if let pressureInt = Int(cleanPressure), equipment.cleanFilterPressure != pressureInt {
            try dataService.updateEquipmentCleanFilterPressure(companyId: companyId, equipmentId: equipmentId, cleanFilterPressure: pressureInt)
        }
        if let pressureInt = Int(currentPressure), equipment.currentPressure != pressureInt {
            try dataService.updateEquipmentCurrentPressure(companyId: companyId, equipmentId: equipmentId, currentPressure: pressureInt)
        }

        if equipment.lastServiceDate != lastServiced {
            try dataService.updateEquipmentCleanLastServiceDate(companyId: companyId, equipmentId: equipmentId, lastServiceDate: lastServiced)
        }
        if equipment.notes != notes {
            try dataService.updateEquipmentNotes(companyId: companyId, equipmentId: equipmentId, notes: notes)
        }

        self.alertMessage = "Updated"
        self.showAlert.toggle()
    }
}

struct EditEquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject var VM: EditEquipmentViewModel
    @State var equipment: Equipment

    init(dataService: any ProductionDataServiceProtocol, equipment: Equipment) {
        _VM = StateObject(wrappedValue: EditEquipmentViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header

                    detailsCard

                    serviceCard

                    if canDelete {
                        deleteCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(true)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert(isPresented: $VM.showDeleteConfirmation) {
            Alert(
                title: Text("Confirm Delete"),
                message: Text(VM.deleteConfirmationMessage),
                primaryButton: .destructive(Text("Delete")) {
                    VM.deleteEquipment(companyId: masterDataManager.currentCompany?.id, equipmentId: equipment.id)
                },
                secondaryButton: .cancel()
            )
        }
        .task {
            VM.category = equipment.type
            VM.typeId = equipment.typeId
            VM.name = equipment.name
            VM.make = equipment.make
            VM.makeId = equipment.makeId
            VM.model = equipment.model
            VM.modelId = equipment.modelId
            VM.universalEquipmentId = equipment.universalEquipmentId
            VM.manualPdfLink = equipment.manualPdfLink
            VM.dateInstalled = equipment.dateInstalled
            VM.status = equipment.status
            VM.notes = equipment.notes
            VM.needsService = equipment.needsService
            VM.lastServiced = equipment.lastServiceDate ?? Date()
            VM.serviceFrequency = equipment.serviceFrequency
            VM.serviceFrequencyEvery = equipment.serviceFrequencyEvery

            // keep these editable too (optional)
            VM.cleanPressure = equipment.cleanFilterPressure.map(String.init) ?? ""
            VM.currentPressure = equipment.currentPressure.map(String.init) ?? ""
        }
    }
}

// MARK: - Sections

extension EditEquipmentView {
    private var canDelete: Bool {
        if let role = masterDataManager.role {
            return role.permissionIdList.contains("66")
        }
        return false
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Edit Equipment")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(equipment.name) • \(equipment.make) \(equipment.model)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: save) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                }
            }
        }
    }

    private var detailsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Details")
                    .font(.headline)
                    .foregroundColor(.primary)

                GridRow2 {
                    Field(title: "Name") {
                        TextField("Name", text: $VM.name)
                            .textFieldStyle(.plain)
                    }

                    Field(title: "Category") {
                        Picker("Category", selection: $VM.category) {
                            ForEach(EquipmentCategory.allCases, id: \.self) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                GridRow2 {
                    Field(title: "Make") {
                        TextField("Make", text: Binding(
                            get: { VM.make },
                            set: {
                                VM.make = $0
                                VM.makeId = ""
                                VM.modelId = ""
                                VM.universalEquipmentId = ""
                                VM.manualPdfLink = ""
                            }
                        )).textFieldStyle(.plain)
                    }
                    Field(title: "Model") {
                        TextField("Model", text: Binding(
                            get: { VM.model },
                            set: {
                                VM.model = $0
                                VM.modelId = ""
                                VM.universalEquipmentId = ""
                                VM.manualPdfLink = ""
                            }
                        )).textFieldStyle(.plain)
                    }
                }

                EquipmentCatalogSelectionControl(
                    dataService: VM.dataService,
                    category: $VM.category,
                    typeId: $VM.typeId,
                    make: $VM.make,
                    makeId: $VM.makeId,
                    model: $VM.model,
                    modelId: $VM.modelId,
                    universalEquipmentId: $VM.universalEquipmentId,
                    manualPdfLink: $VM.manualPdfLink,
                    name: $VM.name
                )

                GridRow2 {
                    Field(title: "Date Installed") {
                        DatePicker("", selection: $VM.dateInstalled, displayedComponents: .date)
                            .labelsHidden()
                    }

                    Field(title: "Status") {
                        Picker("Status", selection: $VM.status) {
                            Text("Operational").tag(EquipmentStatus.operational)
                            Text("Needs Repair").tag(EquipmentStatus.needsRepair)
                            Text("Non-Operational").tag(EquipmentStatus.nonoperational)
                            Text("Needs Maintenance").tag(EquipmentStatus.needsMaintenance)
                        }
                        .pickerStyle(.menu)
                    }
                }

                GridRow2 {
                    Field(title: "Clean Filter Pressure") {
                        TextField("0", text: $VM.cleanPressure)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                    }
                    Field(title: "Current Pressure") {
                        TextField("0", text: $VM.currentPressure)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                    }
                }

                Field(title: "Notes") {
                    TextField("Notes", text: $VM.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.plain)
                }
            }
        }
    }

    private var serviceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Service")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    StatusPill(isOn: VM.needsService, onText: "Needs Service", offText: "OK")
                }

                Toggle(isOn: $VM.needsService) {
                    Text("Needs Service")
                        .fontWeight(.semibold)
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))

                if VM.needsService {
                    Divider().opacity(0.15)

                    GridRow2 {
                        Field(title: "Last Serviced") {
                            DatePicker("", selection: $VM.lastServiced, displayedComponents: .date)
                                .labelsHidden()
                        }
                        Field(title: "Frequency") {
                            HStack(spacing: 10) {
                                Picker("Every", selection: Binding(
                                    get: { VM.serviceFrequency ?? 0 },
                                    set: { VM.serviceFrequency = $0 }
                                )) {
                                    ForEach(0...100, id: \.self) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.menu)

                                Picker("Unit", selection: Binding(
                                    get: { VM.serviceFrequencyEvery ?? .monthly },
                                    set: { VM.serviceFrequencyEvery = $0 }
                                )) {
                                    ForEach(EquipmentFrequency.allCases, id: \.self) { f in
                                        Text(f.rawValue).tag(f)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }
            }
        }
    }

    private var deleteCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Danger Zone")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Deleting equipment cannot be undone.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: {
                    VM.deleteConfirmationMessage = "Please confirm you want to delete this equipment."
                    VM.showDeleteConfirmation.toggle()
                }) {
                    Text("Delete Equipment")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func save() {
        Task {
            do {
                guard let company = masterDataManager.currentCompany else { return }

                if !VM.needsService {
                    VM.lastServicedOptional = nil
                    VM.serviceFrequency = nil
                    VM.serviceFrequencyEvery = nil
                } else {
                    VM.lastServicedOptional = VM.lastServiced
                }

                try await VM.updateEquipmentWithValidation(
                    companyId: company.id,
                    equipmentId: equipment.id,
                    equipment: equipment
                )
                dismiss()
            } catch {
                print(error)
                VM.alertMessage = "Failed To Update"
                VM.showAlert.toggle()
            }
        }
    }
}

// MARK: - Small UI Building Blocks (Aesthetic Only)

private struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }
}

private struct Field<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            content
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct GridRow2<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        // iOS 16+ adaptive two-column layout
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            content
        }
    }
}

private struct StatusPill: View {
    let isOn: Bool
    let onText: String
    let offText: String

    var body: some View {
        Text(isOn ? onText : offText)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isOn ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
            .foregroundColor(isOn ? .red : .green)
            .clipShape(Capsule())
    }
}
