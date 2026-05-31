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
    @State var search: String = ""
    @State var customers: [Customer] = []

    private var filteredVehicals: [Vehical] {
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
    
    private var personalVehical: Vehical? {
        guard companyUser?.allowPersonalVehicle == true,
              let companyUser,
              let personalVehicle = companyUser.personalVehicle
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

                    Text("Choose a company fleet or approved personal vehicle, then confirm your selection.")
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
}
