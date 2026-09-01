//
//  ServiceLocationStartUpViewInField.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/14/24.
//

import SwiftUI

struct ServiceLocationStartUpViewInField: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var vm : JobTemplateViewModel
    @StateObject var VM : ServiceLocationStartUpViewModel

    init(
        dataService: any ProductionDataServiceProtocol,
        customerId: String,
        serviceLocationId: String,
        serviceStop: ServiceStop,
        serviceLocation: ServiceLocation? = nil,
        onOpenServiceAgreementWorkflow: (() -> Void)? = nil
    ) {
        _vm = StateObject(wrappedValue: JobTemplateViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: ServiceLocationStartUpViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _serviceStop = State(wrappedValue: serviceStop)
        self.serviceLocation = serviceLocation
        self.onOpenServiceAgreementWorkflow = onOpenServiceAgreementWorkflow

    }
    @State var customerId: String
    @State var serviceLocationId: String
    @State var serviceStop: ServiceStop
    let serviceLocation: ServiceLocation?
    let onOpenServiceAgreementWorkflow: (() -> Void)?
    
    @State var selectedBOW:BodyOfWater = BodyOfWater(
        id: UUID().uuidString,
        name: "Main Pool",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        notes: "",
        shape: "",
        length: [],
        depth: [],
        width: [],
        lastFilled: Date(),
        isActive: true
    )
    @State var bodyOfWaterList:[BodyOfWater] = []
    
    //Equipment
    @State var equipmentList:[Equipment] = []
    @State var selectedEquipmentId:String = ""
    @State var selectedEquipmentCategory:EquipmentCategory? = nil
    
    //Images
    @State var bodyOfWaterImages:[String:[DripDropImage]] = [:]
    @State var equipmentImages:[String:[DripDropImage]] = [:]
    @State private var serviceLocationPhotos: [DripDropImage] = []

    @State private var locationNickName: String = ""
    @State private var gateCode: String = ""
    @State private var locationNotes: String = ""
    @State private var saveMessage: String? = nil
    @State private var savedServiceLocationPhotoUrls: [DripDropStoredImage] = []
    @State private var surveyAutosaveTask: Task<Void, Never>? = nil
    @State private var lastAutosavedSurveyFingerprint: String = ""
    @State private var didSeedSurveyDraft: Bool = false
    @State private var didLoadExistingSurveyDraft: Bool = false
    @State private var isLoadingSurveyDraft: Bool = false
    @State private var didHydrateLocationFields: Bool = false
    @State private var currentStep: SurveyGuideStep = .siteNotes
    @State private var isSurveyNavigationExpanded: Bool = false
    @State private var showEquipmentEditor: Bool = false
    @State private var recommendationTitle: String = ""
    @State private var recommendationDetails: String = ""
    @State private var recommendationArea: SurveyRecommendationArea = .equipment
    @State private var recommendationPriority: SurveyRecommendationPriority = .recommended
    @State private var recommendationDrafts: [SurveyRecommendationDraft] = []
    @State private var serviceAgreementRecommendedPrice: String = ""
    @State private var serviceAgreementRateType: ServiceAgreementSurveyRateType = .perMonth
    @State private var serviceAgreementFieldNotes: String = ""
    @State private var serviceAgreementAutosaveTask: Task<Void, Never>? = nil
    @State private var lastAutosavedServiceAgreementFingerprint: String = ""
    @State private var didHydrateServiceAgreementRecommendation: Bool = false
    @State private var isSavingServiceAgreementRecommendation: Bool = false
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        surveyToolbar
                            .padding(.horizontal, 10)
                            .padding(.top, 8)

                        guidedSurveyContent
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .overlay(alignment: .trailing) {
                    surveyJumpDock(proxy: scrollProxy)
                        .zIndex(1)
                }
            }
            if VM.isLoading {
                ProgressView()
                    .padding(8)
                    .background(Color.darkGray)
                    .cornerRadius(8)
            }

            if isLoadingSurveyDraft {
                ProgressView("Loading survey")
                    .padding(10)
                    .background(Color.darkGray)
                    .cornerRadius(8)
            }
            
        }
        .onAppear {
            hydrateLocationFieldsIfPossible()
            hydrateServiceAgreementRecommendationIfNeeded()
            loadSurveyDraftIfNeeded()
        }
        .onChange(of: serviceLocation) { _ in
            hydrateLocationFieldsIfPossible()
        }
        .onChange(of: masterDataManager.currentCompany?.id) { _ in
            loadSurveyDraftIfNeeded()
        }
        .onChange(of: surveyAutosaveFingerprint) { _ in
            scheduleSurveyAutosave()
        }
        .onChange(of: serviceAgreementRecommendationFingerprint) { _ in
            scheduleServiceAgreementRecommendationAutosave()
        }
        .onChange(of: selectedEquipmentId, perform: { id in
            if id.isEmpty {
                showEquipmentEditor = false
            }
        })
        .sheet(isPresented: $showEquipmentEditor) {
            equipmentEditorSheet
        }
        .onDisappear {
            surveyAutosaveTask?.cancel()
            serviceAgreementAutosaveTask?.cancel()
        }
    }
}

//#Preview {
//    ServiceLocationStartUpView(dataService: MockDataService(), serviceLocation: MockDataService.mockServiceLocation)
//}
extension ServiceLocationStartUpViewInField {
    private func saveSurvey(companyId: String, includePendingPhotos: Bool) async throws {
        try await VM.createLocation(
            companyId: companyId,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterList: bodyOfWaterList,
            equipmentList: equipmentList,
            bodyOfWaterImages: includePendingPhotos ? bodyOfWaterImages : [:],
            equipmentImages: includePendingPhotos ? equipmentImages : [:],
            locationNickName: locationNickName,
            gateCode: gateCode,
            locationNotes: reportNotesForSave,
            serviceLocationPhotos: includePendingPhotos ? serviceLocationPhotos : []
        )
    }

