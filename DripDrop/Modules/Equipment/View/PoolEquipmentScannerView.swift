//
//  PoolEquipmentScannerView.swift
//  DripDrop
//
//  Created by Codex on 8/7/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

enum PoolEquipmentScanWorkflowStep: String, CaseIterable, Identifiable {
    case capture = "Capture"
    case identify = "Identify"
    case map = "Map"
    case confirm = "Confirm"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .capture:
            return "camera.fill"
        case .identify:
            return "viewfinder.circle.fill"
        case .map:
            return "point.topleft.down.curvedto.point.bottomright.up"
        case .confirm:
            return "checkmark.seal.fill"
        }
    }
}

enum PoolEquipmentPipeDirection: String, Codable, CaseIterable, Identifiable {
    case suction = "Suction"
    case pressure = "Pressure"
    case returnLine = "Return"
    case drain = "Drain"
    case unknown = "Unknown"

    var id: String { rawValue }
}

struct PoolEquipmentScanEquipmentDraft: Identifiable, Codable, Hashable {
    var id: String
    var photoIds: [String]
    var photoNames: [String]
    var predictedName: String
    var confirmedName: String
    var predictedCategory: EquipmentCategory
    var confirmedCategory: EquipmentCategory
    var make: String
    var model: String
    var matchedEquipmentId: String?
    var matchedUniversalEquipmentId: String?
    var predictedUniversalEquipmentId: String?
    var typeId: String
    var makeId: String
    var modelId: String
    var universalEquipmentId: String
    var manualPdfLink: String
    var confidence: Double
    var isConfirmed: Bool
    var correctionNotes: String

    static func draft(
        index: Int,
        category: EquipmentCategory,
        photoIds: [String],
        photoNames: [String],
        equipment: Equipment?,
        catalogMatch: UniversalEquipment? = nil
    ) -> PoolEquipmentScanEquipmentDraft {
        let fallbackName = "\(category.rawValue) \(index + 1)"
        let equipmentName = equipment?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let catalogName = catalogMatch?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let catalogModel = catalogMatch?.model.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = !equipmentName.isEmpty ? equipmentName : (!catalogName.isEmpty ? catalogName : (!catalogModel.isEmpty ? catalogModel : fallbackName))
        let confirmedCategory = equipment?.type ?? Self.category(for: catalogMatch) ?? category
        let equipmentUniversalId = equipment?.universalEquipmentId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let equipmentModelId = equipment?.modelId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let catalogId = !equipmentUniversalId.isEmpty ? equipmentUniversalId : (!equipmentModelId.isEmpty ? equipmentModelId : catalogMatch?.id ?? "")
        let equipmentMake = equipment?.make.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let equipmentModel = equipment?.model.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let typeId = equipment?.typeId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let makeId = equipment?.makeId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return PoolEquipmentScanEquipmentDraft(
            id: "scan_equipment_\(UUID().uuidString)",
            photoIds: photoIds,
            photoNames: photoNames,
            predictedName: name,
            confirmedName: name,
            predictedCategory: confirmedCategory,
            confirmedCategory: confirmedCategory,
            make: !equipmentMake.isEmpty ? equipmentMake : catalogMatch?.make ?? "",
            model: !equipmentModel.isEmpty ? equipmentModel : catalogMatch?.model ?? "",
            matchedEquipmentId: equipment?.id,
            matchedUniversalEquipmentId: catalogId.isEmpty ? nil : catalogId,
            predictedUniversalEquipmentId: catalogId.isEmpty ? nil : catalogId,
            typeId: !typeId.isEmpty ? typeId : catalogMatch?.typeId ?? "",
            makeId: !makeId.isEmpty ? makeId : catalogMatch?.makeId ?? "",
            modelId: !equipmentModelId.isEmpty ? equipmentModelId : catalogMatch?.id ?? "",
            universalEquipmentId: catalogId,
            manualPdfLink: equipment?.manualPdfLink.isEmpty == false ? equipment?.manualPdfLink ?? "" : catalogMatch?.manualPdfLink ?? "",
            confidence: catalogMatch == nil ? (equipment == nil ? 0.46 : 0.68) : 0.74,
            isConfirmed: false,
            correctionNotes: ""
        )
    }

