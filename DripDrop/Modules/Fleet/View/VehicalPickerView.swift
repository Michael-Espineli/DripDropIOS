import SwiftUI

@MainActor
final class VehicalPickerViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var vehicals: [Vehical] = []
    @Published var selectedVehical: Vehical? = nil
    @Published var isLoading: Bool = false
    @Published var isSavingPersonalVehicle: Bool = false

    func onLoad(companyId: String) async throws {
        isLoading = true
        self.vehicals = try await dataService.getAllVehicals(companyId: companyId)
        isLoading = false
    }

    func setInitialSelection(_ vehical: Vehical) {
        if selectedVehical == nil {
            selectedVehical = vehical
        }
    }
    
    func savePersonalVehicle(
        companyId: String,
        companyUser: CompanyUser,
        personalVehicle: PersonalVehicle
    ) async throws {
        isSavingPersonalVehicle = true
        defer { isSavingPersonalVehicle = false }
        
        try await dataService.updateCompanyUserPersonalVehicle(
            companyId: companyId,
            companyUserId: companyUser.id,
            allowPersonalVehicle: true,
            personalVehicle: personalVehicle
        )
    }
}

struct VehicalPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: VehicalPickerViewModel
    @Binding var vehical: Vehical
    let companyUser: CompanyUser?

    init(
        dataService: any ProductionDataServiceProtocol,
        vehical: Binding<Vehical>,
        companyUser: CompanyUser? = nil
    ) {
        _VM = StateObject(wrappedValue: VehicalPickerViewModel(dataService: dataService))
        self._vehical = vehical
        self.companyUser = companyUser
    }

    @State var addVehical: Bool = false
    @State private var editPersonalVehicle: Bool = false
    @State private var savedPersonalVehicle: PersonalVehicle? = nil
    @State var search: String = ""
    @State var customers: [Customer] = []

    private var canUseCompanyVehicals: Bool {
        companyUser?.canUseCompanyRouteVehicle ?? true
    }

    private var canUsePersonalVehical: Bool {
        companyUser?.canUsePersonalRouteVehicle ?? false
    }

    private var filteredVehicals: [Vehical] {
        guard canUseCompanyVehicals else { return [] }

        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return VM.vehicals
        }

        return VM.vehicals.filter { datum in
            datum.nickName.localizedCaseInsensitiveContains(trimmedSearch) ||
            datum.make.localizedCaseInsensitiveContains(trimmedSearch) ||
            datum.model.localizedCaseInsensitiveContains(trimmedSearch) ||
            datum.plate.localizedCaseInsensitiveContains(trimmedSearch) ||
            datum.color.localizedCaseInsensitiveContains(trimmedSearch) ||
            datum.vehicalType.rawValue.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }
    
    private var effectivePersonalVehicle: PersonalVehicle? {
        savedPersonalVehicle ?? companyUser?.personalVehicle
    }
    
    private var personalVehical: Vehical? {
        guard let companyUser,
              let personalVehicle = effectivePersonalVehicle,
              canUsePersonalVehical
        else { return nil }
        
        return personalVehicle.asVehical(ownerId: companyUser.userId)
    }
    
    private var filteredPersonalVehical: Vehical? {
        guard let personalVehical else { return nil }
        
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return personalVehical
        }
        
        let searchableValues = [
            personalVehical.nickName,
            personalVehical.make,
            personalVehical.model,
            personalVehical.plate,
            personalVehical.color,
            personalVehical.vehicalType.rawValue,
            "personal"
        ]
        
        return searchableValues.contains { value in
            value.localizedCaseInsensitiveContains(trimmedSearch)
        } ? personalVehical : nil
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        personalVehicleCard
                        listCard
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 96)
                }
            }

            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .task {
            VM.setInitialSelection(vehical)
            await reloadVehicals()
        }
        .sheet(isPresented: $addVehical, onDismiss: {
            Task {
                await reloadVehicals()
            }
        }) {
            AddNewVehical(dataService: dataService)
        }
        .sheet(isPresented: $editPersonalVehicle) {
            PersonalVehicleEditorSheet(
                initialVehicle: effectivePersonalVehicle,
                isSaving: VM.isSavingPersonalVehicle
            ) { personalVehicle in
                await savePersonalVehicle(personalVehicle)
            }
        }
    }
}

// MARK: - Views

extension VehicalPickerView {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Vehicle Picker")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(canUseCompanyVehicals ? "Choose a company fleet or approved personal vehicle, then confirm your selection." : "Choose an approved personal vehicle, then confirm your selection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Search vehicles", text: $search)
                    .font(.subheadline)
                    .textInputAutocapitalization(.words)

                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var listCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Available Vehicles", systemImage: "car")

                Spacer()

