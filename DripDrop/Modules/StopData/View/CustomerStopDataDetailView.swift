//
//  CustomerStopDataDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/10/24.
//

import SwiftUI
import FirebaseFirestore
@MainActor
final class CustomerStopDataDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showLocationPicker: Bool = false
    @Published var showBOWPicker: Bool = false

    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []
    @Published private(set) var customer: Customer? = nil
    
    @Published var selectedLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        isActive: true
    )
    @Published private(set) var locations: [ServiceLocation] = []
    
    @Published var selectedBodyOfWater: BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []

    @Published private(set) var currentHistory: [StopData] = []

    
    func onLoad(companyId:String,customerId:String){
        Task{
            do {
                print("[CustomerStopDataDetailViewModel][onLoad] On Load")
                self.readingTemplates = try await dataService.getAllReadingTemplates(companyId: companyId)
                print("[CustomerStopDataDetailViewModel][onLoad] readingTemplates \(readingTemplates.count)")

                self.dosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
                print("[CustomerStopDataDetailViewModel][onLoad] dosageTemplates \(dosageTemplates.count)")

                self.locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
                print("[CustomerStopDataDetailViewModel][onLoad] locations \(locations.count)")

                if !locations.isEmpty {
                    self.selectedLocation = locations.first!
                    await loadBodiesOfWater(companyId: companyId, customerId: customerId)
                }
            } catch {
                print(error)
            }
        }
    }
    func onChangeOfServiceLocation(companyId:String,customerId:String){
        Task{
            print("[CustomerStopDataDetailViewModel][onChangeOfServiceLocation] selectedLocation \(selectedLocation.id)")
            await loadBodiesOfWater(companyId: companyId, customerId: customerId)
        }
    }
    func onChangeOfBodyOfWater(companyId:String,customerId:String){
        Task{
            do {
                print("[CustomerStopDataDetailViewModel][onChangeOfServiceLocation] selectedBodyOfWater: \(selectedBodyOfWater.id)")
                if selectedBodyOfWater.id != "" {
                    self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: selectedBodyOfWater.id , amount: 5)
                }
            } catch {
                print(error)
            }
        }
    }

    private func loadBodiesOfWater(companyId: String, customerId: String) async {
        guard !selectedLocation.id.isEmpty else {
            bodiesOfWater = []
            selectedBodyOfWater = emptyBodyOfWater()
            currentHistory = []
            return
        }

        do {
            bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(
                companyId: companyId,
                serviceLocation: selectedLocation
            )

            if let firstBodyOfWater = bodiesOfWater.first {
                if selectedBodyOfWater.id.isEmpty ||
                    !bodiesOfWater.contains(where: { $0.id == selectedBodyOfWater.id }) {
                    selectedBodyOfWater = firstBodyOfWater
                }

                currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(
                    companyId: companyId,
                    bodyOfWaterId: selectedBodyOfWater.id,
                    amount: 5
                )
            } else {
                selectedBodyOfWater = emptyBodyOfWater()
                currentHistory = []
            }
        } catch {
            bodiesOfWater = []
            currentHistory = []
            print("[CustomerStopDataDetailViewModel][loadBodiesOfWater] Error: \(error)")
        }
    }

    private func emptyBodyOfWater() -> BodyOfWater {
        BodyOfWater(
            id: "",
            name: "",
            gallons: "",
            material: "",
            customerId: "",
            serviceLocationId: "",
            lastFilled: Date(),
            isActive: true
        )
    }
}
struct CustomerStopDataDetailView: View {
    init(dataService: any ProductionDataServiceProtocol,customerId:String) {
        _VM = StateObject(wrappedValue: CustomerStopDataDetailViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
    }
    @StateObject var VM : CustomerStopDataDetailViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var customerListVM : CustomerListViewModel
    private var customer: Customer? {
        customerListVM.customers.first { $0.id == customerId }
    }
    @State var customerId:String
    @State private var showAllWaterHistory = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                form
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id, customerId: customerId)
            }
        }
        .onChange(of: VM.selectedLocation, perform: { location in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChangeOfServiceLocation(companyId: currentCompany.id, customerId: customerId)
            }
        })
        .onChange(of: VM.selectedBodyOfWater, perform: { BOW in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChangeOfBodyOfWater(companyId: currentCompany.id, customerId: customerId)
            }
        })
        .sheet(isPresented: $showAllWaterHistory) {
            if let companyId = masterDataManager.currentCompany?.id,
               !VM.selectedBodyOfWater.id.isEmpty {
                CustomerWaterHistoryPagedSheet(
                    dataService: dataService,
                    companyId: companyId,
                    bodyOfWater: VM.selectedBodyOfWater
                )
            }
        }
    }
}