    private func loadSurveyDraftIfNeeded() {
        guard !didLoadExistingSurveyDraft else { return }

        let companyIds = surveyLoadCompanyIds
        guard !companyIds.isEmpty else {
            seedSurveyDraftIfNeeded()
            return
        }

        didLoadExistingSurveyDraft = true
        isLoadingSurveyDraft = true

        Task {
            defer { isLoadingSurveyDraft = false }

            do {
                let existingSurvey = try await loadExistingSurveyDraft(companyIds: companyIds)

                if existingSurvey.bodyOfWaterList.isEmpty {
                    seedSurveyDraftIfNeeded()
                    return
                }

                bodyOfWaterList = existingSurvey.bodyOfWaterList
                equipmentList = existingSurvey.equipmentList
                selectedBOW = existingSurvey.bodyOfWaterList[0]
                selectedEquipmentId = ""
                selectedEquipmentCategory = nil
                didSeedSurveyDraft = true
                markSurveyAutosaveBaseline()
            } catch {
                print("Could not load existing survey draft")
                print(error)
                saveMessage = "Could not load existing survey"
                seedSurveyDraftIfNeeded()
                markSurveyAutosaveBaseline()
            }
        }
    }

    private var surveyLoadCompanyIds: [String] {
        var ids: [String] = []

        if let companyId = masterDataManager.currentCompany?.id, !companyId.isEmpty {
            ids.append(companyId)
        }

        if serviceStop.otherCompany,
           !serviceStop.contractedCompanyId.isEmpty,
           !ids.contains(serviceStop.contractedCompanyId) {
            ids.append(serviceStop.contractedCompanyId)
        }

        return ids
    }

    private func loadExistingSurveyDraft(
        companyIds: [String]
    ) async throws -> (bodyOfWaterList: [BodyOfWater], equipmentList: [Equipment]) {
        for companyId in companyIds {
            let bodyOfWaterList = try await VM.dataService.getAllBodiesOfWaterByServiceLocationId(
                companyId: companyId,
                serviceLocationId: serviceLocationId
            )
            let equipmentList = try await VM.dataService.getEquipmentByServiceLocationId(
                companyId: companyId,
                serviceLocationId: serviceLocationId
            )

            if !bodyOfWaterList.isEmpty || !equipmentList.isEmpty {
                return (
                    bodyOfWaterList.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
                    equipmentList.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                )
            }
        }

        return ([], [])
    }

    private func seedSurveyDraftIfNeeded() {
        guard !didSeedSurveyDraft else { return }

        didSeedSurveyDraft = true
        selectedBOW.customerId = customerId
        selectedBOW.serviceLocationId = serviceLocationId

        if bodyOfWaterList.isEmpty {
            bodyOfWaterList = [selectedBOW]
        }

        if equipmentList.isEmpty {
            equipmentList = [
                defaultEquipment(name: "Main Pump", type: .pump, bodyOfWaterId: selectedBOW.id),
                defaultEquipment(name: "Main Filter", type: .filter, bodyOfWaterId: selectedBOW.id)
            ]
        }

        markSurveyAutosaveBaseline()
    }

    private func hydrateLocationFieldsIfPossible() {
        if let serviceLocation, savedServiceLocationPhotoUrls.isEmpty {
            savedServiceLocationPhotoUrls = serviceLocation.photoUrls ?? []
        }

        guard !didHydrateLocationFields else { return }

        if let serviceLocation {
            locationNickName = serviceLocation.nickName
            gateCode = serviceLocation.gateCode
            locationNotes = serviceLocation.notes ?? ""
            didHydrateLocationFields = true
        } else if locationNickName.isEmpty {
            locationNickName = "\(serviceStop.customerName) Service Location"
        }
    }

    private func hydrateServiceAgreementRecommendationIfNeeded() {
        guard !didHydrateServiceAgreementRecommendation else { return }

        didHydrateServiceAgreementRecommendation = true

        let recommendedPriceCents =
            serviceStop.recommendedServiceAgreementPriceCents ??
            serviceStop.fieldRecommendedServiceAgreementPriceCents ??
            0

        serviceAgreementRecommendedPrice = recommendedPriceCents > 0
            ? dollarsString(fromCents: recommendedPriceCents)
            : ""
        serviceAgreementRateType = ServiceAgreementSurveyRateType(rawValue: serviceStop.recommendedServiceAgreementRateType ?? "") ?? .perMonth
        serviceAgreementFieldNotes = serviceStop.recommendedServiceAgreementNotes ?? ""
        lastAutosavedServiceAgreementFingerprint = serviceAgreementRecommendationFingerprint
    }

    private func defaultEquipment(
        name: String,
        type: EquipmentCategory,
        bodyOfWaterId: String
    ) -> Equipment {
        let createdAt = Date()
        let receivesRegularService = type == .filter || type == .saltCell
        let lastServiceDate = receivesRegularService ? createdAt : nil
        let serviceFrequency = receivesRegularService ? 6 : nil
        let serviceFrequencyEvery: EquipmentFrequency? = receivesRegularService ? .monthly : nil
        return Equipment(
            id: UUID().uuidString,
            name: name,
            type: type,
            typeId: "",
            make: "",
            makeId: "",
            model: "",
            modelId: "",
            dateInstalled: nil,
            createdAt: createdAt,
            status: .operational,
            needsService: receivesRegularService,
            cleanFilterPressure: type == .filter ? 15 : nil,
            currentPressure: type == .filter ? 20 : nil,
            lastServiceDate: lastServiceDate,
            serviceFrequency: serviceFrequency,
            serviceFrequencyEvery: serviceFrequencyEvery,
            nextServiceDate: getNextServiceDate(
                lastServiceDate: lastServiceDate,
                frequency: serviceFrequency,
                every: serviceFrequencyEvery
            ),
            notes: "",
            customerName: serviceStop.customerName,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: bodyOfWaterId,
            isActive: true
        )
    }