                if canUseCompanyVehicals {
                    Button {
                        addVehical.toggle()
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if VM.isLoading {
                loadingState
            } else if filteredVehicals.isEmpty && filteredPersonalVehical == nil {
                emptyState
            } else {
                VStack(spacing: 8) {
                    if let filteredPersonalVehical {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                VM.selectedVehical = filteredPersonalVehical
                            }

                            #if os(iOS)
                            UISelectionFeedbackGenerator().selectionChanged()
                            #endif
                        } label: {
                            vehicalRow(filteredPersonalVehical, sourceLabel: "Personal")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ForEach(filteredVehicals) { datum in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                VM.selectedVehical = datum
                            }

                            #if os(iOS)
                            UISelectionFeedbackGenerator().selectionChanged()
                            #endif
                        } label: {
                            vehicalRow(datum, sourceLabel: "Company Fleet")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    var personalVehicleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("My Personal Vehicle", systemImage: "person.crop.circle.badge.checkmark")
                
                Spacer()
                
                Button {
                    editPersonalVehicle = true
                } label: {
                    Label(personalVehical == nil ? "Add Mine" : "Edit", systemImage: personalVehical == nil ? "plus" : "pencil")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(companyUser == nil)
                .opacity(companyUser == nil ? 0.5 : 1)
            }
            
            if let personalVehical {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        VM.selectedVehical = personalVehical
                    }
                    
                    #if os(iOS)
                    UISelectionFeedbackGenerator().selectionChanged()
                    #endif
                } label: {
                    vehicalRow(personalVehical, sourceLabel: "Personal")
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(companyUser == nil ? "Sign in as a company user to add a personal vehicle." : "Add your own car or truck here so it is available when starting or ending active routes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if companyUser != nil {
                        Button {
                            editPersonalVehicle = true
                        } label: {
                            Label("Add My Personal Vehicle", systemImage: "plus.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func vehicalRow(_ datum: Vehical, sourceLabel: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: VM.selectedVehical == datum ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(VM.selectedVehical == datum ? Color.poolGreen : Color.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(datum.nickName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(datum.year) \(datum.make) - \(datum.model)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(datum.color) \(datum.plate) \(datum.vehicalType.rawValue)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if let sourceLabel {
                    Text(sourceLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(sourceLabel == "Personal" ? Color.blue : Color.poolGreen)
                }
            }

            Spacer()

            if VM.selectedVehical == datum {
                Text("Selected")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.poolGreen.opacity(0.12), in: Capsule())
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    confirmSelection()
                } label: {
                    Label("Select Vehicle", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(VM.selectedVehical == nil)
                .opacity(VM.selectedVehical == nil ? 0.45 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Loading vehicles...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
    }

    var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "car")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(search.isEmpty ? "No vehicles found." : "No matching vehicles.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(search.isEmpty ? "Add a vehicle to select one here." : "Try a different search.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if search.isEmpty {
                Button {
                    addVehical.toggle()
                } label: {
                    Label("Add Vehicle", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}

// MARK: - Actions

extension VehicalPickerView {

    func reloadVehicals() async {
        if let currentCompany = masterDataManager.currentCompany {
            do {
                try await VM.onLoad(companyId: currentCompany.id)
            } catch {
                VM.isLoading = false
                print("Vehical Picker Error")
                print(error)
            }
        }
    }

    func confirmSelection() {
        guard let selectedVehical = VM.selectedVehical else { return }

        vehical = selectedVehical

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        dismiss()
    }
    
    func savePersonalVehicle(_ personalVehicle: PersonalVehicle) async {
        guard let currentCompany = masterDataManager.currentCompany,
              let companyUser
        else { return }
        
        do {
            try await VM.savePersonalVehicle(
                companyId: currentCompany.id,
                companyUser: companyUser,
                personalVehicle: personalVehicle
            )
            
            savedPersonalVehicle = personalVehicle
            VM.selectedVehical = personalVehicle.asVehical(ownerId: companyUser.userId)
            
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } catch {
            print("[VehicalPickerView][savePersonalVehicle] \(error)")
        }
    }
}

private struct PersonalVehicleEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let isSaving: Bool
    let onSave: (PersonalVehicle) async -> Void
    
    @State private var nickName: String
    @State private var vehicalType: VehicalType
    @State private var year: String
    @State private var make: String
    @State private var model: String
    @State private var color: String
    @State private var plate: String
    @State private var miles: String
    
    init(
        initialVehicle: PersonalVehicle?,
        isSaving: Bool,
        onSave: @escaping (PersonalVehicle) async -> Void
    ) {
        self.isSaving = isSaving
        self.onSave = onSave
        _nickName = State(initialValue: initialVehicle?.nickName ?? "")
        _vehicalType = State(initialValue: VehicalType(rawValue: initialVehicle?.vehicalType ?? "") ?? .car)
        _year = State(initialValue: initialVehicle?.year ?? "")
        _make = State(initialValue: initialVehicle?.make ?? "")
        _model = State(initialValue: initialVehicle?.model ?? "")
        _color = State(initialValue: initialVehicle?.color ?? "")
        _plate = State(initialValue: initialVehicle?.plate ?? "")
        _miles = State(initialValue: initialVehicle?.miles.map { String($0) } ?? "")
    }
    
    private var canSave: Bool {
        !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !plate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    TextField("Nickname", text: $nickName)
                    Picker("Type", selection: $vehicalType) {
                        ForEach(VehicalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Color", text: $color)
                    TextField("Plate", text: $plate)
                        .textInputAutocapitalization(.characters)
                    TextField("Current mileage", text: $miles)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Personal Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            await onSave(
                                PersonalVehicle(
                                    nickName: nickName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    vehicalType: vehicalType.rawValue,
                                    year: year.trimmingCharacters(in: .whitespacesAndNewlines),
                                    make: make.trimmingCharacters(in: .whitespacesAndNewlines),
                                    model: model.trimmingCharacters(in: .whitespacesAndNewlines),
                                    color: color.trimmingCharacters(in: .whitespacesAndNewlines),
                                    plate: plate.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                                    miles: Double(miles.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                                )
                            )
                            dismiss()
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }
}
