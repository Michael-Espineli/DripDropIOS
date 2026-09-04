    //
    //  ServiceStopInfoView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/3/23.
    //



import SwiftUI
import UIKit
import FirebaseFunctions

struct ServiceStopUtilityView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var navigationManager: NavigationStateManager
    
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel
    
    @Binding var stopData : StopData
    @State var serviceStopId: String
    @Binding private var testerStripScanImage: UIImage?
    let testerStripScanToken: UUID?
    let onScanTesterStrip: (() -> Void)?
    
    @State var finished:Bool = false
    @State var skipped:Bool = false
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var invoiced:Bool = false
    @State var stopDataList:[StopData] = []
    @State var initialLoadFinished:Bool = false
    @State var previousStopDataView:String = "Table"
    @State var previousStopDataViewoptions:[String] = ["Table","Chart"]
    @State var selectedObservations:[String] = []
    @State var selectedTask:[String] = []
    
    @State var selectedInputId:String = ""
    @State var selectedInputIdList:[String] = []
    
    @State var showObservations:Bool = false
    @State var showTasks:Bool = true
    
    @State var showReadings:Bool = true
    @State var showDosages:Bool = true
    @State private var isAnalyzingTesterStrip: Bool = false
    @State private var testerStripStatusMessage: String? = nil
    @State private var testerStripAppliedReadingTemplateIds: Set<String> = []
    @State private var testerStripReviewScanId: String? = nil
    @FocusState var chemicalInput:Bool

    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )

    init(
        stopData: Binding<StopData>,
        serviceStopId: String,
        testerStripScanImage: Binding<UIImage?> = .constant(nil),
        testerStripScanToken: UUID? = nil,
        onScanTesterStrip: (() -> Void)? = nil
    ) {
        self._stopData = stopData
        self._serviceStopId = State(wrappedValue: serviceStopId)
        self._testerStripScanImage = testerStripScanImage
        self.testerStripScanToken = testerStripScanToken
        self.onScanTesterStrip = onScanTesterStrip
    }
    
    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }

    private var isInputLocked: Bool {
        guard let serviceStop else { return true }
        return continuationGate(for: serviceStop) != nil
    }

    private var selectedBodyOfWaterTitle: String {
        if VM.isLoadingInitialDetails && VM.selectedBOW == nil {
            return "Loading Water"
        }

        guard let selected = VM.selectedBOW,
              !selected.name.isEmpty else {
            return "Select Water"
        }

        return selected.name
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            if let serviceStop {
                VStack(spacing: 0) {
                    bodyOfWaterPicker
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            if VM.isLoadingInitialDetails && VM.selectedBOW == nil {
                                waterDataLoadingState
                            } else if let bodyOfWater = VM.selectedBOW {
                                if bodyOfWater.id ==  "" {
                                    Text("No Bodies of Water")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                } else {
                                        //Replace with the version of stopData in the customer service history Page
                                    previousStopData

                                    if isInputLocked {
                                        waterLockNotice
                                    }

                                    observations(serviceStop)
                                        .disabled(isInputLocked)
                                        .opacity(isInputLocked ? 0.55 : 1)

                                    if serviceStop.includeReadings {
                                        testerStripScanControl
                                            .disabled(isInputLocked)
                                            .opacity(isInputLocked ? 0.55 : 1)
                                    }

                                    if serviceStop.includeReadings {
                                        readingInput(serviceStop)
                                            .disabled(isInputLocked)
                                            .opacity(isInputLocked ? 0.55 : 1)
                                    }
                                    if serviceStop.includeDosages {
                                        dosageInput(serviceStop)
                                            .disabled(isInputLocked)
                                            .opacity(isInputLocked ? 0.55 : 1)
                                    }
                                }
                            } else {
                                ContentUnavailableView(
                                    "No Bodies of Water",
                                    systemImage: "drop.triangle",
                                    description: Text("Add a body of water before recording readings.")
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 18)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: VM.selectedBOW?.id)
                .onChange(of: VM.selectedBOW, perform: { BOW in
                    Task{
                        if let bodyOfWater = BOW,
                           let company = masterDataManager.currentCompany,
                           let user = masterDataManager.user {
                            print("Body Of Water Change \(bodyOfWater.id)")
                            await VM.onChangeOfBodyOfWater(companyId: company.id, bodyOfWater: bodyOfWater)
                            stopData = VM.serviceLocationStopData.first(where: {
                                $0.serviceStopId == serviceStop.id &&
                                $0.serviceLocationId == serviceStop.serviceLocationId &&
                                $0.bodyOfWaterId == bodyOfWater.id
                            }) ?? StopData(
                                id: UUID().uuidString,
                                date: serviceStop.serviceDate,
                                serviceStopId: serviceStop.id,
                                readings: [],
                                dosages: [],
                                observation: [],
                                bodyOfWaterId: bodyOfWater.id,
                                customerId: serviceStop.customerId,
                                serviceLocationId: serviceStop.serviceLocationId,
                                userId: user.id,
                                equipmentMeasurements: []
                            )
                        }
                    }
                })
                .onChange(of: serviceStop, perform: { stop in
                    print("Service Stop Change From Utility View")
                })
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let serviceStop,
               let continuationGate = continuationGate(for: serviceStop) {
                ServiceStopContinuationBanner(title: continuationGate.title) {
                    handleContinuationGate(continuationGate, serviceStop: serviceStop)
                }
            }
        }
        .task(id: testerStripScanToken) {
            guard testerStripScanToken != nil else { return }
            testerStripReviewScanId = nil
            await fillReadingsFromTesterStrip()
        }
        .onAppear {
            ensureBodyOfWaterSelection()
        }
        .onChange(of: VM.bodiesOfWater) { _ in
            ensureBodyOfWaterSelection()
        }
    }
}

