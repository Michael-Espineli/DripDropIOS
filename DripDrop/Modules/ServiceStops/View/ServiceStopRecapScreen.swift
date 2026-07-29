    //
    //  ServiceStopRecapScreen.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 3/18/24.
    //

    import SwiftUI
    import PhotosUI

    enum photoPickerType: Identifiable {
        var id: Self { self }
        case album
        case camera
    }

    @MainActor
    final class ServiceStopRecapWorkSummaryViewModel: ObservableObject {
        @Published private(set) var jobs: [Job] = []
        @Published private(set) var repairRequests: [RepairRequest] = []
        @Published private(set) var pendingParts: [ShoppingListItem] = []
        @Published private(set) var invoices: [SalesInvoice] = []
        @Published private(set) var isLoading: Bool = false
        @Published private(set) var errorMessage: String? = nil

        var hasOperationalWork: Bool {
            !jobs.isEmpty || !repairRequests.isEmpty || !pendingParts.isEmpty
        }

        var hasAnyVisibleWork: Bool {
            hasOperationalWork || !invoices.isEmpty
        }

        func load(
            companyId: String,
            serviceStop: ServiceStop,
            includeFinance: Bool,
            dataService: any ProductionDataServiceProtocol
        ) async {
            isLoading = true
            errorMessage = nil

            do {
                let jobResults = try await dataService.getAllJobsByCustomer(
                    companyId: companyId,
                    customerId: serviceStop.customerId
                )
                let repairRequestResults = try await dataService.getRepairRequestsByCustomer(
                    companyId: companyId,
                    customerId: serviceStop.customerId
                )
                let partResults = try await dataService.getAllShoppingListItemsByCompanyCustomer(
                    companyId: companyId,
                    customerId: serviceStop.customerId
                )
                let invoicesResult = includeFinance
                    ? try await dataService.getSalesInvoices(companyId: companyId, customerId: serviceStop.customerId)
                    : []

                jobs = jobResults
                    .filter { job in
                        job.serviceLocationId == serviceStop.serviceLocationId &&
                        job.operationStatus != .finished &&
                        ![JobBillingStatus.paid, .comped, .expired].contains(job.billingStatus)
                    }
                    .sorted { $0.dateCreated > $1.dateCreated }

                repairRequests = repairRequestResults
                    .filter { request in
                        request.locationId == serviceStop.serviceLocationId &&
                        request.status.isOpenWorkQueueItem
                    }
                    .sorted { $0.date > $1.date }

                pendingParts = partResults
                    .filter { item in
                        let matchesLinkedJob = item.jobId.map { jobId in
                            jobs.contains(where: { $0.id == jobId })
                        } ?? false

                        return item.status.needsShoppingAction &&
                        (item.serviceLocationId == serviceStop.serviceLocationId ||
                         matchesLinkedJob)
                    }
                    .sorted { ($0.actionDate ?? $0.datePurchased ?? Date.distantPast) > ($1.actionDate ?? $1.datePurchased ?? Date.distantPast) }

                invoices = invoicesResult
                    .filter { invoice in
                        invoiceAppliesToCurrentLocation(invoice, serviceLocationId: serviceStop.serviceLocationId) &&
                        invoiceNeedsAttention(invoice)
                    }
                    .sorted { invoiceSortDate($0) < invoiceSortDate($1) }
            } catch {
                jobs = []
                repairRequests = []
                pendingParts = []
                invoices = []
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }

        private func invoiceAppliesToCurrentLocation(_ invoice: SalesInvoice, serviceLocationId: String) -> Bool {
            guard let locationIds = invoice.serviceLocationIds, !locationIds.isEmpty else { return true }
            return locationIds.contains(serviceLocationId)
        }

        private func invoiceNeedsAttention(_ invoice: SalesInvoice) -> Bool {
            if invoice.status == .open || invoice.status == .partiallyPaid || invoice.status == .overdue {
                return true
            }

            if let dueDate = invoice.dueDate, dueDate < Date(), invoice.status != .paid {
                return true
            }

            return false
        }

        private func invoiceSortDate(_ invoice: SalesInvoice) -> Date {
            invoice.dueDate ?? invoice.createdAt ?? Date.distantFuture
        }
    }

    struct ServiceStopRecapScreen: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.presentationMode) var presentationMode

        @EnvironmentObject var navigationManager: NavigationStateManager
        @EnvironmentObject var masterDataManager: MasterDataManager

        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject var VM: ServiceStopDetailViewModel
        @StateObject private var workSummaryViewModel = ServiceStopRecapWorkSummaryViewModel()

        @State var serviceStop: ServiceStop
        @Binding var stopData: StopData
        @State var tasks: [ServiceStopTask]

        @State var showPhotoSelectionOptions: Bool = false

        @State private var showCamera = false
        @State var image: UIImage?

        @State var opStatus: ServiceStopOperationStatus = .notFinished

        @State var showSkipReason: Bool = false
        @State var skipReason: String = ""
        @State var isLoading: Bool = true
        @State private var finishErrorMessage: String? = nil

        // Photos
        @State var pickerType: photoPickerType? = nil
        @State var selectedNewPicker: photoPickerType? = nil
        @State var selectedImage: UIImage? = nil
        @State var images: [UIImage] = []

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: true) {
                    VStack(spacing: 14) {
                        headerCard

                        outstandingWorkSummary

                        recapCard

                        observationRecap

                        taskRecap

                        photos
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom) {
                statusActionBar
            }
            .alert("Provide skip reason", isPresented: $showSkipReason) {
                TextField("reason", text: $skipReason)
                Button("OK", action: submitSkipReason)
            } message: {
                Text("Will send to customer and manager")
                    .font(.footnote)
            }
            .alert(
                "Unable To Finish",
                isPresented: Binding(
                    get: { finishErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            finishErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    finishErrorMessage = nil
                }
            } message: {
                Text(finishErrorMessage ?? "")
            }
            .onAppear {
                opStatus = serviceStop.operationStatus
            }
            .task(id: serviceStop.id) {
                await loadOutstandingWorkSummary()
            }
            .onChange(of: selectedImage) { image in
                if let image {
                    images.append(image)
                }
            }
        }

        private var canViewFinanceSummary: Bool {
            masterDataManager.role?.permissionIdList.contains(where: { permissionId in
                permissionId == "400" || permissionId == "13"
            }) == true
        }

        private func loadOutstandingWorkSummary() async {
            guard let company = masterDataManager.currentCompany else { return }

            await workSummaryViewModel.load(
                companyId: company.id,
                serviceStop: serviceStop,
                includeFinance: canViewFinanceSummary,
                dataService: dataService
            )
        }

        func submitSkipReason() {
            if skipReason == "" {
                print("Did not Provide a Reason")
            } else {
                print("You skipped because \(skipReason)")
            }
        }
    }

    struct ServiceStopRecapScreen_Previews: PreviewProvider {
        static let dataService = ProductionDataService()

        static var previews: some View {
            @State var stopData: StopData = StopData(
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

            ServiceStopRecapScreen(
                serviceStop: MockDataService().mockServiceStops.first!,
                stopData: $stopData,
                tasks: []
            )
        }
    }

    // MARK: - Main Layout

    extension ServiceStopRecapScreen {

        var headerCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Service Stop Recap")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(serviceStop.customerName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(opStatus.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                HStack(spacing: 8) {
                    Label(shortDate(date: serviceStop.serviceDate), systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())

                    Label("\(tasks.count) Tasks", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())

                    Label("\(VM.selectedDripDropPhotos.count + images.count) Photos", systemImage: "photo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())

                    Spacer()
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var outstandingWorkSummary: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    sectionHeader("Outstanding Work", systemImage: "tray.full")

                    Spacer()

                    if workSummaryViewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    workSummaryMetric(
                        title: "Jobs",
                        count: workSummaryViewModel.jobs.count,
                        systemImage: "briefcase",
                        tint: .poolBlue
                    )

                    workSummaryMetric(
                        title: "Parts",
                        count: workSummaryViewModel.pendingParts.count,
                        systemImage: "shippingbox",
                        tint: .orange
                    )

                    workSummaryMetric(
                        title: "Repairs",
                        count: workSummaryViewModel.repairRequests.count,
                        systemImage: "wrench.and.screwdriver",
                        tint: .red
                    )

                    if canViewFinanceSummary {
                        workSummaryMetric(
                            title: "Invoices",
                            count: workSummaryViewModel.invoices.count,
                            systemImage: "doc.text",
                            tint: .purple
                        )
                    }
                }

                if let errorMessage = workSummaryViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if !workSummaryViewModel.isLoading && !workSummaryViewModel.hasAnyVisibleWork {
                    emptyState(
                        title: "No Outstanding Work",
                        message: "No open jobs, repair requests, or pending parts are linked to this location.",
                        systemImage: "checkmark.seal"
                    )
                } else {
                    VStack(spacing: 10) {
                        if !workSummaryViewModel.jobs.isEmpty {
                            workSummarySection(
                                title: "Jobs",
                                count: workSummaryViewModel.jobs.count,
                                systemImage: "briefcase",
                                tint: .poolBlue
                            ) {
                                ForEach(workSummaryViewModel.jobs.prefix(3), id: \.id) { job in
                                    workSummaryRow(
                                        title: job.internalId,
                                        subtitle: nonEmpty(job.type, fallback: "Open job"),
                                        detail: job.operationStatus.rawValue,
                                        systemImage: "briefcase"
                                    )
                                }
                            }
                        }

                        if !workSummaryViewModel.pendingParts.isEmpty {
                            workSummarySection(
                                title: "Parts Pending",
                                count: workSummaryViewModel.pendingParts.count,
                                systemImage: "shippingbox",
                                tint: .orange
                            ) {
                                ForEach(workSummaryViewModel.pendingParts.prefix(3), id: \.id) { item in
                                    workSummaryRow(
                                        title: item.name,
                                        subtitle: nonEmpty(item.description, fallback: "Material needed"),
                                        detail: item.status.rawValue,
                                        systemImage: "shippingbox"
                                    )
                                }
                            }
                        }

                        if !workSummaryViewModel.repairRequests.isEmpty {
                            workSummarySection(
                                title: "Repair Requests",
                                count: workSummaryViewModel.repairRequests.count,
                                systemImage: "wrench.and.screwdriver",
                                tint: .red
                            ) {
                                ForEach(workSummaryViewModel.repairRequests.prefix(3), id: \.id) { request in
                                    workSummaryRow(
                                        title: request.status.displayName,
                                        subtitle: nonEmpty(request.description, fallback: "Open repair request"),
                                        detail: shortDate(date: request.date),
                                        systemImage: "wrench.and.screwdriver"
                                    )
                                }
                            }
                        }

                        if canViewFinanceSummary && !workSummaryViewModel.invoices.isEmpty {
                            workSummarySection(
                                title: "Invoices",
                                count: workSummaryViewModel.invoices.count,
                                systemImage: "doc.text",
                                tint: .purple
                            ) {
                                ForEach(workSummaryViewModel.invoices.prefix(3), id: \.id) { invoice in
                                    workSummaryRow(
                                        title: nonEmpty(invoice.invoiceNumber, fallback: "Invoice"),
                                        subtitle: invoiceSubtitle(invoice),
                                        detail: moneyText(invoice.amountDueCents ?? invoice.totalAmountCents),
                                        systemImage: invoiceIsOverdue(invoice) ? "exclamationmark.circle" : "doc.text"
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .refreshable {
                await loadOutstandingWorkSummary()
            }
        }

        func workSummaryMetric(title: String, count: Int, systemImage: String, tint: Color) -> some View {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(count)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        func workSummarySection<Content: View>(
            title: String,
            count: Int,
            systemImage: String,
            tint: Color,
            @ViewBuilder content: () -> Content
        ) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)

                    Spacer()

                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tint.opacity(0.12), in: Capsule())
                }

                content()
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        func workSummaryRow(title: String, subtitle: String, detail: String, systemImage: String) -> some View {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }

        func invoiceSubtitle(_ invoice: SalesInvoice) -> String {
            let statusText = invoiceIsOverdue(invoice) ? "Overdue" : invoice.status.rawValue
            guard let dueDate = invoice.dueDate else { return statusText }
            return "\(statusText) - Due \(shortDate(date: dueDate))"
        }

        func invoiceIsOverdue(_ invoice: SalesInvoice) -> Bool {
            invoice.status == .overdue || ((invoice.dueDate ?? Date.distantFuture) < Date() && invoice.status != .paid)
        }

        func moneyText(_ cents: Int) -> String {
            (Double(cents) / 100.0).formatted(.currency(code: "USD"))
        }

        func nonEmpty(_ text: String, fallback: String) -> String {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedText.isEmpty ? fallback : trimmedText
        }

        var recapCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                if serviceStop.typeId == "0E398067-1E3D-487A-BC21-1CC3A54933D5" {
                    waterRecap
                } else if serviceStop.typeId == "2" {
                    startUpRecap
                } else {
                    waterRecap
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    // MARK: - Bottom Actions

    extension ServiceStopRecapScreen {

        var statusActionBar: some View {
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.35)

                HStack(spacing: 12) {
                    switch opStatus {
                    case .finished:
                        Button {
                            opStatus = .skipped
                            showSkipReason = true
                        } label: {
                            Label("Skip", systemImage: "forward")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                                    opStatus = .notFinished
                                    do {
                                        print("")
                                        try await VM.updateServicestopOperationStatus(
                                            companyId: company.id,
                                            currentUserId: user.id,
                                            stop: serviceStop,
                                            operationStatus: .notFinished
                                        )

                                        if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                                            try await VM.updateServicestopOperationStatus(
                                                companyId: serviceStop.contractedCompanyId,
                                                currentUserId: user.id,
                                                stop: serviceStop,
                                                operationStatus: .notFinished
                                            )
                                        }

                                        print("Un finished")
                                        print("Successful")
                                        print("")
                                    } catch {
                                        print("Failed To Updated Finish Stops \(serviceStop.id)")
                                        print(error)
                                        print("")
                                    }

                                    navigationManager.goBack()
                                } else {
                                    print("Either Invalid Company or active Route")
                                }
                            }
                        } label: {
                            Label("Finished", systemImage: "checkmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                    case .notFinished:
                        Button {
                            opStatus = .skipped
                            showSkipReason = true
                        } label: {
                            Label("Skip", systemImage: "forward")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                                    opStatus = .finished
                                    do {
                                        print("")
                                        print("Finishing Screen")
                                        print("-----------------")

                                        try await VM.updateServicestopOperationStatus(
                                            companyId: company.id,
                                            currentUserId: user.id,
                                            stop: serviceStop,
                                            operationStatus: .finished
                                        )
                                        navigationManager.goBack()
                                    } catch {
                                        print("Failed To Updated Finish Stops \(serviceStop.id)")
                                        print(error)
                                        finishErrorMessage = error.localizedDescription
                                        print("")
                                    }
                                } else {
                                    print("Either Invalid Company or active Route")
                                }
                            }
                        } label: {
                            Label("Finish", systemImage: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                    case .skipped:
                        Button {
                            Task {
                                if let serviceStop = masterDataManager.selectedServiceStops,
                                   let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                                    do {
                                        opStatus = .notFinished

                                        if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                                            try await VM.updateServicestopOperationStatus(
                                                companyId: serviceStop.contractedCompanyId,
                                                currentUserId: user.id,
                                                stop: serviceStop,
                                                operationStatus: .notFinished
                                            )
                                        }

                                        try await VM.updateServicestopOperationStatus(
                                            companyId: company.id,
                                            currentUserId: user.id,
                                            stop: serviceStop,
                                            operationStatus: .notFinished
                                        )
                                    } catch {
                                        print("Error")
                                    }
                                }
                            }
                        } label: {
                            Label("Unskip", systemImage: "arrow.uturn.left")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
        }    }

    // MARK: - Sections

    extension ServiceStopRecapScreen {

        var finalButtons: some View {
            HStack {
                VStack {
                    Button {
                        showPhotoSelectionOptions.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)

                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.poolGreen)
                        }
                    }
                    .confirmationDialog("Select Type", isPresented: self.$showPhotoSelectionOptions) {
                        Button {
                            self.pickerType = .album
                            self.selectedNewPicker = .album
                        } label: {
                            Text("Album")
                        }

                        Button {
                            self.pickerType = .camera
                            self.selectedNewPicker = .camera
                        } label: {
                            Text("Camera")
                        }
                    }
                    .sheet(item: self.$pickerType, onDismiss: {

                    }) { item in
                        switch item {
                        case .album:
                            NavigationView {
                                VStack {
                                    HStack {
                                        Spacer()

                                        Button {
                                            pickerType = nil
                                        } label: {
                                            Text("Done")
                                        }
                                        .padding(16)
                                    }

                                    ImagePicker(image: self.$selectedImage)
                                }
                            }
                        case .camera:
                            NavigationView {
                                accessCameraView(selectedImage: self.$selectedImage)
                            }
                        }
                    }
                }

                if images.isEmpty {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .frame(width: 100)
                            .scaledToFit()
                    } else {
                        Button {
                            showPhotoSelectionOptions = true
                            print("add New Photo")
                        } label: {
                            Image(systemName: "photo.fill")
                                .resizable()
                                .frame(width: 100)
                                .scaledToFit()
                                .foregroundColor(Color.blue)
                        }
                    }
                } else {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 100)
                            .scaledToFit()
                    }
                }
            }
            .frame(height: 100)
        }

        var waterRecap: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Water Recap", systemImage: "drop")

                HStack(alignment: .top, spacing: 12) {
                    titleRow

                    ScrollView(.horizontal, showsIndicators: false) {
                        readingsDosagesEquipment
                    }
                }
            }
        }

        var titleRow: some View {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Readings")
                        .lineLimit(1, reservesSpace: true)
                        .font(.headline)

                    ForEach(VM.readingTemplates) { template in
                        Text("\(String(template.name.prefix(10)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dosages")
                        .lineLimit(1, reservesSpace: true)
                        .font(.headline)

                    ForEach(VM.dosageTemplates) { template in
                        Text("\(String((template.name ?? "").prefix(10)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(12)
            .frame(width: 110)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var readingsDosagesEquipment: some View {
            HStack(alignment: .top, spacing: 10) {
                ForEach(VM.bodiesOfWater) { BOW in
                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Text("\(BOW.name)")
                                .lineLimit(1, reservesSpace: true)
                                .font(.headline)
                                .frame(width: 90)

                            ChemReadingRecap(
                                dataService: dataService,
                                templates: VM.readingTemplates,
                                BOW: BOW
                            )
                        }

                        Divider()

                        VStack(spacing: 8) {
                            Text("\(BOW.name)")
                                .lineLimit(1, reservesSpace: true)
                                .font(.headline)
                                .frame(width: 90)

                            ChemDosageRecap(
                                dataService: dataService,
                                templates: VM.dosageTemplates,
                                BOW: BOW
                            )
                        }
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }

        var photos: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Photos", systemImage: "camera")

                    Spacer()

                    Text("\(VM.selectedDripDropPhotos.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                DripDropStoredImageRow(images: VM.loadedImages)

                PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var taskRecap: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Tasks", systemImage: "checklist")

                    Spacer()

                    Text("\(tasks.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                if tasks.isEmpty {
                    emptyState(
                        title: "No Tasks",
                        message: "There are no tasks to recap.",
                        systemImage: "checklist.unchecked"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(tasks, id: \.self) { task in
                            HStack(spacing: 12) {
                                Image(systemName: task.status == .finished ? "checkmark.circle.fill" : "circle")
                                    .font(.body)
                                    .foregroundStyle(task.status == .finished ? Color.poolGreen : .secondary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(task.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text(task.status.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var observationRecap: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionHeader("Observations", systemImage: "eye")

                    Spacer()

                    Text("\(stopData.observation.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                if stopData.observation.isEmpty {
                    emptyState(
                        title: "No Observations",
                        message: "There are no observations for this stop.",
                        systemImage: "eye.slash"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(stopData.observation, id: \.self) { observation in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "note.text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)

                                Text(observation)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var startUpRecap: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Start Up Recap", systemImage: "power")

                emptyState(
                    title: "Start Up Recap",
                    message: "Start up recap details will appear here.",
                    systemImage: "sparkles"
                )
            }
        }

        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }

        func emptyState(title: String, message: String, systemImage: String) -> some View {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    struct EquipmentRecapCardView: View {
        let equipment: Equipment
        let equipmentMeasurments: EquipmentMeasurements?

        var body: some View {
            VStack(spacing: 6) {
                if let measurements = equipmentMeasurments {
                    switch equipment.type {
                    case .cleaner:
                        Text("Cleaner")
                            .bold(true)
                    case .pump:
                        Text("Pump")
                            .bold(true)
                        Text("\(measurements.status)")
                    case .filter:
                        Text("Filter")
                            .bold(true)
                        Text("\(measurements.status)")
                        if let PSI = measurements.poundForcePerSquareInch {
                            Text("\(String(PSI))")
                        } else {
                            Text("-")
                        }
                    case .heater:
                        Text("Heater")
                            .bold(true)
                        Text("\(measurements.status)")
                    case .saltCell:
                        Text("Salt Cell")
                            .bold(true)
                        Text("\(measurements.status)")
                    case .light:
                        Text("Light")
                            .bold(true)
                        Text("\(measurements.status)")
                    case .autoChlorinator:
                        Text("Light")
                            .bold(true)
                        Text("\(measurements.status)")
                    case .controlSystem:
                        Text("Light")
                            .bold(true)
                        Text("\(measurements.status)")
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
