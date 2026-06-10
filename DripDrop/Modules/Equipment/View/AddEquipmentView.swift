//
//  AddEquipmentView.swift
//  BuisnessSide
//
//  Aesthetic refresh to match Equipment Detail:
//  - light grouped background
//  - card layout w/ soft shadows
//  - rounded inputs
//  - sticky-ish header actions (Cancel / Submit)
//  - modern sheet for equipment selector
//

import SwiftUI
import Foundation
import FirebaseFirestore
import MapKit

@MainActor
final class AddEquipmentViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var customer: Customer? = nil
    @Published private(set) var equipmentTypes: [UniversalEquipmentType] = []
    @Published var selectedEquipmentType: UniversalEquipmentType? = nil { didSet { onChangeOfSelectedType() } }

    @Published var equipmentmakes: [UniversalEquipmentMake] = []
    @Published var selectedEquipmentMake: UniversalEquipmentMake? = nil { didSet { onChangeOfSelectedMake() } }

    @Published var showAlert: Bool = false
    @Published var alertMessage: String?
    @Published var universalEquipmentList: [UniversalEquipment] = []
    @Published var selectedUniversalEquipment: UniversalEquipment? = nil

    @Published var category: EquipmentCategory = .filter
    @Published var typeId: String = ""
    @Published var name: String = ""
    @Published var showSelectEquipment: Bool = false

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
    @State var lastServicedOptional: Date? = Date()

    @Published var serviceFrequency: Int? = 6
    @Published var serviceFrequencyEvery: EquipmentFrequency? = .monthly

    func onLoad(companyId: String, bodyOfWater: BodyOfWater) async throws {
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: bodyOfWater.customerId)
        self.equipmentTypes = try await dataService.getUniversalEquipmentTypes()
    }

    func onChangeOfSelectedType() {
        Task {
            if let selectedEquipmentType {
                do {
                    self.equipmentmakes = try await dataService.getUniversalEquipmentBrandsByType(type: selectedEquipmentType)
                } catch { print(error) }
            }
        }
    }

    func onChangeOfSelectedMake() {
        Task {
            if let selectedEquipmentMake, let selectedEquipmentType {
                do {
                    self.universalEquipmentList = try await dataService.getUniversalEquipmentByTypeAndBrand(
                        type: selectedEquipmentType,
                        make: selectedEquipmentMake
                    )
                } catch { print(error) }
            }
        }
    }

    func addNewEquipment(companyId: String, bodyOfWater: BodyOfWater) async throws {
        let bodyOfWaterId = "comp_bow_" + UUID().uuidString

        if needsService {
            guard let _ = serviceFrequency else { return }
            guard let _ = serviceFrequencyEvery else { return }
        }

        if let customer {
            let fullName = customer.firstName + " " + customer.lastName
            let equipment = Equipment(
                id: bodyOfWaterId,
                name: name,
                type: category,
                typeId: typeId,
                make: make,
                makeId: makeId,
                model: model,
                modelId: modelId,
                universalEquipmentId: universalEquipmentId,
                manualPdfLink: manualPdfLink,
                dateInstalled: dateInstalled,
                status: status,
                needsService: needsService,
                lastServiceDate: lastServiced,
                serviceFrequency: serviceFrequency,
                serviceFrequencyEvery: serviceFrequencyEvery,
                nextServiceDate: getNextServiceDate(
                    lastServiceDate: lastServiced,
                    frequency: serviceFrequency,
                    every: serviceFrequencyEvery
                ),
                notes: notes,
                customerName: fullName,
                customerId: customer.id,
                serviceLocationId: bodyOfWater.serviceLocationId,
                bodyOfWaterId: bodyOfWater.id,
                isActive: true
            )

            try await dataService.addNewEquipmentWithParts(companyId: companyId, equipment: equipment)
            self.alertMessage = "Successfully Uploaded"
            self.showAlert.toggle()
        }

        // reset
        self.name = ""
        self.typeId = ""
        self.make = ""
        self.makeId = ""
        self.model = ""
        self.modelId = ""
        self.universalEquipmentId = ""
        self.manualPdfLink = ""
        self.dateInstalled = Date()
        self.notes = ""
        self.status = .operational
        self.needsService = false
        self.lastServiced = Date()
        self.lastServicedOptional = Date()
    }
}

struct AddEquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM: AddEquipmentViewModel
    @State var bodyOfWater: BodyOfWater

    init(dataService: any ProductionDataServiceProtocol, bodyOfWater: BodyOfWater) {
        _VM = StateObject(wrappedValue: AddEquipmentViewModel(dataService: dataService))
        _bodyOfWater = State(wrappedValue: bodyOfWater)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header

                    detailsCard

                    serviceCard

                    submitCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(true)
        .alert(VM.alertMessage ?? "", isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, bodyOfWater: bodyOfWater)
                } catch {
                    print(error)
                }
            }
        }
    }
}