extension ServiceStopUtilityView {
    private func continuationGate(for serviceStop: ServiceStop) -> ServiceStopContinuationGate? {
        if vm.activeRoute?.status.requiresStartToContinueServiceStopWork == true {
            return .startRoute
        }

        if serviceStop.startTime == nil {
            return .startServiceStop
        }

        return nil
    }

    private func handleContinuationGate(_ gate: ServiceStopContinuationGate, serviceStop: ServiceStop) {
        switch gate {
        case .startRoute:
            vm.startActiveRoute(
                companyId: masterDataManager.currentCompany?.id,
                companyName: masterDataManager.currentCompany?.name,
                user: masterDataManager.user
            )
        case .startServiceStop:
            vm.startServiceStop(
                companyId: masterDataManager.currentCompany?.id,
                serviceStopId: serviceStop.id,
                startTime: vm.arrivalTimeForServiceStop(serviceStop.id) ?? Date()
            )
        }
    }

    private func resetButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                Text("Reset")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray))
            .foregroundStyle(Color.poolWhite)
        }
        .accessibilityLabel("Reset")
    }

    var sideBar:some View {
        ZStack{
            HStack{
                if skipped {
                    ZStack{
                        Rectangle()
                            .fill(Color.realYellow)
                            .frame(width: 5,height: 25)
                        
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                } else {
                    ZStack{
                        Rectangle()
                            .fill(finished ? Color.poolGreen : Color.gray)
                            .frame(width: 5,height: 25)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
            
            if skipped {
                ZStack{
                    Rectangle()
                        .fill(Color.realYellow)
                        .frame(width: 5,height: 25)
                    
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            } else {
                ZStack{
                    Rectangle()
                        .fill(finished ? Color.poolGreen : Color.gray)
                        .frame(height: 5)
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
        }
    }

    private var testerStripScanControl: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: {
                        if testerStripScanImage == nil {
                            onScanTesterStrip?()
                        } else {
                            Task { await fillReadingsFromTesterStrip() }
                        }
                    }, label: {
                        HStack(spacing: 6) {
                            if isAnalyzingTesterStrip {
                                ProgressView()
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: testerStripScanImage == nil ? "viewfinder" : "checkmark.viewfinder")
                                    .font(.caption.weight(.semibold))
                            }

                            Text(testerStripScanImage == nil ? "Scan Strip" : "Fill Readings")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(testerStripScanImage == nil ? Color.poolBlue : Color.poolGreen)
                        )
                        .foregroundStyle(Color.poolWhite)
                        .shadow(
                            color: (testerStripScanImage == nil ? Color.poolBlue : Color.poolGreen).opacity(0.18),
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                    })
                    .disabled(isAnalyzingTesterStrip || (testerStripScanImage == nil && onScanTesterStrip == nil))
                    .accessibilityLabel(testerStripScanImage == nil ? "Scan tester strip" : "Fill readings from tester strip")

                    if testerStripScanImage != nil {
                        resetButton(action: resetTesterStrip)
                        .disabled(isAnalyzingTesterStrip)
                        .accessibilityLabel("Reset tester strip")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if let testerStripStatusMessage {
                Text(testerStripStatusMessage)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    @MainActor
    private func fillReadingsFromTesterStrip() async {
        guard !isAnalyzingTesterStrip else { return }
        guard let testerStripScanImage else { return }
        guard let companyId = masterDataManager.currentCompany?.id else {
            testerStripStatusMessage = "Select a company before reading the strip."
            return
        }
        guard let serviceStop else {
            testerStripStatusMessage = "Service stop is not ready yet."
            return
        }
        guard let bodyOfWater = VM.selectedBOW else {
            testerStripStatusMessage = "Select a body of water before reading the strip."
            return
        }

        isAnalyzingTesterStrip = true
        testerStripStatusMessage = "Saving strip photo..."

        do {
            var reviewPhotoStored = true
            var testerStripReview: TesterStripScanReview?
            do {
                testerStripReview = try await ensureTesterStripReviewImageStored(
                    companyId: companyId,
                    serviceStop: serviceStop,
                    bodyOfWater: bodyOfWater,
                    image: testerStripScanImage
                )
            } catch {
                reviewPhotoStored = false
                print("Tester strip review image upload failed:", error)
            }

            testerStripStatusMessage = "Reading strip..."
            let readings = try await VM.analyzeTesterStripScan(
                companyId: companyId,
                serviceStopId: serviceStop.id,
                bodyOfWaterId: bodyOfWater.id,
                image: testerStripScanImage,
                scanId: testerStripReview?.id ?? testerStripReviewScanId,
                scanImageURL: testerStripReview?.image.imageURL
            )
            let filledCount = applyTesterStripReadings(readings, bodyOfWaterId: bodyOfWater.id)
            if readings.isEmpty {
                testerStripStatusMessage = "No readings found on strip."
            } else if filledCount == 0 {
                testerStripStatusMessage = "Strip read, but no matching reading fields were found."
            } else {
                testerStripStatusMessage = "\(filledCount) reading\(filledCount == 1 ? "" : "s") filled from strip.\(reviewPhotoStored ? "" : " Review photo not saved.")"
            }
        } catch {
            testerStripStatusMessage = testerStripErrorMessage(for: error)
        }

        isAnalyzingTesterStrip = false
    }

    @MainActor
    private func resetTesterStrip() {
        testerStripScanImage = nil
        testerStripStatusMessage = nil
        isAnalyzingTesterStrip = false

        if let testerStripReviewScanId {
            stopData.testerStripScans?.removeAll { $0.id == testerStripReviewScanId }
            self.testerStripReviewScanId = nil
        }

        guard let bodyOfWaterId = VM.selectedBOW?.id else {
            testerStripAppliedReadingTemplateIds = []
            return
        }

        stopData.readings.removeAll { reading in
            testerStripAppliedReadingTemplateIds.contains(reading.universalTemplateId) &&
            reading.bodyOfWaterId == bodyOfWaterId
        }
        testerStripAppliedReadingTemplateIds = []
    }

    @MainActor
    private func ensureTesterStripReviewImageStored(
        companyId: String,
        serviceStop: ServiceStop,
        bodyOfWater: BodyOfWater,
        image: UIImage
    ) async throws -> TesterStripScanReview {
        if let scanId = testerStripReviewScanId,
           let existingReview = stopData.testerStripScans?.first(where: { $0.id == scanId }) {
            return existingReview
        }

        let scanId = testerStripReviewScanId ?? "tester_strip_scan_\(UUID().uuidString)"
        testerStripReviewScanId = scanId

        let storedImage = try await VM.uploadTesterStripReviewImage(
            companyId: companyId,
            serviceStopId: serviceStop.id,
            scanId: scanId,
            image: image
        )

        let review = TesterStripScanReview(
            id: scanId,
            profileId: "aquachek_7_in_1",
            profileName: "AquaChek 7-in-1",
            serviceStopId: serviceStop.id,
            bodyOfWaterId: bodyOfWater.id,
            image: storedImage,
            createdAt: Date()
        )

        var scans = stopData.testerStripScans ?? []
        scans.removeAll { $0.id == scanId }
        scans.append(review)
        stopData.testerStripScans = scans

        return review
    }

    @MainActor
    @discardableResult
    private func applyTesterStripReadings(_ readings: [Reading], bodyOfWaterId: String) -> Int {
        let validReadings = readings.compactMap { reading in
            testerStripReading(reading, bodyOfWaterId: bodyOfWaterId)
        }
        let filledTemplateIds = Set(validReadings.map(\.universalTemplateId))

        stopData.readings.removeAll { reading in
            filledTemplateIds.contains(reading.universalTemplateId) &&
            reading.bodyOfWaterId == bodyOfWaterId
        }
        stopData.readings.append(contentsOf: validReadings)
        testerStripAppliedReadingTemplateIds = filledTemplateIds
        showReadings = true
        selectedInputId = ""
        return validReadings.count
    }

    private func testerStripReading(_ reading: Reading, bodyOfWaterId: String) -> Reading? {
        guard let template = testerStripTemplate(for: reading) else { return nil }
        let amount = reading.amount ?? ""
        guard !amount.isEmpty else { return nil }

        return Reading(
            id: reading.id,
            templateId: template.id,
            universalTemplateId: template.readingsTemplateId,
            dosageType: template.chemType,
            name: template.name,
            amount: amount,
            UOM: template.UOM,
            bodyOfWaterId: bodyOfWaterId
        )
    }

    private func testerStripTemplate(for reading: Reading) -> SavedReadingsTemplate? {
        let candidates = [
            reading.universalTemplateId,
            reading.templateId,
            reading.dosageType,
            reading.name ?? "",
        ].flatMap { testerStripTemplateAliases(for: $0) }

        return VM.readingTemplates.first { template in
            let templateKeys = [
                template.readingsTemplateId,
                template.id,
                template.chemType,
                template.name,
            ].flatMap { testerStripTemplateAliases(for: $0) }

            return candidates.contains { candidate in
                templateKeys.contains(candidate)
            }
        }
    }

    private func testerStripTemplateAliases(for value: String) -> Set<String> {
        let key = testerStripTemplateKey(value)
        var aliases: Set<String> = key.isEmpty ? [] : [key]

        switch key {
        case "totalalkalinity":
            aliases.insert("alkalinity")
        case "alkalinity":
            aliases.insert("totalalkalinity")
        case "ph":
            aliases.insert("potentialhydrogen")
        case "cya":
            aliases.insert("cyanuricacid")
        case "cyanuricacid":
            aliases.insert("cya")
        case "totalchlorinebromine":
            aliases.insert("totalchlorine")
            aliases.insert("totalbromine")
            aliases.insert("bromine")
        case "totalchlorine":
            aliases.insert("totalchlorinebromine")
        case "totalbromine", "bromine":
            aliases.insert("totalchlorinebromine")
        default:
            break
        }

        return aliases
    }

    private func testerStripTemplateKey(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func testerStripErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == FunctionsErrorDomain,
           nsError.code == FunctionsErrorCode.notFound.rawValue {
            return "AquaChek tester strip setup was not found. Seed or enable the AquaChek 7-in-1 profile, then try again."
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.uppercased() == "NOT_FOUND" || message.lowercased().contains("not found") {
            return "AquaChek tester strip setup was not found. Seed or enable the AquaChek 7-in-1 profile, then try again."
        }

        return message.isEmpty ? "Tester strip scan failed." : message
    }

    var bodyOfWaterPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.poolBlue.opacity(0.12))
                        .frame(width: 34, height: 34)

                    Image(systemName: "drop.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.poolBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Body of Water")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(selectedBodyOfWaterTitle)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                }

                Spacer()

                if VM.isLoadingInitialDetails && VM.selectedBOW == nil {
                    ProgressView()
                        .controlSize(.mini)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                } else if let selected = VM.selectedBOW {
                    Text(bodyOfWaterMetaText(selected))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if VM.isLoadingInitialDetails && VM.bodiesOfWater.isEmpty {
                        bodyOfWaterLoadingChips
                    } else if VM.bodiesOfWater.isEmpty {
                        ContentUnavailableView(
                            "No Bodies of Water",
                            systemImage: "drop.triangle",
                            description: Text("Add a body of water before recording readings.")
                        )
                        .frame(minWidth: 280)
                        .padding(.vertical, 6)
                    } else {
                        ForEach(VM.bodiesOfWater) { bodyOfWater in
                            bodyOfWaterChip(bodyOfWater)
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
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func bodyOfWaterChip(_ bodyOfWater: BodyOfWater) -> some View {
        let isSelected = VM.selectedBOW?.id == bodyOfWater.id

        return Button {
            VM.selectedBOW = bodyOfWater
        } label: {
            HStack(spacing: 9) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(bodyOfWater.name.isEmpty ? "Unnamed Water" : bodyOfWater.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(bodyOfWaterMetaText(bodyOfWater))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.82) : Color.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minWidth: 128, alignment: .leading)
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
        .disabled(isInputLocked)
    }

    private func bodyOfWaterMetaText(_ bodyOfWater: BodyOfWater) -> String {
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

    var waterLockNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.orange)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Start Required")
                    .font(.subheadline.weight(.semibold))

                Text("You can review and scroll water history now. Start the route or service stop before changing readings, dosages, or observations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.vertical, 8)
    }

    var previousStopData: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label("Recent Water History", systemImage: "tablecells")
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 8)

                if let first = VM.currentHistory.first {
                    NavigationLink(value: Route.customerStopDataDetailView(dataService: dataService, customerId: first.customerId)) {
                        HStack(spacing: 6) {
                            Text("Details")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)

                            Image(systemName: "arrow.up.right")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(Color.poolGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.poolGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if VM.isLoadingInitialDetails && VM.currentHistory.isEmpty {
                waterHistoryLoadingState
            } else {
                StopDataTableView(
                    stopData: VM.currentHistory,
                    readingTemplates: VM.readingTemplates,
                    dosageTemplates: VM.dosageTemplates,
                    bodyOfWaterId: VM.selectedBOW?.id
                )
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    var bodyOfWaterLoadingChips: some View {
        ForEach(0..<2, id: \.self) { index in
            HStack(spacing: 9) {
                ProgressView()
                    .controlSize(.mini)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.secondary.opacity(0.18))
                        .frame(width: index == 0 ? 92 : 118, height: 10)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: index == 0 ? 76 : 88, height: 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minWidth: 128, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    var waterDataLoadingState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Loading Water Data")
                        .font(.subheadline.weight(.semibold))

                    Text("Getting bodies of water, recent history, readings, and dosages.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 10) {
                waterLoadingRow(width: 210)
                waterLoadingRow(width: 168)
                waterLoadingRow(width: 190)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.top, 8)
    }

    var waterHistoryLoadingState: some View {
        VStack(spacing: 10) {
            waterLoadingRow(width: 184)
            waterLoadingRow(width: 142)
            waterLoadingRow(width: 168)
        }
        .padding(.vertical, 4)
    }

    func waterLoadingRow(width: CGFloat) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.secondary.opacity(0.14))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: width, height: 10)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: max(92, width - 46), height: 8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.listColor.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    var table: some View {
        VStack(spacing:0){
            if VM.currentHistory.isEmpty {
                ZStack{
                    Text("No Data Yet")
                }
            } else {
                
                StopDataRowTitle(readingTemplates: VM.readingTemplates, dosageTemplates: VM.dosageTemplates)
                ForEach(VM.currentHistory) { data in
                    Divider()
                    StopDataRow(dataService:dataService,stopData: data, readingTemplates: VM.readingTemplates, dosageTemplate: VM.dosageTemplates)
                }
            }
        }
    }
    var chart: some View {
        VStack{
            TabView{
                ForEach(VM.readingTemplates) { templates in
                    StopDataReadingChartView(stopData: VM.currentHistory,readingTemplate: templates)
                }
                ForEach(VM.dosageTemplates) { templates in
                    StopDataDosageChartView(stopData: VM.currentHistory,dosageTemplate: templates)
                }
            }
            .tabViewStyle(.page)
            .frame(minWidth: 300, minHeight: 150)
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 10))
        }
        
    }
    var tasks: some View {
        ZStack{
                //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.realYellow)
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                }
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Tasks")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.realYellow))
                            .foregroundStyle(Color.basicFontText)
                        }
                    } else {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(finished ? Color.poolGreen.opacity(0.25) : Color.gray.opacity(0.25))
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(finished ? Color.poolGreen : Color.gray)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                    Button(action: {
                                        showObservations.toggle()
                                    }, label: {
                                        ZStack {
                                            Circle().fill(finished ? Color.poolGreen : Color.gray)
                                            Image(systemName: showObservations ? "chevron.up" : "chevron.down")
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    })
                                    
                                }
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Tasks")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill((finished ? Color.poolGreen : Color.gray)))
                            .foregroundStyle(Color.white)
                        }
                    }
                    
                }
                if showTasks {
                    if let stop = masterDataManager.selectedServiceStops {
                        StopDataTaskView(stop: stop, selectedTasks: $selectedTask)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .padding(10)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            
        }
    }
    
    private var selectedBodyOfWaterId: String {
        VM.selectedBOW?.id ?? bodyOfWater.id
    }

    private var selectedReadingCount: Int {
        stopData.readings.filter { itemMatchesSelectedBodyOfWater($0.bodyOfWaterId) }.count
    }

    private var selectedDosageCount: Int {
        stopData.dosages.filter { itemMatchesSelectedBodyOfWater($0.bodyOfWaterId) }.count
    }

    private func resetReadings() {
        stopData.readings.removeAll { itemMatchesSelectedBodyOfWater($0.bodyOfWaterId) }
        selectedInputId = ""
        showReadings = true
    }

    private func resetDosages() {
        stopData.dosages.removeAll { itemMatchesSelectedBodyOfWater($0.bodyOfWaterId) }
        selectedInputId = ""
        showDosages = true
    }

    private func itemMatchesSelectedBodyOfWater(_ itemBodyOfWaterId: String) -> Bool {
        let itemId = itemBodyOfWaterId.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedId = selectedBodyOfWaterId.trimmingCharacters(in: .whitespacesAndNewlines)

        return itemId.isEmpty || itemId == selectedId
    }

    private func waterSection<Content: View>(
        title: String,
        systemImage: String,
        count: Int,
        isExpanded: Bool,
        isComplete: Bool,
        resetAction: @escaping () -> Void,
        toggleAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let tint = isComplete ? Color.poolGreen : Color.poolBlue

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(isComplete ? "Recorded" : "Not Recorded")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("\(count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(minWidth: 26)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.12), in: Capsule())

                Button(action: resetAction) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset \(title)")

                Button(action: toggleAction) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse \(title)" : "Expand \(title)")
            }

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func observations(_ serviceStop: ServiceStop) -> some View {
        waterSection(
            title: "Observations",
            systemImage: "eye.fill",
            count: stopData.observation.count,
            isExpanded: showObservations,
            isComplete: !stopData.observation.isEmpty,
            resetAction: {
                stopData.observation = []
                selectedInputId = ""
                showDosages = true
            },
            toggleAction: {
                showObservations.toggle()
            }
        ) {
            StopDataObservationsView(
                stop: serviceStop,
                selectedObservations: $selectedObservations,
                stopData: $stopData
            )
        }
    }
    private func readingInput(_ serviceStop: ServiceStop) -> some View {
        waterSection(
            title: "Readings",
            systemImage: "testtube.2",
            count: selectedReadingCount,
            isExpanded: showReadings,
            isComplete: selectedReadingCount > 0,
            resetAction: resetReadings,
            toggleAction: {
                showReadings.toggle()
            }
        ) {
            VStack(spacing: 8) {
                ForEach(VM.readingTemplates) { template in
                    StopDataReadingInputView(
                        stopDataList: $stopDataList,
                        template: template,
                        bodyOfWaterId: selectedBodyOfWaterId,
                        selectedId: $selectedInputId,
                        selectedIdList: VM.selectedInputIdList,
                        stopData: $stopData,
                        serviceStopId: serviceStop.id,
                        serviceDate: serviceStop.serviceDate,
                        customerId: serviceStop.customerId,
                        serviceLocationId: serviceStop.serviceLocationId
                    )
                }
            }
        }
    }

    private func dosageInput(_ serviceStop: ServiceStop) -> some View {
        waterSection(
            title: "Dosages",
            systemImage: "drop.degreesign",
            count: selectedDosageCount,
            isExpanded: showDosages,
            isComplete: selectedDosageCount > 0,
            resetAction: resetDosages,
            toggleAction: {
                showDosages.toggle()
            }
        ) {
            VStack(spacing: 8) {
                ForEach(VM.dosageTemplates) { template in
                    StopDataDosageInputView(
                        stopDataList: $stopDataList,
                        template: template,
                        bodyOfWaterId: selectedBodyOfWaterId,
                        selectedId: $selectedInputId,
                        selectedIdList: VM.selectedInputIdList,
                        stopData: $stopData,
                        serviceStopId: serviceStop.id,
                        serviceDate: serviceStop.serviceDate,
                        observations: selectedObservations,
                        gallons: Int(
                            VM.selectedBOW?.gallons ?? bodyOfWater.gallons
                        ) ?? 16_000
                    )
                }
            }
        }
    }
    var homeNav: some View {
        
        ZStack{
            if let stop = masterDataManager.selectedServiceStops {
                
                Button(action: {
#if os(iOS)
                    
                    let address = "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                    
                    let urlText = address.replacingOccurrences(of: " ", with: "?")
                    
                    let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
#endif
                }, label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("\(stop.address.streetAddress)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(skipped ? Color.realYellow : (finished ? Color.poolGreen : Color.gray))
                    )
                    .foregroundStyle(skipped ? Color.basicFontText : Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                })
                
                
            }
        }
    }
}
