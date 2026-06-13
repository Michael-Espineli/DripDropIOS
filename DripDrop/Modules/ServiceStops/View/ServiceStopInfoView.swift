//
//  ServiceStopInfoView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/30/23.
//

import SwiftUI

@MainActor
final class ServiceStopInfoViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var workOrder: Job? = nil
    @Published private(set) var customer: Customer? = nil
    @Published private(set) var otherCompany: Company? = nil

    func onLoad(companyId: String, WorkOrderId: String) async throws {
        self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: WorkOrderId)
    }

    func getCustomer(companyId: String, customerId: String) async throws {
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
    }

    func loadCustomerContext(companyId: String?, serviceStop: ServiceStop) async throws {
        customer = nil
        otherCompany = nil

        if serviceStop.otherCompany {
            guard let otherCompanyId = serviceStop.mainCompanyId else { return }
            otherCompany = try await dataService.getCompany(companyId: otherCompanyId)
            customer = try await dataService.getCustomerById(companyId: otherCompanyId, customerId: serviceStop.customerId)
        } else if let companyId {
            customer = try await dataService.getCustomerById(companyId: companyId, customerId: serviceStop.customerId)
        }
    }
}

struct ServiceStopInfoView: View {
    init(dataService: any ProductionDataServiceProtocol, serviceStopId: String) {
        _viewModel = StateObject(wrappedValue: ServiceStopInfoViewModel(dataService: dataService))
        self.serviceStopId = serviceStopId
    }

    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var routeViewModel: MobileDailyRouteDisplayViewModel

    @StateObject private var viewModel: ServiceStopInfoViewModel

    private let serviceStopId: String

    private var serviceStop: ServiceStop? {
        routeViewModel.serviceStopList.first { $0.id == serviceStopId }
    }

    private var canOpenCustomerPage: Bool {
        masterDataManager.role?.permissionIdList.contains("10") == true
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if let serviceStop {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        headerCard(serviceStop)
                        linksSection(serviceStop)
                        timingSection(serviceStop)
                        workDetailsSection(serviceStop)
                        contactSection(serviceStop)
                        notesSection(serviceStop)
                    }
                    .padding(.horizontal, UIDevice.isIPhone ? 12 : 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ContentUnavailableView(
                    "Service stop unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The selected service stop could not be found in the current route.")
                )
                .padding()
            }
        }
        .textSelection(.enabled)
        .task(id: serviceStop?.id) {
            await loadLinkedRecords()
        }
    }
}

private extension ServiceStopInfoView {
    func loadLinkedRecords() async {
        guard let serviceStop else { return }

        if let company = masterDataManager.currentCompany, !serviceStop.jobId.isEmpty {
            do {
                try await viewModel.onLoad(companyId: company.id, WorkOrderId: serviceStop.jobId)
            } catch {
                print("[ServiceStopInfoView][loadLinkedRecords] Work order error \(error)")
            }
        }

        do {
            try await viewModel.loadCustomerContext(
                companyId: masterDataManager.currentCompany?.id,
                serviceStop: serviceStop
            )
        } catch {
            print("[ServiceStopInfoView][loadLinkedRecords] Customer error \(error)")
        }
    }

    func headerCard(_ stop: ServiceStop) -> some View {
        ServiceStopInfoHero(
            icon: stop.typeImage.isEmpty ? "mappin.and.ellipse" : stop.typeImage,
            title: stop.customerName,
            subtitle: subtitle(for: stop),
            status: stop.operationStatus.rawValue,
            statusColor: operationStatusColor(stop.operationStatus),
            dateText: shortDate(date: stop.serviceDate),
            techText: nonEmpty(stop.tech, fallback: "No tech assigned")
        )
    }

    func linksSection(_ stop: ServiceStop) -> some View {
        ServiceStopInfoSection(title: "Links & Location", systemImage: "link") {
            customerLinkRow(stop)

            if shouldShowRelatedWorkRow(for: stop) {
                ServiceStopInfoDivider()
                relatedWorkRow(stop)
            }

            ServiceStopInfoDivider()
            addressNavigationLink(stop)
        }
    }