// MARK: - Sections

extension AddEquipmentView {
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Add Equipment")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Create a new equipment record for this customer.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var detailsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Details")
                    .font(.headline)

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
                        ))
                            .textFieldStyle(.plain)
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
                        ))
                            .textFieldStyle(.plain)
                    }
                }

                GridRow2 {
                    Field(title: "Date Installed") {
                        DatePicker("", selection: $VM.dateInstalled, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Field(title: "Status") {
                        Picker("Status", selection: $VM.status) {
                            ForEach(EquipmentStatus.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
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
                    Spacer()
                    StatusPill(isOn: VM.needsService, onText: "Scheduled", offText: "None")
                }

                Toggle(isOn: $VM.needsService) {
                    Text("Needs Regular Service")
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

    private var submitCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Create")
                    .font(.headline)

                Text("Review your inputs, then submit to create the equipment record.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: submit) {
                    Text("Submit")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                }
            }
        }
    }

    private func submit() {
        Task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.addNewEquipment(companyId: company.id, bodyOfWater: bodyOfWater)
                }
            } catch {
                print("[AddEquipmentView][submit] Error \(error)")
                VM.alertMessage = "Failed to submit"
                VM.showAlert = true
            }
        }
    }
}

// MARK: - Equipment Selector Sheet (Aesthetic Refresh)