    private var locationSurveyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.headline)
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Survey")
                        .font(.headline.weight(.semibold))

                    Text(fullAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            VStack(spacing: 10) {
                surveyTextField(title: "Location Name", text: $locationNickName)
                surveyTextField(title: "Gate Code", text: $gateCode)
                surveyTextField(title: "Location Notes", text: $locationNotes, lineLimit: 3...6)
            }

            if !savedServiceLocationPhotoUrls.isEmpty {
                DripDropStoredImageRow(images: savedServiceLocationPhotoUrls)
            }

            PhotoContentView(selectedImages: $serviceLocationPhotos)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var fullAddress: String {
        [
            serviceStop.address.streetAddress,
            serviceStop.address.city,
            serviceStop.address.state,
            serviceStop.address.zip
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func surveyTextField(
        title: String,
        text: Binding<String>,
        lineLimit: ClosedRange<Int>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))

            if let lineLimit {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(lineLimit)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
                    )
                    .foregroundColor(Color.basicFontText)
            } else {
                TextField(title, text: text)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
                    )
                    .foregroundColor(Color.basicFontText)
            }
        }
    }

    var guidedSurveyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            surveySection(.siteNotes) {
                locationSurveyCard
            }

            surveySection(.waterProfile) {
                bodyOfWaterStep
            }

            surveySection(.equipmentProfile) {
                equipmentStep
            }

            surveySection(.salesFindings) {
                salesFindingsStep
            }

            surveySection(.agreementEstimate) {
                serviceAgreementEstimateStep
            }

            surveySection(.review) {
                reviewStep
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 24)
    }

    private func surveySection<Content: View>(
        _ step: SurveyGuideStep,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            guideStepCard(step)
            content()
        }
        .id(step)
    }

    private func guideStepCard(_ step: SurveyGuideStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: step.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(step.tint)
                    .frame(width: 34, height: 34)
                    .background(step.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.headline.weight(.semibold))

                    Text(step.guidance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                ForEach(step.checkpoints, id: \.self) { checkpoint in
                    Label(checkpoint, systemImage: "checkmark.circle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var bodyOfWaterStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            bodyOfWaterPicker
            bodyOfWaterStartUp
        }
    }

    var equipmentStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            selectedBodyOfWaterContext
            equipmentStartUp
        }
    }

    var selectedBodyOfWaterContext: some View {
        HStack(spacing: 10) {
            Image(systemName: "drop.fill")
                .foregroundStyle(Color.poolBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Equipment for \(selectedBOW.name)")
                    .font(.subheadline.weight(.semibold))

                Text("Add each system component, then mark status and service needs for the report.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var salesFindingsStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            equipmentFindingsCard
            recommendationEntryCard
            recommendationListCard
        }
    }

    var equipmentFindingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Equipment Flags", systemImage: "wrench.adjustable")
                .font(.headline.weight(.semibold))

            if equipmentSalesFindings.isEmpty {
                Text("No equipment has been marked for repair or maintenance yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(equipmentSalesFindings) { finding in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: finding.priority.systemImage)
                            .foregroundStyle(finding.priority.tint)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(finding.title)
                                .font(.subheadline.weight(.semibold))

                            Text(finding.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)
                    }
                    .padding(10)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var recommendationEntryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Add Sales Finding", systemImage: "plus.bubble")
                .font(.headline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                surveyTextField(title: "Recommendation", text: $recommendationTitle)
                surveyTextField(title: "Details for proposal/report", text: $recommendationDetails, lineLimit: 3...6)
            }

            HStack(spacing: 10) {
                recommendationMenu(
                    title: "Area",
                    value: recommendationArea.rawValue,
                    systemImage: recommendationArea.systemImage
                ) {
                    ForEach(SurveyRecommendationArea.allCases) { area in
                        Button {
                            recommendationArea = area
                        } label: {
                            Label(area.rawValue, systemImage: area.systemImage)
                        }
                    }
                }

                recommendationMenu(
                    title: "Priority",
                    value: recommendationPriority.rawValue,
                    systemImage: recommendationPriority.systemImage
                ) {
                    ForEach(SurveyRecommendationPriority.allCases) { priority in
                        Button {
                            recommendationPriority = priority
                        } label: {
                            Label(priority.rawValue, systemImage: priority.systemImage)
                        }
                    }
                }
            }

            Button {
                addRecommendation()
            } label: {
                Label("Add Finding", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
            .disabled(recommendationTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(recommendationTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func recommendationMenu<Content: View>(
        title: String,
        value: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var recommendationListCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Manual Findings", systemImage: "doc.text.magnifyingglass")
                .font(.headline.weight(.semibold))

            if recommendationDrafts.isEmpty {
                Text("Add anything the office should quote, discuss, or include in the initial report.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(recommendationDrafts) { finding in
                    recommendationRow(finding)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func recommendationRow(_ finding: SurveyRecommendationDraft) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: finding.priority.systemImage)
                .foregroundStyle(finding.priority.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(finding.title)
                    .font(.subheadline.weight(.semibold))

                Text("\(finding.area.rawValue) - \(finding.priority.rawValue)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if !finding.details.isEmpty {
                    Text(finding.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Button(role: .destructive) {
                recommendationDrafts.removeAll { $0.id == finding.id }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete finding")
        }
        .padding(10)
        .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var serviceAgreementEstimateStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            serviceAgreementPriceCard
            serviceAgreementWorkflowCard
        }
    }

    var serviceAgreementPriceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "signature")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Service Agreement Price")
                        .font(.headline.weight(.semibold))

                    Text(serviceAgreementRecommendationStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isSavingServiceAgreementRecommendation {
                    ProgressView()
                        .frame(width: 22, height: 22)
                } else if serviceAgreementRecommendedPriceCents > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.poolGreen)
                        .font(.title3)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                surveyCurrencyField(
                    title: "Recommended Price",
                    text: $serviceAgreementRecommendedPrice
                )

                serviceAgreementRateMenu
                    .frame(width: UIDevice.isIPhone ? 142 : 170)
            }

            surveyTextField(
                title: "Field Notes",
                text: $serviceAgreementFieldNotes,
                lineLimit: 3...6
            )
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var serviceAgreementWorkflowCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: canOpenFieldServiceAgreementWorkflow ? "paperplane.fill" : "lock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canOpenFieldServiceAgreementWorkflow ? Color.poolGreen : Color.secondary)
                .frame(width: 30, height: 30)
                .background(
                    (canOpenFieldServiceAgreementWorkflow ? Color.poolGreen : Color.secondary).opacity(0.12),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(canOpenFieldServiceAgreementWorkflow ? "Field Agreement Ready" : "Recommendation Captured")
                    .font(.subheadline.weight(.semibold))

                Text(canOpenFieldServiceAgreementWorkflow ? "Create or send the customer agreement from the field workflow." : "The office can turn this recommendation into the customer agreement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if canOpenFieldServiceAgreementWorkflow {
                Button {
                    openServiceAgreementDraft()
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 34, height: 34)
                        .background(Color.poolBlue, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open service agreement workflow")
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func surveyCurrencyField(
        title: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))

            HStack(spacing: 6) {
                Text("$")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)

                TextField("0.00", text: text)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.basicFontText)
            }
            .padding(10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
            )
        }
    }

    var serviceAgreementRateMenu: some View {
        Menu {
            ForEach(ServiceAgreementSurveyRateType.allCases) { rateType in
                Button {
                    serviceAgreementRateType = rateType
                } label: {
                    Label(rateType.label, systemImage: rateType.systemImage)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: serviceAgreementRateType.systemImage)
                    .foregroundStyle(Color.poolBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rate")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(serviceAgreementRateType.shortLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)
            }
            .padding(10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var serviceAgreementRecapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Agreement Recap", systemImage: "signature")
                .font(.headline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                summaryTile(title: "Price", value: serviceAgreementPriceDisplay, systemImage: "dollarsign.circle")
                summaryTile(title: "Rate", value: serviceAgreementRateType.shortLabel, systemImage: serviceAgreementRateType.systemImage)
            }

            if !serviceAgreementFieldNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(serviceAgreementFieldNotes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var reviewStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            surveySummaryCard
            serviceAgreementRecapCard
            reportPreviewCard
        }
    }

    var surveySummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Survey Summary", systemImage: "checklist")
                .font(.headline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                summaryTile(title: "Bodies", value: "\(bodyOfWaterList.count)", systemImage: "drop")
                summaryTile(title: "Equipment", value: "\(equipmentList.count)", systemImage: "wrench.and.screwdriver")
                summaryTile(title: "Photos", value: "\(surveyPhotoCount)", systemImage: "photo")
                summaryTile(title: "Findings", value: "\(equipmentSalesFindings.count + recommendationDrafts.count)", systemImage: "exclamationmark.bubble")
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func summaryTile(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.poolBlue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline.weight(.semibold))
            }

            Spacer(minLength: 4)
        }
        .padding(10)
        .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var reportPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Initial Report Notes", systemImage: "doc.plaintext")
                .font(.headline.weight(.semibold))

            Text(reportNotesForSave.isEmpty ? "No report notes added yet." : reportNotesForSave)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var surveyToolbar: some View {
        HStack(spacing: 8) {
            autosaveStatusPill

            if let saveMessage {
                Text(saveMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(saveMessageColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }

    func surveyJumpDock(proxy: ScrollViewProxy) -> some View {
        ZStack(alignment: .trailing) {
            if isSurveyNavigationExpanded {
                VStack(spacing: 10) {
                    ForEach(SurveyGuideStep.allCases) { step in
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                currentStep = step
                                proxy.scrollTo(step, anchor: .top)
                            }
                        } label: {
                            surveyDockIcon(
                                systemImage: step.systemImage,
                                tint: step.tint,
                                isSelected: currentStep == step
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(step.title)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isSurveyNavigationExpanded = false
                        }
                    } label: {
                        surveyDockIcon(
                            systemImage: "chevron.right",
                            tint: .secondary,
                            isSelected: false
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Collapse survey navigation")
                }
                .padding(7)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isSurveyNavigationExpanded = true
                    }
                } label: {
                    surveyDockIcon(
                        systemImage: "chevron.left",
                        tint: .poolBlue,
                        isSelected: false
                    )
                }
                .buttonStyle(.plain)
                .padding(7)
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .accessibilityLabel("Expand survey navigation")
            }
        }
        .padding(.trailing, 10)
        .padding(.bottom, UIDevice.isIPhone ? 18 : 14)
    }

    private func surveyDockIcon(
        systemImage: String,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    var autosaveStatusPill: some View {
        HStack(spacing: 6) {
            if VM.isLoading {
                ProgressView()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "checkmark.circle.fill")
            }

            Text(VM.isLoading ? "Saving" : "Auto-save")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.poolGreen.opacity(0.16), in: Capsule())
        .foregroundStyle(Color.poolGreen)
    }

    var bodyOfWaterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    addBodyOfWater()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(Color.poolBlue, in: Capsule())
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)

                ForEach(bodyOfWaterList) { BOW in
                    Button {
                        selectBodyOfWater(BOW)
                    } label: {
                        Label(BOW.name, systemImage: selectedBOW.id == BOW.id ? "drop.fill" : "drop")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                selectedBOW.id == BOW.id ? Color.poolBlue.opacity(0.14) : Color.listColor.opacity(0.75),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedBOW.id == BOW.id ? Color.poolBlue : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    var bodyOfWaterStartUp: some View {
        BodyOfWaterDetailStartUpView(
            bodiesOfWater: $bodyOfWaterList,
            selectedBodyOfWater: $selectedBOW,
            equipmentList: $equipmentList,
            photos: $bodyOfWaterImages
        )
    }

    var equipmentStartUp: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 36, height: 36)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Equipment Setup")
                        .font(.headline.weight(.semibold))

                    Text("Build the equipment profile for \(selectedBOW.name).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            ForEach(EquipmentCategory.allCases, id: \.self) { category in
                equipmentCategorySection(category)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func equipmentCategorySection(_ category: EquipmentCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(category.rawValue)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button {
                    addEquipment(for: category)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                        .background(Color.poolBlue, in: Circle())
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(category.rawValue)")
            }

            let equipmentForCategory = equipmentList
                .filter { $0.bodyOfWaterId == selectedBOW.id }
                .filter { $0.type == category }

            if equipmentForCategory.isEmpty {
                Text("No \(category.rawValue.lowercased()) equipment added.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(equipmentForCategory) { equipment in
                            equipmentChip(equipment, category: category)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func equipmentChip(_ equipment: Equipment, category: EquipmentCategory) -> some View {
        Button {
            presentEquipmentEditor(equipment, category: category)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedEquipmentId == equipment.id ? "square.and.pencil.circle.fill" : "square.and.pencil")
                Text(equipment.name)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                selectedEquipmentId == equipment.id ? Color.poolBlue.opacity(0.14) : Color.listColor.opacity(0.75),
                in: Capsule()
            )
            .foregroundStyle(selectedEquipmentId == equipment.id ? Color.poolBlue : Color.primary)
        }
        .buttonStyle(.plain)
    }

    var equipmentEditorSheet: some View {
        NavigationStack {
            ScrollView {
                EquipmentDetailStartUpView(
                    dataService: VM.dataService,
                    equipmentList: $equipmentList,
                    selectedEquipmentId: $selectedEquipmentId,
                    photos: $equipmentImages
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle(selectedEquipmentSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showEquipmentEditor = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var selectedEquipmentSheetTitle: String {
        guard let equipment = equipmentList.first(where: { $0.id == selectedEquipmentId }) else {
            return "Equipment"
        }

        let trimmedName = equipment.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? equipment.typeDisplayName : trimmedName
    }

    func presentEquipmentEditor(_ equipment: Equipment, category: EquipmentCategory) {
        selectedEquipmentId = equipment.id
        selectedEquipmentCategory = category
        showEquipmentEditor = true
    }

    func addBodyOfWater() {
        let name = "Pool \(bodyOfWaterList.count + 1)"
        let id = UUID().uuidString
        let bodyOfWater = BodyOfWater(
            id: id,
            name: name,
            gallons: "",
            material: "",
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            notes: "",
            shape: "",
            length: [],
            depth: [],
            width: [],
            lastFilled: Date(),
            isActive: true
        )

        bodyOfWaterList.append(bodyOfWater)
        selectedBOW = bodyOfWater
        equipmentList.append(
            contentsOf: [
                defaultEquipment(name: "Main Pump", type: .pump, bodyOfWaterId: selectedBOW.id),
                defaultEquipment(name: "Main Filter", type: .filter, bodyOfWaterId: selectedBOW.id)
            ]
        )
    }

    func selectBodyOfWater(_ bodyOfWater: BodyOfWater) {
        selectedBOW = bodyOfWater
        selectedEquipmentId = ""
        selectedEquipmentCategory = nil
        showEquipmentEditor = false
    }

    func addEquipment(for category: EquipmentCategory) {
        selectedEquipmentId = ""
        let newId = UUID().uuidString
        let count = equipmentList
            .filter { $0.bodyOfWaterId == selectedBOW.id }
            .filter { $0.type == category }
            .count + 1
        let name = "\(category.rawValue) \(count)"

        equipmentList.append(
            Equipment(
                id: newId,
                name: name,
                type: category,
                typeId: "",
                make: "",
                makeId: "",
                model: "",
                modelId: "",
                dateInstalled: nil,
                createdAt: Date(),
                status: .operational,
                needsService: false,
                notes: "",
                customerName: serviceStop.customerName,
                customerId: customerId,
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: selectedBOW.id,
                isActive: true
            )
        )
        selectedEquipmentId = newId
        selectedEquipmentCategory = category
        showEquipmentEditor = true
    }

    func submitSurvey(
        automated: Bool = false,
        includePendingPhotos: Bool = true,
        moveToReview: Bool = true
    ) {
        Task {
            guard !VM.isLoading else {
                if automated {
                    scheduleSurveyAutosave()
                }
                return
            }

            let fingerprintBeingSaved = surveyAutosaveFingerprint
            let companyIds = surveySaveCompanyIds
            guard !companyIds.isEmpty else {
                saveMessage = "Could not save survey"
                return
            }

            do {
                saveMessage = automated ? "Autosaving..." : "Saving survey..."

                for companyId in companyIds {
                    try await saveSurvey(companyId: companyId, includePendingPhotos: includePendingPhotos)
                }

                if includePendingPhotos {
                    if let primaryCompanyId = surveyPrimaryCompanyId {
                        try? await refreshSavedSurveyDraft(companyId: primaryCompanyId)
                    }

                    serviceLocationPhotos = []
                    bodyOfWaterImages = [:]
                    equipmentImages = [:]
                }

                lastAutosavedSurveyFingerprint = includePendingPhotos ? surveyAutosaveFingerprint : fingerprintBeingSaved
                saveMessage = automated ? "Autosaved" : "Survey saved"

                if moveToReview {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentStep = .review
                    }
                }

                if surveyAutosaveFingerprint != lastAutosavedSurveyFingerprint {
                    scheduleSurveyAutosave()
                }
            } catch {
                print("error")
                print(error)
                saveMessage = "Could not save survey"
            }
        }
    }

    func addRecommendation() {
        let title = recommendationTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let details = recommendationDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        recommendationDrafts.append(
            SurveyRecommendationDraft(
                title: title,
                details: details,
                area: recommendationArea,
                priority: recommendationPriority
            )
        )

        recommendationTitle = ""
        recommendationDetails = ""
        recommendationArea = .equipment
        recommendationPriority = .recommended
    }

    private var surveySaveCompanyIds: [String] {
        var ids: [String] = []

        if serviceStop.otherCompany,
           !serviceStop.contractedCompanyId.isEmpty {
            ids.append(serviceStop.contractedCompanyId)
        }

        if let companyId = masterDataManager.currentCompany?.id,
           !companyId.isEmpty,
           !ids.contains(companyId) {
            ids.append(companyId)
        }

        return ids
    }

    private var surveyPrimaryCompanyId: String? {
        if let companyId = masterDataManager.currentCompany?.id, !companyId.isEmpty {
            return companyId
        }

        if serviceStop.otherCompany, !serviceStop.contractedCompanyId.isEmpty {
            return serviceStop.contractedCompanyId
        }

        return nil
    }

    private func scheduleSurveyAutosave() {
        let fingerprint = surveyAutosaveFingerprint
        guard !fingerprint.isEmpty else { return }
        guard fingerprint != lastAutosavedSurveyFingerprint else { return }
        guard !surveySaveCompanyIds.isEmpty else { return }

        surveyAutosaveTask?.cancel()
        saveMessage = "Autosave pending"

        let includePendingPhotos = hasPendingSurveyPhotos
        let delay: UInt64 = includePendingPhotos ? 1_600_000_000 : 900_000_000

        surveyAutosaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: delay)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                submitSurvey(
                    automated: true,
                    includePendingPhotos: includePendingPhotos,
                    moveToReview: false
                )
            }
        }
    }

    private func scheduleServiceAgreementRecommendationAutosave() {
        let fingerprint = serviceAgreementRecommendationFingerprint
        guard fingerprint != lastAutosavedServiceAgreementFingerprint else { return }
        guard !surveySaveCompanyIds.isEmpty else { return }

        serviceAgreementAutosaveTask?.cancel()
        saveMessage = "Agreement autosave pending"

        serviceAgreementAutosaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 900_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                saveServiceAgreementRecommendation(fingerprintBeingSaved: fingerprint)
            }
        }
    }

    private func saveServiceAgreementRecommendation(fingerprintBeingSaved: String) {
        guard !isSavingServiceAgreementRecommendation else {
            scheduleServiceAgreementRecommendationAutosave()
            return
        }

        Task {
            isSavingServiceAgreementRecommendation = true
            defer { isSavingServiceAgreementRecommendation = false }

            let companyIds = surveySaveCompanyIds
            let priceCents = serviceAgreementRecommendedPriceCents
            let notes = serviceAgreementFieldNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            let userId = activeFieldUserId
            let userName = activeFieldUserName
            var didSave = false

            for companyId in companyIds {
                do {
                    try await VM.dataService.updateInitialSurveyServiceAgreementRecommendation(
                        companyId: companyId,
                        serviceStopId: serviceStop.id,
                        recommendedPriceCents: priceCents,
                        rateType: serviceAgreementRateType.rawValue,
                        notes: notes,
                        recommendedByUserId: userId,
                        recommendedByUserName: userName
                    )
                    didSave = true
                } catch {
                    print("Could not save service agreement recommendation")
                    print(error)
                }
            }

            if didSave {
                serviceStop.recommendedServiceAgreementPriceCents = priceCents
                serviceStop.fieldRecommendedServiceAgreementPriceCents = priceCents
                serviceStop.recommendedServiceAgreementRateType = serviceAgreementRateType.rawValue
                serviceStop.recommendedServiceAgreementNotes = notes
                serviceStop.recommendedServiceAgreementByUserId = userId
                serviceStop.recommendedServiceAgreementByUserName = userName
                serviceStop.recommendedServiceAgreementAt = Date()
                lastAutosavedServiceAgreementFingerprint = fingerprintBeingSaved
                saveMessage = "Agreement estimate saved"

                if serviceAgreementRecommendationFingerprint != lastAutosavedServiceAgreementFingerprint {
                    scheduleServiceAgreementRecommendationAutosave()
                }
            } else {
                saveMessage = "Agreement estimate could not save"
            }
        }
    }

    private func markSurveyAutosaveBaseline() {
        lastAutosavedSurveyFingerprint = surveyAutosaveFingerprint
    }

    private func refreshSavedSurveyDraft(companyId: String) async throws {
        let previousSelectedBodyOfWater = selectedBOW
        let existingSurvey = try await loadExistingSurveyDraft(companyIds: [companyId])

        if !existingSurvey.bodyOfWaterList.isEmpty {
            bodyOfWaterList = existingSurvey.bodyOfWaterList
            selectedBOW =
                bodyOfWaterList.first { $0.id == previousSelectedBodyOfWater.id } ??
                bodyOfWaterList.first {
                    $0.name.localizedCaseInsensitiveCompare(previousSelectedBodyOfWater.name) == .orderedSame
                } ??
                bodyOfWaterList[0]
        }

        equipmentList = existingSurvey.equipmentList

        if let refreshedLocation = try? await VM.dataService.getServiceLocationById(
            companyId: companyId,
            locationId: serviceLocationId
        ) {
            savedServiceLocationPhotoUrls = refreshedLocation.photoUrls ?? []
        }
    }

    func moveToNextStep() {
        guard let next = currentStep.next else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            currentStep = next
        }
    }

    func moveToPreviousStep() {
        guard let previous = currentStep.previous else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            currentStep = previous
        }
    }

    private var equipmentSalesFindings: [SurveyRecommendationDraft] {
        equipmentList
            .filter { $0.status != .operational || $0.needsService }
            .map { equipment in
                let priority: SurveyRecommendationPriority

                switch equipment.status {
                case .nonoperational:
                    priority = .urgent
                case .needsRepair:
                    priority = .recommended
                case .needsMaintenance:
                    priority = .maintenance
                case .replaced:
                    priority = .optional
                case .operational:
                    priority = equipment.needsService ? .maintenance : .optional
                }

                let statusText = equipment.status.displayName
                let notes = equipment.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                let details = notes.isEmpty
                    ? "\(equipment.typeDisplayName) marked \(statusText.lowercased())."
                    : notes

                return SurveyRecommendationDraft(
                    title: "\(equipment.name): \(statusText)",
                    details: details,
                    area: .equipment,
                    priority: priority
                )
            }
    }

    var surveyPhotoCount: Int {
        savedServiceLocationPhotoUrls.count
        + serviceLocationPhotos.count
        + bodyOfWaterList.reduce(0) { $0 + ($1.photoUrls?.count ?? 0) }
        + equipmentList.reduce(0) { $0 + ($1.photoUrls?.count ?? 0) }
        + bodyOfWaterImages.values.reduce(0) { $0 + $1.count }
        + equipmentImages.values.reduce(0) { $0 + $1.count }
    }

    private var hasPendingSurveyPhotos: Bool {
        serviceLocationPhotos.isEmpty == false ||
        bodyOfWaterImages.values.contains(where: { !$0.isEmpty }) ||
        equipmentImages.values.contains(where: { !$0.isEmpty })
    }

    private var saveMessageColor: Color {
        switch saveMessage ?? "" {
        case "Survey saved", "Autosaved", "Agreement estimate saved":
            return Color.poolGreen
        case "Autosave pending", "Autosaving...", "Saving survey...", "Agreement autosave pending":
            return Color.secondary
        default:
            return Color.poolRed
        }
    }

    private var surveyAutosaveFingerprint: String {
        [
            locationNickName,
            gateCode,
            baseLocationNotes,
            bodyOfWaterAutosaveFingerprint,
            equipmentAutosaveFingerprint,
            recommendationAutosaveFingerprint,
            pendingPhotoAutosaveFingerprint
        ]
            .joined(separator: "||")
    }

    private var bodyOfWaterAutosaveFingerprint: String {
        bodyOfWaterList
            .sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
            .map { bodyOfWater in
                [
                    bodyOfWater.id,
                    bodyOfWater.name,
                    bodyOfWater.gallons,
                    bodyOfWater.material,
                    bodyOfWater.customerId,
                    bodyOfWater.serviceLocationId,
                    bodyOfWater.notes ?? "",
                    bodyOfWater.shape ?? "",
                    (bodyOfWater.length ?? []).joined(separator: ","),
                    (bodyOfWater.depth ?? []).joined(separator: ","),
                    (bodyOfWater.width ?? []).joined(separator: ","),
                    "\(bodyOfWater.lastFilled.timeIntervalSince1970)",
                    bodyOfWater.isActive ? "active" : "inactive"
                ]
                    .joined(separator: "~")
            }
            .joined(separator: "^")
    }

    private var equipmentAutosaveFingerprint: String {
        equipmentList
            .sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
            .map { equipment in
                let lastServiceDate = timestampString(equipment.lastServiceDate)
                let nextServiceDate = timestampString(equipment.nextServiceDate)
                let dateUninstalled = timestampString(equipment.dateUninstalled)

                return [
                    equipment.id,
                    equipment.name,
                    equipment.typeStorageValue,
                    equipment.customTypeName,
                    equipment.typeId,
                    equipment.make,
                    equipment.makeId,
                    equipment.model,
                    equipment.modelId,
                    equipment.universalEquipmentId,
                    equipment.manualPdfLink,
                    timestampString(equipment.dateInstalled),
                    equipment.status.rawValue,
                    equipment.needsService ? "needs-service" : "no-service",
                    equipment.cleanFilterPressure.map(String.init) ?? "",
                    equipment.currentPressure.map(String.init) ?? "",
                    lastServiceDate,
                    equipment.serviceFrequency.map(String.init) ?? "",
                    equipment.serviceFrequencyEvery?.rawValue ?? "",
                    nextServiceDate,
                    equipment.notes,
                    equipment.customerName,
                    equipment.customerId,
                    equipment.serviceLocationId,
                    equipment.bodyOfWaterId,
                    equipment.isActive ? "active" : "inactive",
                    dateUninstalled
                ]
                    .joined(separator: "~")
            }
            .joined(separator: "^")
    }

    private func timestampString(_ date: Date?) -> String {
        guard let date else {
            return ""
        }

        return String(date.timeIntervalSince1970)
    }

    private var recommendationAutosaveFingerprint: String {
        recommendationDrafts
            .map { recommendation in
                [
                    recommendation.id,
                    recommendation.title,
                    recommendation.details,
                    recommendation.area.rawValue,
                    recommendation.priority.rawValue
                ]
                    .joined(separator: "~")
            }
            .joined(separator: "^")
    }

    private var pendingPhotoAutosaveFingerprint: String {
        let serviceLocationFingerprint = dripDropImageFingerprint(serviceLocationPhotos)
        let bodyFingerprints = bodyOfWaterImages
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key):\(dripDropImageFingerprint($0.value))" }
            .joined(separator: "^")
        let equipmentFingerprints = equipmentImages
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key):\(dripDropImageFingerprint($0.value))" }
            .joined(separator: "^")

        return [
            serviceLocationFingerprint,
            bodyFingerprints,
            equipmentFingerprints
        ]
            .joined(separator: "||")
    }

    private var serviceAgreementRecommendationFingerprint: String {
        [
            normalizedCurrencyInput(serviceAgreementRecommendedPrice),
            serviceAgreementRateType.rawValue,
            serviceAgreementFieldNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
            .joined(separator: "||")
    }

    private var serviceAgreementRecommendedPriceCents: Int {
        let normalized = normalizedCurrencyInput(serviceAgreementRecommendedPrice)
        return Int(((Double(normalized) ?? 0) * 100).rounded())
    }

    private var serviceAgreementRecommendationStatusText: String {
        if let recommendedByUserName = serviceStop.recommendedServiceAgreementByUserName,
           !recommendedByUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Recommended by \(recommendedByUserName)"
        }

        if serviceAgreementRecommendedPriceCents > 0 {
            return "Recommendation ready for the service agreement."
        }

        return "Add the field price recommendation for the office or agreement workflow."
    }

    private var serviceAgreementPriceDisplay: String {
        guard serviceAgreementRecommendedPriceCents > 0 else {
            return "$0"
        }

        return dollarsString(fromCents: serviceAgreementRecommendedPriceCents)
    }

    private var activeFieldUserId: String {
        masterDataManager.companyUser?.userId ?? masterDataManager.user?.id ?? ""
    }

    private var activeFieldUserName: String {
        let companyUserName = masterDataManager.companyUser?.userName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !companyUserName.isEmpty {
            return companyUserName
        }

        let userName = [
            masterDataManager.user?.firstName,
            masterDataManager.user?.lastName
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return userName.isEmpty ? "Field user" : userName
    }

    private var canOpenFieldServiceAgreementWorkflow: Bool {
        hasRolePermission("400") ||
        hasRolePermission("432") ||
        hasRolePermission("438") ||
        hasRolePermission("628")
    }

    private func hasRolePermission(_ permissionId: String) -> Bool {
        guard let role = masterDataManager.role else {
            return false
        }

        return role.permissionIdList.contains(permissionId)
    }

    private func normalizedCurrencyInput(_ value: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        let filtered = value
            .unicodeScalars
            .filter { allowedCharacters.contains($0) }
        let components = String(String.UnicodeScalarView(filtered)).split(separator: ".", omittingEmptySubsequences: false)

        guard components.count > 1 else {
            return String(String.UnicodeScalarView(filtered))
        }

        return "\(components[0]).\(components.dropFirst().joined())"
    }

    private func dollarsString(fromCents cents: Int) -> String {
        let dollars = Double(cents) / 100
        return dollars.formatted(.number.precision(.fractionLength(2)))
    }

    private func openServiceAgreementDraft() {
        if let onOpenServiceAgreementWorkflow {
            onOpenServiceAgreementWorkflow()
            return
        }

        guard let url = serviceAgreementDraftURL else {
            saveMessage = "Could not open agreement workflow"
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private var serviceAgreementDraftURL: URL? {
        var components = URLComponents(string: "https://dripdrop-poolapp.com/company/sales/agreements/new")
        components?.queryItems = [
            URLQueryItem(name: "customerId", value: customerId),
            URLQueryItem(name: "serviceLocationId", value: serviceLocationId),
            URLQueryItem(name: "serviceStopId", value: serviceStop.id)
        ]
            .filter { !($0.value ?? "").isEmpty }

        return components?.url
    }

    private func dripDropImageFingerprint(_ images: [DripDropImage]) -> String {
        images
            .map { "\($0.id.uuidString):\($0.name)" }
            .joined(separator: ",")
    }

    var reportNotesForSave: String {
        let baseNotes = baseLocationNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let findings = allReportFindings

        guard !findings.isEmpty else {
            return baseNotes
        }

        let findingsText = findings
            .enumerated()
            .map { index, finding in
                let detail = finding.details.isEmpty ? "" : " - \(finding.details)"
                return "\(index + 1). [\(finding.priority.rawValue)] \(finding.area.rawValue): \(finding.title)\(detail)"
            }
            .joined(separator: "\n")

        if baseNotes.isEmpty {
            return "Survey Findings\n\(findingsText)"
        }

        return "\(baseNotes)\n\nSurvey Findings\n\(findingsText)"
    }

    var baseLocationNotes: String {
        let marker = "\n\nSurvey Findings\n"

        if let markerRange = locationNotes.range(of: marker) {
            return String(locationNotes[..<markerRange.lowerBound])
        }

        return locationNotes
    }

    private var allReportFindings: [SurveyRecommendationDraft] {
        equipmentSalesFindings + recommendationDrafts
    }
}

private enum SurveyGuideStep: String, CaseIterable, Identifiable {
    case siteNotes
    case waterProfile
    case equipmentProfile
    case salesFindings
    case agreementEstimate
    case review

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .siteNotes:
            return "Site Notes"
        case .waterProfile:
            return "Water Profile"
        case .equipmentProfile:
            return "Equipment Profile"
        case .salesFindings:
            return "Sales Findings"
        case .agreementEstimate:
            return "Agreement Estimate"
        case .review:
            return "Finish & Recap"
        }
    }

    var shortTitle: String {
        switch self {
        case .siteNotes:
            return "Site"
        case .waterProfile:
            return "Water"
        case .equipmentProfile:
            return "Equipment"
        case .salesFindings:
            return "Findings"
        case .agreementEstimate:
            return "Agreement"
        case .review:
            return "Recap"
        }
    }

    var systemImage: String {
        switch self {
        case .siteNotes:
            return "mappin.and.ellipse"
        case .waterProfile:
            return "drop.fill"
        case .equipmentProfile:
            return "wrench.and.screwdriver.fill"
        case .salesFindings:
            return "exclamationmark.bubble.fill"
        case .agreementEstimate:
            return "signature"
        case .review:
            return "checklist.checked"
        }
    }

    var tint: Color {
        switch self {
        case .siteNotes:
            return .poolBlue
        case .waterProfile:
            return .teal
        case .equipmentProfile:
            return .orange
        case .salesFindings:
            return .poolRed
        case .agreementEstimate:
            return .poolBlue
        case .review:
            return .poolGreen
        }
    }

    var guidance: String {
        switch self {
        case .siteNotes:
            return "Capture access notes, gate code, location photos, and anything the office needs before creating the agreement."
        case .waterProfile:
            return "Document each pool, spa, or other body of water with structure, gallons, dimensions, notes, and photos."
        case .equipmentProfile:
            return "Build the equipment list for the selected body of water, including make, model, status, service needs, and photos."
        case .salesFindings:
            return "Flag repair needs, upgrades, safety concerns, or sales opportunities for the proposal and initial report."
        case .agreementEstimate:
            return "Capture the recurring service price recommendation before the agreement is drafted or sent."
        case .review:
            return "Review the survey, agreement estimate, photos, and report notes before finishing the visit."
        }
    }

    var checkpoints: [String] {
        switch self {
        case .siteNotes:
            return ["Access", "Notes", "Photos"]
        case .waterProfile:
            return ["Type", "Gallons", "Photos"]
        case .equipmentProfile:
            return ["Catalog", "Status", "Service"]
        case .salesFindings:
            return ["Repairs", "Upgrades", "Report"]
        case .agreementEstimate:
            return ["Price", "Rate", "Field"]
        case .review:
            return ["Summary", "Agreement", "Notes"]
        }
    }

    var position: Int {
        (Self.allCases.firstIndex(of: self) ?? 0) + 1
    }

    var stepLabel: String {
        "Step \(position)"
    }

    var next: SurveyGuideStep? {
        guard let index = Self.allCases.firstIndex(of: self) else { return nil }
        let nextIndex = index + 1
        guard Self.allCases.indices.contains(nextIndex) else { return nil }
        return Self.allCases[nextIndex]
    }

    var previous: SurveyGuideStep? {
        guard let index = Self.allCases.firstIndex(of: self) else { return nil }
        let previousIndex = index - 1
        guard Self.allCases.indices.contains(previousIndex) else { return nil }
        return Self.allCases[previousIndex]
    }
}

private enum ServiceAgreementSurveyRateType: String, CaseIterable, Identifiable {
    case perMonth
    case perVisit
    case oneTime

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .perMonth:
            return "Monthly Service"
        case .perVisit:
            return "Per Visit"
        case .oneTime:
            return "One-Time Startup"
        }
    }

    var shortLabel: String {
        switch self {
        case .perMonth:
            return "Monthly"
        case .perVisit:
            return "Per Visit"
        case .oneTime:
            return "One-Time"
        }
    }

    var systemImage: String {
        switch self {
        case .perMonth:
            return "calendar"
        case .perVisit:
            return "arrow.triangle.2.circlepath"
        case .oneTime:
            return "sparkles"
        }
    }
}

private enum SurveyRecommendationArea: String, CaseIterable, Identifiable {
    case equipment = "Equipment"
    case water = "Water"
    case safety = "Safety"
    case access = "Access"
    case servicePlan = "Service Plan"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .equipment:
            return "wrench.and.screwdriver"
        case .water:
            return "drop"
        case .safety:
            return "shield"
        case .access:
            return "key"
        case .servicePlan:
            return "doc.text"
        }
    }
}

private enum SurveyRecommendationPriority: String, CaseIterable, Identifiable {
    case urgent = "Urgent"
    case recommended = "Recommended"
    case maintenance = "Maintenance"
    case optional = "Optional"

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .urgent:
            return "exclamationmark.triangle.fill"
        case .recommended:
            return "star.fill"
        case .maintenance:
            return "calendar.badge.clock"
        case .optional:
            return "lightbulb"
        }
    }

    var tint: Color {
        switch self {
        case .urgent:
            return Color.poolRed
        case .recommended:
            return Color.orange
        case .maintenance:
            return Color.poolBlue
        case .optional:
            return Color.secondary
        }
    }
}

private struct SurveyRecommendationDraft: Identifiable, Equatable {
    let id: String
    var title: String
    var details: String
    var area: SurveyRecommendationArea
    var priority: SurveyRecommendationPriority

    init(
        id: String = UUID().uuidString,
        title: String,
        details: String,
        area: SurveyRecommendationArea,
        priority: SurveyRecommendationPriority
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.area = area
        self.priority = priority
    }
}