    private static func category(for catalogMatch: UniversalEquipment?) -> EquipmentCategory? {
        guard let catalogMatch else { return nil }
        if let directMatch = EquipmentCategory(rawValue: catalogMatch.type) {
            return directMatch
        }

        let searchText = "\(catalogMatch.type) \(catalogMatch.name) \(catalogMatch.model)".lowercased()
        if searchText.contains("pump") { return .pump }
        if searchText.contains("filter") { return .filter }
        if searchText.contains("heater") { return .heater }
        if searchText.contains("salt") { return .saltCell }
        if searchText.contains("light") { return .light }
        if searchText.contains("cleaner") || searchText.contains("vacuum") { return .cleaner }
        if searchText.contains("control") || searchText.contains("automation") { return .controlSystem }
        if searchText.contains("chlorinator") || searchText.contains("feeder") { return .autoChlorinator }
        return nil
    }
}

struct PoolEquipmentScanPipeSegment: Identifiable, Codable, Hashable {
    var id: String
    var fromNode: String
    var toNode: String
    var direction: PoolEquipmentPipeDirection
    var material: String
    var diameter: String
    var confidence: Double
    var isConfirmed: Bool
    var notes: String

    static func segment(
        fromNode: String,
        toNode: String,
        direction: PoolEquipmentPipeDirection,
        confidence: Double = 0.44
    ) -> PoolEquipmentScanPipeSegment {
        PoolEquipmentScanPipeSegment(
            id: "scan_pipe_\(UUID().uuidString)",
            fromNode: fromNode,
            toNode: toNode,
            direction: direction,
            material: "PVC",
            diameter: "",
            confidence: confidence,
            isConfirmed: false,
            notes: ""
        )
    }
}

struct PoolEquipmentScanSession: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var customerId: String?
    var serviceLocationId: String?
    var bodyOfWaterId: String?
    var createdByUserId: String?
    var createdByName: String?
    var status: String
    var photoIds: [String]
    var photoNames: [String]
    var equipmentDrafts: [PoolEquipmentScanEquipmentDraft]
    var pipeSegments: [PoolEquipmentScanPipeSegment]
    var technicianNotes: String
    var modelVersion: String
    var createdAt: Date
    var updatedAt: Date
    var confirmedAt: Date?
}

struct PoolEquipmentScannerLearningFeedback: Identifiable, Codable, Hashable {
    var id: String
    var scanId: String
    var companyId: String
    var confirmedByUserId: String?
    var confirmedByName: String?
    var photoIds: [String]
    var equipmentDrafts: [PoolEquipmentScanEquipmentDraft]
    var pipeSegments: [PoolEquipmentScanPipeSegment]
    var correctionCount: Int
    var confirmedAt: Date
}

final class PoolEquipmentScannerManager {
    static let shared = PoolEquipmentScannerManager()

    private let db = Firestore.firestore()

    private init() {}

    private func scansCollection(companyId: String) -> CollectionReference {
        db.collection("companies").document(companyId).collection("equipmentScans")
    }

    func saveConfirmedScan(
        companyId: String,
        session: PoolEquipmentScanSession,
        feedback: PoolEquipmentScannerLearningFeedback
    ) async throws {
        let scanDoc = scansCollection(companyId: companyId).document(session.id)
        try scanDoc.setData(from: session, merge: true)
        try scanDoc.collection("learningFeedback").document(feedback.id).setData(from: feedback, merge: true)
    }
}