private struct EquipmentSelectorSheet: View {
    @ObservedObject var VM: AddEquipmentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Text("Equipment Catalog")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 12) {
                        // Breadcrumb / selection header
                        if VM.selectedEquipmentType != nil || VM.selectedEquipmentMake != nil {
                            Card {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Button(action: goBack) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "chevron.left")
                                                Text("Back")
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 10)
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        Spacer()
                                    }

                                    if let t = VM.selectedEquipmentType {
                                        HStack {
                                            Text("Type")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                                .textCase(.uppercase)
                                            Spacer()
                                            Text(t.name).fontWeight(.semibold)
                                        }
                                    }

                                    if let m = VM.selectedEquipmentMake {
                                        HStack {
                                            Text("Make")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                                .textCase(.uppercase)
                                            Spacer()
                                            Text(m.name).fontWeight(.semibold)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Main list
                        VStack(spacing: 10) {
                            if let _ = VM.selectedEquipmentType {
                                if let _ = VM.selectedEquipmentMake {
                                    listHeader("Models", count: VM.universalEquipmentList.count)

                                    ForEach(VM.universalEquipmentList) { eq in
                                        RowButton(title: eq.model) {
                                            VM.selectedUniversalEquipment = eq
                                            // purely aesthetic: auto-fill model when selected
                                            if VM.model.isEmpty { VM.model = eq.model }
                                        }
                                    }
                                } else {
                                    listHeader("Brands", count: VM.equipmentmakes.count)

                                    ForEach(VM.equipmentmakes) { make in
                                        RowButton(title: make.name) { VM.selectedEquipmentMake = make }
                                    }
                                }
                            } else {
                                listHeader("Types", count: VM.equipmentTypes.count)

                                ForEach(VM.equipmentTypes) { type in
                                    RowButton(title: type.name) { VM.selectedEquipmentType = type }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }

    private func goBack() {
        if VM.selectedEquipmentMake != nil {
            VM.selectedEquipmentMake = nil
            VM.universalEquipmentList = []
        } else {
            VM.selectedEquipmentType = nil
            VM.equipmentmakes = []
        }
    }

    private func listHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text("\(title) • \(count)")
                .font(.headline)
            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct RowButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared UI Building Blocks

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
            .background(isOn ? Color.blue.opacity(0.14) : Color.gray.opacity(0.14))
            .foregroundColor(isOn ? .blue : .secondary)
            .clipShape(Capsule())
    }
}

struct EquipmentCatalogSelectionControl: View {
    let dataService: any ProductionDataServiceProtocol
    @Binding var category: EquipmentCategory
    @Binding var typeId: String
    @Binding var make: String
    @Binding var makeId: String
    @Binding var model: String
    @Binding var modelId: String
    @Binding var universalEquipmentId: String
    @Binding var manualPdfLink: String
    @Binding var name: String

    @State private var showCatalog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make & Model")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                Button(action: { showCatalog = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                        Text("Search equipment catalog")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: clearCatalogIds) {
                    Text("Custom")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if !modelId.isEmpty || !makeId.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text([make, model].filter { !$0.isEmpty }.joined(separator: " "))
                            .fontWeight(.semibold)
                        Text("Selected from catalog")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Clear") { clearCatalogIds() }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if !manualPdfLink.isEmpty, let url = URL(string: manualPdfLink) {
                Link("View catalog manual", destination: url)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showCatalog) {
            EquipmentCatalogSelectionSheet(
                dataService: dataService,
                onCustom: {
                    clearCatalogIds()
                    showCatalog = false
                },
                onSelect: { selectedType, selectedMake, selectedModel in
                    if let matchedCategory = EquipmentCategory(rawValue: selectedModel.type) ?? EquipmentCategory(rawValue: selectedType.name) {
                        category = matchedCategory
                    }
                    typeId = selectedType.id
                    make = selectedMake.name
                    makeId = selectedMake.id
                    model = selectedModel.model
                    modelId = selectedModel.id
                    universalEquipmentId = selectedModel.id
                    manualPdfLink = selectedModel.manualPdfLink
                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        name = selectedModel.name.isEmpty ? selectedModel.model : selectedModel.name
                    }
                    showCatalog = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func clearCatalogIds() {
        typeId = ""
        makeId = ""
        modelId = ""
        universalEquipmentId = ""
        manualPdfLink = ""
    }
}

private struct EquipmentCatalogSelectionSheet: View {
    let dataService: any ProductionDataServiceProtocol
    let onCustom: () -> Void
    let onSelect: (UniversalEquipmentType, UniversalEquipmentMake, UniversalEquipment) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var equipmentTypes: [UniversalEquipmentType] = []
    @State private var equipmentMakes: [UniversalEquipmentMake] = []
    @State private var equipmentModels: [UniversalEquipment] = []
    @State private var selectedType: UniversalEquipmentType?
    @State private var selectedMake: UniversalEquipmentMake?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Text("Equipment Catalog")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 12) {
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    if selectedType != nil || selectedMake != nil {
                                        Button(action: goBack) {
                                            Label("Back", systemImage: "chevron.left")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    Spacer()
                                    Button("Use custom make/model") {
                                        onCustom()
                                        dismiss()
                                    }
                                    .fontWeight(.semibold)
                                }

                                if let selectedType {
                                    detailRow("Type", selectedType.name)
                                }

                                if let selectedMake {
                                    detailRow("Make", selectedMake.name)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }

                        if isLoading {
                            ProgressView()
                                .padding(.top, 24)
                        }

                        VStack(spacing: 10) {
                            if let selectedType {
                                if let selectedMake {
                                    listHeader("Models", count: equipmentModels.count)

                                    ForEach(equipmentModels) { equipment in
                                        RowButton(title: equipment.model) {
                                            onSelect(selectedType, selectedMake, equipment)
                                            dismiss()
                                        }
                                    }
                                } else {
                                    listHeader("Makes", count: equipmentMakes.count)

                                    ForEach(equipmentMakes) { make in
                                        RowButton(title: make.name) {
                                            selectedMake = make
                                            Task { await loadModels(type: selectedType, make: make) }
                                        }
                                    }
                                }
                            } else {
                                listHeader("Categories", count: equipmentTypes.count)

                                ForEach(equipmentTypes) { type in
                                    RowButton(title: type.name) {
                                        selectedType = type
                                        Task { await loadMakes(type: type) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .task {
            await loadTypes()
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func listHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text("\(title) • \(count)")
                .font(.headline)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func goBack() {
        errorMessage = nil
        if selectedMake != nil {
            selectedMake = nil
            equipmentModels = []
        } else {
            selectedType = nil
            equipmentMakes = []
            equipmentModels = []
        }
    }

    private func loadTypes() async {
        guard equipmentTypes.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await dataService.getUniversalEquipmentTypes()
            equipmentTypes = loaded.sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Unable to load equipment categories."
        }
        isLoading = false
    }

    private func loadMakes(type: UniversalEquipmentType) async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await dataService.getUniversalEquipmentBrandsByType(type: type)
            equipmentMakes = loaded.sorted { $0.name < $1.name }
        } catch {
            errorMessage = "Unable to load equipment makes."
        }
        isLoading = false
    }

    private func loadModels(type: UniversalEquipmentType, make: UniversalEquipmentMake) async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await dataService.getUniversalEquipmentByTypeAndBrand(type: type, make: make)
            equipmentModels = loaded.sorted { $0.model < $1.model }
        } catch {
            errorMessage = "Unable to load equipment models."
        }
        isLoading = false
    }
}