#Preview {
    CustomerStopDataDetailView(dataService: MockDataService(), customerId: "")
}
extension CustomerStopDataDetailView {
    var form: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                locationForm
                BOWForm
                table
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    var locationForm: some View {
        selectorCard(
            title: "Service Location",
            value: selectedLocationTitle,
            detail: selectedLocationDetail,
            systemImage: "mappin.and.ellipse",
            accentColor: Color.poolBlue
        ) {
            VM.showLocationPicker.toggle()
        }
        .sheet(isPresented: $VM.showLocationPicker, onDismiss: {
            print("[CustomerStopDataDetailView][showLocationPicker] On dismiss")
        }, content: {
            ServiceLocationPicker(dataService: dataService, customerId: customerId, location: $VM.selectedLocation)
        })
    }

    var BOWForm: some View {
        selectorCard(
            title: "Body of Water",
            value: selectedBodyOfWaterTitle,
            detail: bodyOfWaterMetaText(VM.selectedBodyOfWater),
            systemImage: "drop.fill",
            accentColor: Color.poolGreen
        ) {
            VM.showBOWPicker.toggle()
        }
        .disabled(VM.selectedLocation.id.isEmpty)
        .opacity(VM.selectedLocation.id.isEmpty ? 0.55 : 1)
        .sheet(isPresented: $VM.showBOWPicker, onDismiss: {
            print("[CustomerStopDataDetailView][showBOWPicker] On dismiss")
        }, content: {
            BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.selectedLocation.id, bodyOfWater: $VM.selectedBodyOfWater)
        })
    }

    var table: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Water History")
                        .font(.headline.weight(.semibold))

                    Text(selectedBodyOfWaterTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !VM.currentHistory.isEmpty {
                    Button {
                        showAllWaterHistory = true
                    } label: {
                        Label("View All", systemImage: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.poolBlue)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Text("\(VM.currentHistory.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.poolBlue.opacity(0.1), in: Capsule())
            }

            if VM.selectedBodyOfWater.id != "" && VM.selectedLocation.id != "" {
                if VM.currentHistory.count != 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        StopDataTableView(
                            stopData: VM.currentHistory,
                            readingTemplates: VM.readingTemplates,
                            dosageTemplates: VM.dosageTemplates,
                            bodyOfWaterId: VM.selectedBodyOfWater.id
                        )
                    }
                } else {
                    compactEmptyState(
                        title: "No Water History",
                        systemImage: "tablecells"
                    )
                }
            } else {
                compactEmptyState(
                    title: "Select Water",
                    systemImage: "drop.triangle"
                )
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func compactEmptyState(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var selectedLocationTitle: String {
        if !VM.selectedLocation.nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return VM.selectedLocation.nickName
        }

        let street = VM.selectedLocation.address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return street.isEmpty ? "No Location Selected" : street
    }

    private var selectedLocationDetail: String {
        let address = VM.selectedLocation.address
        let detail = [
            address.city,
            address.state,
            address.zip,
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")

        return detail.isEmpty ? "Tap to choose a location" : detail
    }

    private var selectedBodyOfWaterTitle: String {
        let name = VM.selectedBodyOfWater.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "No Water Body Selected" : name
    }

    private func bodyOfWaterMetaText(_ bodyOfWater: BodyOfWater) -> String {
        let gallons = bodyOfWater.gallons.trimmingCharacters(in: .whitespacesAndNewlines)
        let material = bodyOfWater.material.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            gallons.isEmpty ? "" : "\(gallons) gal",
            material,
        ].filter { !$0.isEmpty }

        return parts.isEmpty ? "Tap to choose water" : parts.joined(separator: " · ")
    }

    private func selectorCard(
        title: String,
        value: String,
        detail: String,
        systemImage: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(value)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

@MainActor
private final class CustomerWaterHistoryPagedViewModel: ObservableObject {
    @Published private(set) var history: [StopData] = []
    @Published private(set) var isLoadingPage = false
    @Published private(set) var hasMoreHistory = true
    @Published var alertMessage = ""
    @Published var showAlert = false

    private let dataService: any ProductionDataServiceProtocol
    private let companyId: String
    private let bodyOfWaterId: String
    private let pageSize = 5
    private var lastDocument: DocumentSnapshot? = nil

    init(
        dataService: any ProductionDataServiceProtocol,
        companyId: String,
        bodyOfWaterId: String
    ) {
        self.dataService = dataService
        self.companyId = companyId
        self.bodyOfWaterId = bodyOfWaterId
    }

    func loadFirstPage() async {
        guard history.isEmpty else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoadingPage, hasMoreHistory else { return }

        isLoadingPage = true
        defer { isLoadingPage = false }

        do {
            let page = try await dataService.getStopDataByBodyOfWaterPage(
                companyId: companyId,
                bodyOfWaterId: bodyOfWaterId,
                limit: pageSize,
                lastDocument: lastDocument
            )
            let loadedIds = Set(history.map(\.id))
            history.append(contentsOf: page.stopData.filter { !loadedIds.contains($0.id) })
            lastDocument = page.lastDocument
            hasMoreHistory = page.lastDocument != nil && page.stopData.count == pageSize
        } catch {
            alertMessage = "Unable to load more water history."
            showAlert = true
            print("[CustomerWaterHistoryPagedViewModel][loadNextPage] Error: \(error)")
        }
    }
}

private struct CustomerWaterHistoryPagedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var VM: CustomerWaterHistoryPagedViewModel

    let bodyOfWater: BodyOfWater

    init(
        dataService: any ProductionDataServiceProtocol,
        companyId: String,
        bodyOfWater: BodyOfWater
    ) {
        _VM = StateObject(
            wrappedValue: CustomerWaterHistoryPagedViewModel(
                dataService: dataService,
                companyId: companyId,
                bodyOfWaterId: bodyOfWater.id
            )
        )
        self.bodyOfWater = bodyOfWater
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    if VM.history.isEmpty && !VM.isLoadingPage {
                        HStack(spacing: 8) {
                            Image(systemName: "tablecells")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text("No Water History")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(VM.history) { item in
                                CustomerWaterHistoryRow(stopData: item)
                                    .onAppear {
                                        if VM.history.last?.id == item.id {
                                            Task {
                                                await VM.loadNextPage()
                                            }
                                        }
                                    }
                            }

                            if VM.isLoadingPage {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await VM.loadFirstPage()
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "drop.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 34, height: 34)
                .background(Color.poolBlue.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Water History")
                    .font(.headline.weight(.semibold))
                Text(bodyOfWater.name.isEmpty ? "Selected body of water" : bodyOfWater.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CustomerWaterHistoryRow: View {
    let stopData: StopData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(fullDateAndDay(date: stopData.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text("\(stopData.readings.count)R / \(stopData.dosages.count)D")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.poolBlue.opacity(0.10), in: Capsule())
            }

            if !readingSummary.isEmpty {
                Text(readingSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !dosageSummary.isEmpty {
                Text(dosageSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !stopData.observation.isEmpty {
                Text(stopData.observation.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private var readingSummary: String {
        stopData.readings.prefix(4).compactMap { reading in
            guard let name = reading.name, !name.isEmpty else { return nil }
            let amount = reading.amount ?? ""
            let unit = reading.UOM ?? ""
            return "\(name) \(amount)\(unit.isEmpty ? "" : " \(unit)")"
        }
        .joined(separator: " • ")
    }

    private var dosageSummary: String {
        stopData.dosages.prefix(4).compactMap { dosage in
            guard let name = dosage.name, !name.isEmpty else { return nil }
            let amount = dosage.amount ?? ""
            let unit = dosage.UOM ?? ""
            return "\(name) \(amount)\(unit.isEmpty ? "" : " \(unit)")"
        }
        .joined(separator: " • ")
    }
}