@MainActor
final class PoolEquipmentScannerViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    @Published var workflowStep: PoolEquipmentScanWorkflowStep = .capture
    @Published var scanPhotos: [DripDropImage] = []
    @Published var existingEquipment: [Equipment] = []
    @Published var universalEquipmentCatalog: [UniversalEquipment] = []
    @Published var didLoadUniversalCatalog = false
    @Published var equipmentDrafts: [PoolEquipmentScanEquipmentDraft] = []
    @Published var pipeSegments: [PoolEquipmentScanPipeSegment] = []
    @Published var technicianNotes: String = ""
    @Published var pipeFromNode: String = "Pool/Spa"
    @Published var pipeToNode: String = "Pump 1"
    @Published var pipeDirection: PoolEquipmentPipeDirection = .suction
    @Published var pipeDiameter: String = ""
    @Published var pipeNotes: String = ""
    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    private var didLoad = false

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    var confirmedEquipmentCount: Int {
        equipmentDrafts.filter(\.isConfirmed).count
    }

    var confirmedPipeSegmentCount: Int {
        pipeSegments.filter(\.isConfirmed).count
    }

    var correctionCount: Int {
        equipmentDrafts.filter { draft in
            let predictedUniversalId = draft.predictedUniversalEquipmentId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let confirmedUniversalId = draft.universalEquipmentId.trimmingCharacters(in: .whitespacesAndNewlines)

            return draft.predictedName != draft.confirmedName ||
            draft.predictedCategory != draft.confirmedCategory ||
            predictedUniversalId != confirmedUniversalId ||
            !draft.correctionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count + pipeSegments.filter { !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var canSave: Bool {
        !isSaving && (!equipmentDrafts.isEmpty || !pipeSegments.isEmpty)
    }

    var universalCatalogSummary: String {
        if !didLoadUniversalCatalog {
            return "Loading universal equipment catalog"
        }

        if universalEquipmentCatalog.isEmpty {
            return "Universal catalog unavailable; drafts can still be corrected and saved"
        }

        return "\(universalEquipmentCatalog.count) universal catalog models available"
    }

    var endpointOptions: [String] {
        var options = ["Pool/Spa", "Skimmer", "Main Drain", "Return Manifold", "Cleaner Line"]
        options.append(contentsOf: equipmentDrafts.map(\.confirmedName).filter { !$0.isEmpty })

        var seen: Set<String> = []
        return options.filter { option in
            guard !seen.contains(option) else { return false }
            seen.insert(option)
            return true
        }
    }

    func load(companyId: String?) async {
        guard !didLoad, let companyId else { return }
        didLoad = true

        do {
            existingEquipment = try await dataService.getAllEquipment(companyId: companyId)
        } catch {
            showMessage(
                title: "Equipment could not load.",
                message: "Scanner drafts will still work, but matching to existing equipment is unavailable."
            )
        }

        do {
            universalEquipmentCatalog = try await loadUniversalEquipmentCatalog()
            didLoadUniversalCatalog = true
        } catch {
            didLoadUniversalCatalog = true
            showMessage(
                title: "Universal catalog could not load.",
                message: "Scanner drafts can still be corrected and saved, but catalog matching is unavailable."
            )
        }
    }

    func generateDraftScan() {
        let photoIds = scanPhotos.map { $0.id.uuidString }
        let photoNames = scanPhotos.map(\.name)
        let sourceEquipment = Array(existingEquipment.prefix(4))
        let categories: [EquipmentCategory] = [.pump, .filter, .heater, .saltCell, .controlSystem, .autoChlorinator]
        let draftCount = max(3, min(5, max(scanPhotos.count, sourceEquipment.count)))

        equipmentDrafts = (0..<draftCount).map { index in
            let equipment = sourceEquipment.indices.contains(index) ? sourceEquipment[index] : nil
            let category = equipment?.type ?? categories[index % categories.count]
            let catalogMatch = bestUniversalCatalogMatch(for: equipment, category: category, index: index)

            return PoolEquipmentScanEquipmentDraft.draft(
                index: index,
                category: category,
                photoIds: photoIds,
                photoNames: photoNames,
                equipment: equipment,
                catalogMatch: catalogMatch
            )
        }

        rebuildStarterPipeSegments()

        withAnimation {
            workflowStep = .identify
        }
    }

    func addEquipmentDraft() {
        let nextIndex = equipmentDrafts.count
        let category = EquipmentCategory.allCases[nextIndex % EquipmentCategory.allCases.count]
        let catalogMatch = bestUniversalCatalogMatch(for: nil, category: category, index: nextIndex)
        equipmentDrafts.append(
            PoolEquipmentScanEquipmentDraft.draft(
                index: nextIndex,
                category: category,
                photoIds: scanPhotos.map { $0.id.uuidString },
                photoNames: scanPhotos.map(\.name),
                equipment: nil,
                catalogMatch: catalogMatch
            )
        )
    }

    func deleteEquipmentDraft(_ draft: PoolEquipmentScanEquipmentDraft) {
        equipmentDrafts.removeAll { $0.id == draft.id }
    }

    func addPipeSegment() {
        let trimmedFrom = pipeFromNode.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo = pipeToNode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFrom.isEmpty, !trimmedTo.isEmpty, trimmedFrom != trimmedTo else {
            showMessage(title: "Pipe segment needs two points.", message: "Choose different from and to points before adding the segment.")
            return
        }

        var segment = PoolEquipmentScanPipeSegment.segment(
            fromNode: trimmedFrom,
            toNode: trimmedTo,
            direction: pipeDirection
        )
        segment.diameter = pipeDiameter
        segment.notes = pipeNotes
        pipeSegments.append(segment)
        pipeNotes = ""

        withAnimation {
            workflowStep = .map
        }
    }

    func deletePipeSegment(_ segment: PoolEquipmentScanPipeSegment) {
        pipeSegments.removeAll { $0.id == segment.id }
    }

    func saveConfirmedScan(companyId: String?, user: DBUser?) async {
        guard let companyId else {
            showMessage(title: "Company missing.", message: "Select a company before saving scanner feedback.")
            return
        }

        guard canSave else {
            showMessage(title: "Nothing to save.", message: "Add at least one equipment draft or pipe segment before saving.")
            return
        }

        isSaving = true
        defer { isSaving = false }

        let now = Date()
        let scanId = "equip_scan_\(UUID().uuidString)"
        let equipmentDraftsForSave = normalizedEquipmentDraftsForSave()
        let userName = [user?.firstName, user?.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let session = PoolEquipmentScanSession(
            id: scanId,
            companyId: companyId,
            customerId: nil,
            serviceLocationId: nil,
            bodyOfWaterId: nil,
            createdByUserId: user?.id,
            createdByName: userName.isEmpty ? nil : userName,
            status: "confirmed",
            photoIds: scanPhotos.map { $0.id.uuidString },
            photoNames: scanPhotos.map(\.name),
            equipmentDrafts: equipmentDraftsForSave,
            pipeSegments: pipeSegments,
            technicianNotes: technicianNotes,
            modelVersion: "universal-catalog-feedback-v1",
            createdAt: now,
            updatedAt: now,
            confirmedAt: now
        )

        let feedback = PoolEquipmentScannerLearningFeedback(
            id: "equip_scan_feedback_\(UUID().uuidString)",
            scanId: scanId,
            companyId: companyId,
            confirmedByUserId: user?.id,
            confirmedByName: userName.isEmpty ? nil : userName,
            photoIds: scanPhotos.map { $0.id.uuidString },
            equipmentDrafts: equipmentDraftsForSave,
            pipeSegments: pipeSegments,
            correctionCount: correctionCount,
            confirmedAt: now
        )

        do {
            try await PoolEquipmentScannerManager.shared.saveConfirmedScan(
                companyId: companyId,
                session: session,
                feedback: feedback
            )
            showMessage(title: "Scan saved.", message: "Confirmed equipment and pipe feedback is ready for scanner learning.")
            resetAfterSave()
        } catch {
            showMessage(title: "Scan could not save.", message: error.localizedDescription)
        }
    }

    private func rebuildStarterPipeSegments() {
        let names = equipmentDrafts.map(\.confirmedName).filter { !$0.isEmpty }
        guard names.count >= 2 else {
            pipeSegments = []
            return
        }

        var starterSegments: [PoolEquipmentScanPipeSegment] = []
        starterSegments.append(.segment(fromNode: "Pool/Spa", toNode: names[0], direction: .suction))

        for index in 0..<(names.count - 1) {
            starterSegments.append(
                .segment(fromNode: names[index], toNode: names[index + 1], direction: index == 0 ? .pressure : .returnLine)
            )
        }

        if let last = names.last {
            starterSegments.append(.segment(fromNode: last, toNode: "Return Manifold", direction: .returnLine))
        }

        pipeSegments = starterSegments
        pipeFromNode = names.last ?? "Pool/Spa"
        pipeToNode = "Return Manifold"
    }

    private func loadUniversalEquipmentCatalog() async throws -> [UniversalEquipment] {
        let types = try await dataService.getUniversalEquipmentTypes()
        var catalog: [UniversalEquipment] = []

        for type in types {
            let makes = try await dataService.getUniversalEquipmentBrandsByType(type: type)
            for make in makes {
                let models = try await dataService.getUniversalEquipmentByTypeAndBrand(type: type, make: make)
                catalog.append(contentsOf: models)
            }
        }

        return catalog.sorted {
            [$0.type, $0.make, $0.model].joined(separator: " ") < [$1.type, $1.make, $1.model].joined(separator: " ")
        }
    }

    private func bestUniversalCatalogMatch(for equipment: Equipment?, category: EquipmentCategory, index: Int) -> UniversalEquipment? {
        let explicitIds = [equipment?.universalEquipmentId, equipment?.modelId]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let explicitMatch = universalEquipmentCatalog.first(where: { explicitIds.contains($0.id) }) {
            return explicitMatch
        }

        let scoredMatches = universalEquipmentCatalog
            .map { catalogEquipment in
                (equipment: catalogEquipment, score: universalCatalogScore(catalogEquipment, equipment: equipment, category: category))
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.equipment.model < rhs.equipment.model
                }
                return lhs.score > rhs.score
            }

        if let bestMatch = scoredMatches.first {
            return bestMatch.equipment
        }

        let categoryMatches = universalEquipmentCatalog.filter { universalCatalogCategoryMatches($0, category: category) }
        guard !categoryMatches.isEmpty else { return nil }
        return categoryMatches[index % categoryMatches.count]
    }

    private func universalCatalogScore(_ catalogEquipment: UniversalEquipment, equipment: Equipment?, category: EquipmentCategory) -> Int {
        var score = universalCatalogCategoryMatches(catalogEquipment, category: category) ? 12 : 0
        guard let equipment else { return score }

        let make = equipment.make.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let model = equipment.model.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let name = equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let catalogMake = catalogEquipment.make.lowercased()
        let catalogModel = catalogEquipment.model.lowercased()
        let catalogName = catalogEquipment.name.lowercased()

        if !make.isEmpty && catalogMake.contains(make) { score += 25 }
        if !model.isEmpty && catalogModel.contains(model) { score += 35 }
        if !name.isEmpty && (catalogName.contains(name) || name.contains(catalogModel)) { score += 10 }
        return score
    }

    private func universalCatalogCategoryMatches(_ catalogEquipment: UniversalEquipment, category: EquipmentCategory) -> Bool {
        if catalogEquipment.type.caseInsensitiveCompare(category.rawValue) == .orderedSame {
            return true
        }

        let searchText = "\(catalogEquipment.type) \(catalogEquipment.name) \(catalogEquipment.model)".lowercased()
        switch category {
        case .pump:
            return searchText.contains("pump")
        case .filter:
            return searchText.contains("filter")
        case .heater:
            return searchText.contains("heater")
        case .saltCell:
            return searchText.contains("salt")
        case .light:
            return searchText.contains("light")
        case .cleaner:
            return searchText.contains("cleaner") || searchText.contains("vacuum")
        case .controlSystem:
            return searchText.contains("control") || searchText.contains("automation")
        case .autoChlorinator:
            return searchText.contains("chlorinator") || searchText.contains("feeder")
        }
    }

    private func normalizedEquipmentDraftsForSave() -> [PoolEquipmentScanEquipmentDraft] {
        equipmentDrafts.map { draft in
            var normalizedDraft = draft
            let universalEquipmentId = normalizedDraft.universalEquipmentId.trimmingCharacters(in: .whitespacesAndNewlines)
            normalizedDraft.universalEquipmentId = universalEquipmentId
            normalizedDraft.matchedUniversalEquipmentId = universalEquipmentId.isEmpty ? nil : universalEquipmentId
            if normalizedDraft.modelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                normalizedDraft.modelId = universalEquipmentId
            }
            return normalizedDraft
        }
    }

    private func resetAfterSave() {
        scanPhotos = []
        equipmentDrafts = []
        pipeSegments = []
        technicianNotes = ""
        pipeFromNode = "Pool/Spa"
        pipeToNode = "Pump 1"
        pipeDirection = .suction
        pipeDiameter = ""
        pipeNotes = ""
        workflowStep = .capture
    }

    private func showMessage(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct PoolEquipmentScannerView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var VM: PoolEquipmentScannerViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: PoolEquipmentScannerViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    headerCard
                    workflowCard
                    captureCard
                    identifyCard
                    pipeMapCard
                    confirmationCard

                    Color.clear.frame(height: 80)
                }
                .padding(14)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Equipment Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await VM.load(companyId: masterDataManager.currentCompany?.id)
        }
        .alert(VM.alertTitle, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(VM.alertMessage)
        }
    }
}