    func timingSection(_ stop: ServiceStop) -> some View {
        ServiceStopInfoSection(title: "Timing", systemImage: "clock") {
            ServiceStopInfoLine(
                icon: "calendar",
                title: "Service Date",
                value: fullDateAndDay(date: stop.serviceDate)
            )

            ServiceStopInfoDivider()

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ServiceStopInfoMetricTile(
                    title: "Estimated",
                    value: displayMinAsMinAndHour(min: stop.estimatedDuration),
                    systemImage: "timer"
                )

                ServiceStopInfoMetricTile(
                    title: "Duration",
                    value: displayMinAsMinAndHour(min: stop.duration),
                    systemImage: "hourglass"
                )
            }

            ServiceStopInfoDivider()
            startTimeRow(stop)

            ServiceStopInfoDivider()
            ServiceStopInfoLine(
                icon: "stop.circle",
                title: "End Time",
                value: stop.endTime == nil ? "Not Finished Yet" : shortDateAndTime(date: stop.endTime),
                isMuted: stop.endTime == nil
            )
        }
    }

    func workDetailsSection(_ stop: ServiceStop) -> some View {
        ServiceStopInfoSection(title: "Work Details", systemImage: "doc.text") {
            ServiceStopInfoLine(
                icon: "number",
                title: "Service Stop ID",
                value: stop.internalId
            )

            ServiceStopInfoDivider()

            ServiceStopInfoLine(
                icon: "person.crop.circle",
                title: "Tech",
                value: nonEmpty(stop.tech, fallback: "No tech assigned"),
                isMuted: stop.tech.isEmpty
            )

            ServiceStopInfoDivider()

            ServiceStopInfoLine(
                icon: "tag",
                title: "Type",
                value: nonEmpty(stop.type, fallback: "No service type"),
                isMuted: stop.type.isEmpty
            )
        }
    }

    func contactSection(_ stop: ServiceStop) -> some View {
        ServiceStopInfoSection(title: "Contact", systemImage: "phone") {
            ServiceLocationContactInfo(dataService: dataService, locationId: stop.serviceLocationId)
        }
    }

    func notesSection(_ stop: ServiceStop) -> some View {
        ServiceStopInfoSection(title: "Description", systemImage: "text.alignleft") {
            Text(nonEmpty(stop.description, fallback: "No description provided."))
                .font(.subheadline)
                .foregroundStyle(stop.description.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    func customerLinkRow(_ stop: ServiceStop) -> some View {
        if canOpenCustomerPage, let customer = viewModel.customer {
            NavigationLink(value: Route.customer(customer: customer, dataService: dataService)) {
                ServiceStopActionLabel(
                    icon: "person.crop.circle",
                    title: "Customer",
                    subtitle: customerDisplayName(customer),
                    footnote: viewModel.otherCompany?.name,
                    tint: .poolBlue,
                    accessorySystemImage: "chevron.right"
                )
            }
            .buttonStyle(.plain)
        } else {
            ServiceStopInfoLine(
                icon: "person.crop.circle",
                title: "Customer",
                value: stop.customerName
            )
        }
    }

    @ViewBuilder
    func relatedWorkRow(_ stop: ServiceStop) -> some View {
        if UIDevice.isIPhone {
            if let job = viewModel.workOrder {
                NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                    ServiceStopActionLabel(
                        icon: "briefcase",
                        title: "Job",
                        subtitle: job.internalId,
                        footnote: nonEmpty(job.type, fallback: "Open job"),
                        tint: .poolBlue,
                        accessorySystemImage: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
            } else if !stop.jobId.isEmpty {
                ServiceStopInfoLine(
                    icon: "briefcase",
                    title: "Job ID",
                    value: stop.jobId
                )
            }
        } else {
            Button {
                if masterDataManager.currentCompany != nil {
                    masterDataManager.selectedCategory = .customers
                    masterDataManager.selectedID = stop.customerId
                }
            } label: {
                ServiceStopActionLabel(
                    icon: "sidebar.right",
                    title: "Customer Workspace",
                    subtitle: stop.customerName,
                    footnote: "Open in the detail column",
                    tint: .poolBlue,
                    accessorySystemImage: "chevron.right"
                )
            }
            .buttonStyle(.plain)
        }
    }

    func addressNavigationLink(_ stop: ServiceStop) -> some View {
        Button {
            openMaps(for: stop.address)
        } label: {
            ServiceStopActionLabel(
                icon: "map",
                title: "Address",
                subtitle: nonEmpty(stop.address.streetAddress, fallback: "No street address"),
                footnote: cityStateZip(for: stop.address),
                tint: .poolBlue,
                accessorySystemImage: "arrow.triangle.turn.up.right.diamond"
            )
        }
        .buttonStyle(.plain)
    }

    func startTimeRow(_ stop: ServiceStop) -> some View {
        ServiceStopInfoLine(
            icon: "play.circle",
            title: "Start Time",
            value: stop.startTime == nil ? "Not Started Yet" : shortDateAndTime(date: stop.startTime),
            isMuted: stop.startTime == nil
        ) {
            if stop.startTime != nil && stop.operationStatus != .finished {
                Button {
                    routeViewModel.startServiceStop(
                        companyId: masterDataManager.currentCompany?.id,
                        serviceStopId: stop.id
                    )
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    func shouldShowRelatedWorkRow(for stop: ServiceStop) -> Bool {
        !UIDevice.isIPhone || viewModel.workOrder != nil || !stop.jobId.isEmpty
    }

    func subtitle(for stop: ServiceStop) -> String {
        if let jobName = stop.jobName, !jobName.isEmpty {
            return jobName
        }

        return nonEmpty(stop.type, fallback: "Service Stop")
    }

    func customerDisplayName(_ customer: Customer) -> String {
        nonEmpty("\(customer.firstName) \(customer.lastName)", fallback: "Customer")
    }

    func cityStateZip(for address: Address) -> String {
        nonEmpty(
            "\(address.city) \(address.state) \(address.zip)",
            fallback: "No city, state, or ZIP"
        )
    }

    func openMaps(for address: Address) {
        let addressText = "\(address.streetAddress) \(address.city) \(address.state) \(address.zip)"
        let encodedAddress = addressText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? addressText

        guard let url = URL(string: "maps://?saddr=&daddr=\(encodedAddress)") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func nonEmpty(_ text: String, fallback: String) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? fallback : trimmedText
    }

    func operationStatusColor(_ status: ServiceStopOperationStatus) -> Color {
        switch status {
        case .finished:
            return .poolGreen
        case .skipped:
            return .orange
        case .notFinished:
            return .poolBlue
        }
    }
}

private struct ServiceStopInfoHero: View {
    let icon: String
    let title: String
    let subtitle: String
    let status: String
    let statusColor: Color
    let dateText: String
    let techText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                ServiceStopStatusPill(text: status, color: statusColor)
            }

            HStack(spacing: 8) {
                ServiceStopMetaPill(systemImage: "calendar", text: dateText)
                ServiceStopMetaPill(systemImage: "person.crop.circle", text: techText)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ServiceStopInfoSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            content
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ServiceStopInfoLine<Trailing: View>: View {
    let icon: String
    let title: String
    let value: String
    let isMuted: Bool
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        value: String,
        isMuted: Bool = false,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.isMuted = isMuted
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isMuted ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            trailing
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension ServiceStopInfoLine where Trailing == EmptyView {
    init(
        icon: String,
        title: String,
        value: String,
        isMuted: Bool = false
    ) {
        self.init(icon: icon, title: title, value: value, isMuted: isMuted) {
            EmptyView()
        }
    }
}

private struct ServiceStopActionLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let footnote: String?
    let tint: Color
    let accessorySystemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let footnote, !footnote.isEmpty {
                    Text(footnote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: accessorySystemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

private struct ServiceStopInfoMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.poolBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ServiceStopStatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ServiceStopMetaPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ServiceStopInfoDivider: View {
    var body: some View {
        Divider()
            .opacity(0.45)
    }
}

private struct ServiceStopContactDetails: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ServiceStopInfoLine(
                icon: "person",
                title: "Name",
                value: fieldValue(contact.name, fallback: "No name")
            )

            ServiceStopInfoDivider()

            ServiceStopInfoLine(
                icon: "phone",
                title: "Phone Number",
                value: fieldValue(contact.phoneNumber, fallback: "No phone number"),
                isMuted: contact.phoneNumber.isEmpty
            )

            ServiceStopInfoDivider()

            ServiceStopInfoLine(
                icon: "envelope",
                title: "Email",
                value: fieldValue(contact.email, fallback: "No email"),
                isMuted: contact.email.isEmpty
            )

            ServiceStopInfoDivider()

            ServiceStopInfoLine(
                icon: "note.text",
                title: "Notes",
                value: fieldValue(contact.notes ?? "", fallback: "No notes"),
                isMuted: contact.notes?.isEmpty ?? true
            )
        }
    }

    private func fieldValue(_ value: String, fallback: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? fallback : trimmedValue
    }
}

@MainActor
final class ServiceLocationContactInfoViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    let locationId: String

    init(dataService: any ProductionDataServiceProtocol, locationId: String) {
        self.dataService = dataService
        self.locationId = locationId
    }

    @Published private(set) var serviceLocation: ServiceLocation?

    func onLoad(companyId: String?) async {
        guard let companyId else { return }

        do {
            self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: locationId)
        } catch {
            print("[ServiceLocationContactInfoViewModel][onLoad] Error \(error)")
        }
    }
}

struct ServiceLocationContactInfo: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager

    @StateObject private var viewModel: ServiceLocationContactInfoViewModel

    private let locationId: String

    init(dataService: any ProductionDataServiceProtocol, locationId: String) {
        _viewModel = StateObject(wrappedValue: ServiceLocationContactInfoViewModel(dataService: dataService, locationId: locationId))
        self.locationId = locationId
    }

    var body: some View {
        Group {
            if let location = viewModel.serviceLocation {
                ServiceStopContactDetails(contact: location.mainContact)
            } else {
                HStack(spacing: 10) {
                    ProgressView()

                    Text("Loading contact...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }
        }
        .task(id: locationId) {
            await viewModel.onLoad(companyId: masterDataManager.currentCompany?.id)
        }
    }
}