private extension PoolEquipmentScannerView {
    var headerCard: some View {
        scannerCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "viewfinder.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Pool Equipment Scanner")
                        .font(.title3.weight(.semibold))

                    Text("Capture equipment photos, confirm detected gear, and map the above-ground pipe sequence.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Label("Flag 15", systemImage: "flag.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.poolBlue.opacity(0.12), in: Capsule())
            }
        }
    }

    var workflowCard: some View {
        scannerCard {
            HStack(spacing: 8) {
                ForEach(PoolEquipmentScanWorkflowStep.allCases) { step in
                    Button {
                        withAnimation {
                            VM.workflowStep = step
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: step.systemImage)
                                .font(.subheadline.weight(.semibold))

                            Text(step.rawValue)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(VM.workflowStep == step ? .white : Color.primary)
                        .background(
                            VM.workflowStep == step ? AnyShapeStyle(Color.poolBlue) : AnyShapeStyle(Color(.secondarySystemBackground)),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var captureCard: some View {
        scannerCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Capture", systemImage: "camera.fill", count: VM.scanPhotos.count)

                PhotoContentView(selectedImages: $VM.scanPhotos)

                Button {
                    VM.generateDraftScan()
                } label: {
                    Label("Draft Recognition", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    var identifyCard: some View {
        scannerCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionTitle("Identify Equipment", systemImage: "wrench.adjustable.fill", count: VM.equipmentDrafts.count)

                    Spacer()

                    Button {
                        VM.addEquipmentDraft()
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.poolGreen, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add equipment draft")
                }

                Label(VM.universalCatalogSummary, systemImage: "shippingbox.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.poolBlue.opacity(0.1), in: Capsule())

                if VM.equipmentDrafts.isEmpty {
                    emptyState("No equipment drafts yet.", systemImage: "viewfinder")
                } else {
                    VStack(spacing: 10) {
                        ForEach($VM.equipmentDrafts) { $draft in
                            equipmentDraftCard(draft: $draft)
                        }
                    }
                }
            }
        }
    }

    var pipeMapCard: some View {
        scannerCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionTitle("Pipe Path Map", systemImage: "point.topleft.down.curvedto.point.bottomright.up", count: VM.pipeSegments.count)
                    Spacer()
                }

                pipeBuilder

                if VM.pipeSegments.isEmpty {
                    emptyState("No pipe segments mapped yet.", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                } else {
                    VStack(spacing: 10) {
                        ForEach($VM.pipeSegments) { $segment in
                            pipeSegmentCard(segment: $segment)
                        }
                    }
                }
            }
        }
    }

    var confirmationCard: some View {
        scannerCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Confirm Learning", systemImage: "checkmark.seal.fill", count: VM.confirmedEquipmentCount + VM.confirmedPipeSegmentCount)

                HStack(spacing: 8) {
                    statPill(title: "Photos", value: "\(VM.scanPhotos.count)", color: .poolBlue)
                    statPill(title: "Equipment", value: "\(VM.confirmedEquipmentCount)", color: .poolGreen)
                    statPill(title: "Pipe", value: "\(VM.confirmedPipeSegmentCount)", color: .orange)
                    statPill(title: "Corrections", value: "\(VM.correctionCount)", color: .purple)
                }

                TextField("Technician notes", text: $VM.technicianNotes, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(4, reservesSpace: true)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    Task {
                        await VM.saveConfirmedScan(
                            companyId: masterDataManager.currentCompany?.id,
                            user: masterDataManager.user
                        )
                    }
                } label: {
                    HStack {
                        if VM.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "tray.and.arrow.down.fill")
                        }

                        Text(VM.isSaving ? "Saving Scan" : "Save Confirmed Scan")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(VM.canSave ? Color.poolGreen : Color.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!VM.canSave)
            }
        }
    }

    func equipmentDraftCard(draft: Binding<PoolEquipmentScanEquipmentDraft>) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(draft.wrappedValue.predictedName)
                        .font(.subheadline.weight(.semibold))

                    Text("\(Int(draft.wrappedValue.confidence * 100))% draft confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    VM.deleteEquipmentDraft(draft.wrappedValue)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolRed)
                        .frame(width: 32, height: 32)
                        .background(Color.poolRed.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }

            TextField("Confirmed name", text: draft.confirmedName)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 8) {
                Picker("Category", selection: draft.confirmedCategory) {
                    ForEach(EquipmentCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Toggle("Confirmed", isOn: draft.isConfirmed)
                    .labelsHidden()
                    .tint(Color.poolGreen)
            }

            HStack(spacing: 8) {
                TextField("Make", text: draft.make)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                TextField("Model", text: draft.model)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            EquipmentCatalogSelectionControl(
                dataService: VM.dataService,
                category: draft.confirmedCategory,
                typeId: draft.typeId,
                make: draft.make,
                makeId: draft.makeId,
                model: draft.model,
                modelId: draft.modelId,
                universalEquipmentId: universalEquipmentIdBinding(draft),
                manualPdfLink: draft.manualPdfLink,
                name: draft.confirmedName
            )

            if let predictedUniversalEquipmentId = draft.wrappedValue.predictedUniversalEquipmentId,
               !predictedUniversalEquipmentId.isEmpty,
               predictedUniversalEquipmentId != draft.wrappedValue.universalEquipmentId {
                Label("Catalog correction will train future recognition", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
            }

            if !VM.existingEquipment.isEmpty {
                Picker("Existing match", selection: matchedEquipmentBinding(draft)) {
                    Text("New equipment").tag("")
                    ForEach(VM.existingEquipment) { equipment in
                        Text(equipment.name.isEmpty ? equipment.type.rawValue : equipment.name).tag(equipment.id)
                    }
                }
                .pickerStyle(.menu)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            TextField("Corrections or identifying details", text: draft.correctionNotes, axis: .vertical)
                .font(.caption)
                .lineLimit(3, reservesSpace: true)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(draft.wrappedValue.isConfirmed ? Color.poolGreen.opacity(0.55) : Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    var pipeBuilder: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Picker("From", selection: $VM.pipeFromNode) {
                    ForEach(VM.endpointOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Picker("To", selection: $VM.pipeToNode) {
                    ForEach(VM.endpointOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack(spacing: 8) {
                Picker("Direction", selection: $VM.pipeDirection) {
                    ForEach(PoolEquipmentPipeDirection.allCases) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                .pickerStyle(.menu)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                TextField("Pipe size", text: $VM.pipeDiameter)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            TextField("Segment notes", text: $VM.pipeNotes, axis: .vertical)
                .font(.caption)
                .lineLimit(2, reservesSpace: true)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                VM.addPipeSegment()
            } label: {
                Label("Add Pipe Segment", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(.white)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    func pipeSegmentCard(segment: Binding<PoolEquipmentScanPipeSegment>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(segment.wrappedValue.fromNode) -> \(segment.wrappedValue.toNode)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    Text("\(segment.wrappedValue.direction.rawValue) line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Confirmed", isOn: segment.isConfirmed)
                    .labelsHidden()
                    .tint(Color.poolGreen)

                Button {
                    VM.deletePipeSegment(segment.wrappedValue)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolRed)
                        .frame(width: 30, height: 30)
                        .background(Color.poolRed.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("Material", text: segment.material)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                TextField("Diameter", text: segment.diameter)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            TextField("Notes", text: segment.notes, axis: .vertical)
                .font(.caption)
                .lineLimit(2, reservesSpace: true)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(segment.wrappedValue.isConfirmed ? Color.poolGreen.opacity(0.55) : Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    func sectionTitle(_ title: String, systemImage: String, count: Int? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.poolBlue)

            Text(title)
                .font(.headline)

            if let count {
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
    }

    func statPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.weight(.semibold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        }
    }

    func emptyState(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Color(.secondarySystemBackground), in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func scannerCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            }
    }

    func matchedEquipmentBinding(_ draft: Binding<PoolEquipmentScanEquipmentDraft>) -> Binding<String> {
        Binding(
            get: {
                draft.wrappedValue.matchedEquipmentId ?? ""
            },
            set: { newValue in
                var updated = draft.wrappedValue
                updated.matchedEquipmentId = newValue.isEmpty ? nil : newValue

                if let equipment = VM.existingEquipment.first(where: { $0.id == newValue }) {
                    updated.confirmedName = equipment.name
                    updated.confirmedCategory = equipment.type
                    updated.make = equipment.make
                    updated.model = equipment.model
                    updated.typeId = equipment.typeId
                    updated.makeId = equipment.makeId
                    updated.modelId = equipment.modelId
                    updated.manualPdfLink = equipment.manualPdfLink
                    let catalogId = equipment.universalEquipmentId.isEmpty ? equipment.modelId : equipment.universalEquipmentId
                    updated.universalEquipmentId = catalogId
                    updated.matchedUniversalEquipmentId = catalogId.isEmpty ? nil : catalogId
                }

                draft.wrappedValue = updated
            }
        )
    }

    func universalEquipmentIdBinding(_ draft: Binding<PoolEquipmentScanEquipmentDraft>) -> Binding<String> {
        Binding(
            get: {
                draft.wrappedValue.universalEquipmentId
            },
            set: { newValue in
                var updated = draft.wrappedValue
                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                updated.universalEquipmentId = trimmedValue
                updated.matchedUniversalEquipmentId = trimmedValue.isEmpty ? nil : trimmedValue
                draft.wrappedValue = updated
            }
        )
    }
}

#Preview {
    NavigationStack {
        PoolEquipmentScannerView(dataService: MockDataService())
            .environmentObject(MasterDataManager(dataService: MockDataService()))
    }
}
