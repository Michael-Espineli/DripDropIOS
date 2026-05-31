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

        func onLoad(companyId: String, WorkOrderId: String) async throws {
            self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: WorkOrderId)
        }

        func getCustomer(companyId: String, customerId: String) async throws {
            self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
        }
    }

    struct ServiceStopInfoView: View {
        init(dataService: any ProductionDataServiceProtocol, serviceStopId: String) {
            _VM = StateObject(wrappedValue: ServiceStopInfoViewModel(dataService: dataService))
            _serviceStopId = State(wrappedValue: serviceStopId)
        }

        @EnvironmentObject var navigationManager: NavigationStateManager
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel

        @StateObject var VM: ServiceStopInfoViewModel

        @State var serviceStopId: String
        @State var taskList: [ServiceStopTask] = []
        @State var showSheet: Bool = false

        private var serviceStop: ServiceStop? {
            vm.serviceStopList.first { $0.id == serviceStopId }
        }

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        siteInfo

                        if let serviceStop {
                            contactCard(locationId: serviceStop.serviceLocationId)
                        }

                        stopInfo
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .textSelection(.enabled)
            .task {
                if let company = masterDataManager.currentCompany, let serviceStop {
                    if serviceStop.jobId != "" {
                        do {
                            try await VM.onLoad(companyId: company.id, WorkOrderId: serviceStop.jobId)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
    }

    extension ServiceStopInfoView {

        var headerCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Service Stop Info")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let serviceStop {
                            Text(serviceStop.customerName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Review service stop details.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let serviceStop {
                        Text(serviceStop.operationStatus.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                if let serviceStop {
                    HStack(spacing: 8) {
                        Label(shortDate(date: serviceStop.serviceDate), systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())

                        Label(serviceStop.tech, systemImage: "person.crop.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())

                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var siteInfo: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Site Information", systemImage: "mappin.and.ellipse")

                customerPageLink
                addressNavigationLink
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        func contactCard(locationId: String) -> some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Contact", systemImage: "phone")

                ServiceLocationContactInfo(dataService: dataService, locationId: locationId)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var stopInfo: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Service Stop Information", systemImage: "doc.text")

                if let serviceStop {
                    detailRow(
                        title: "Date",
                        value: fullDateAndDay(date: serviceStop.serviceDate),
                        systemImage: "calendar"
                    )

                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Service Stop Id")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(serviceStop.internalId)
                                .font(.subheadline.weight(.semibold))
                                .textSelection(.enabled)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    jobPageLink

                    detailRow(
                        title: "Tech",
                        value: serviceStop.tech,
                        systemImage: "person.crop.circle"
                    )

                    detailRow(
                        title: "Type",
                        value: serviceStop.type,
                        systemImage: "tag"
                    )

                    detailRow(
                        title: "Estimated Duration",
                        value: displayMinAsMinAndHour(min: serviceStop.estimatedDuration),
                        systemImage: "timer"
                    )

                    startTimeRow(serviceStop: serviceStop)

                    detailRow(
                        title: "End Time",
                        value: serviceStop.endTime == nil ? "Not Finished Yet" : shortDateAndTime(date: serviceStop.endTime!),
                        systemImage: "stop.circle"
                    )

                    detailRow(
                        title: "Duration",
                        value: displayMinAsMinAndHour(min: serviceStop.duration),
                        systemImage: "clock"
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(serviceStop.description.isEmpty ? "No description provided." : serviceStop.description)
                            .font(.subheadline)
                            .foregroundStyle(serviceStop.description.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        func startTimeRow(serviceStop: ServiceStop) -> some View {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "play.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let startTime = serviceStop.startTime {
                        Text(shortDateAndTime(date: startTime))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Not Started Yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if serviceStop.startTime != nil && serviceStop.operationStatus != .finished {
                    Button {
                        vm.startServiceStop(
                            companyId: masterDataManager.currentCompany?.id,
                            serviceStopId: serviceStop.id
                        )
                    } label: {
                        Text("Restart")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var jobPageLink: some View {
            HStack {
                if let serviceStop {
                    if UIDevice.isIPhone {
                        if let job = VM.workOrder {
                            Image(systemName: "briefcase")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Job Id")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                                    Text(job.internalId)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        } else if !serviceStop.jobId.isEmpty {
                            detailRow(
                                title: "Job Id",
                                value: serviceStop.jobId,
                                systemImage: "briefcase"
                            )
                        }
                    } else {
                        Button {
                            Task {
                                if masterDataManager.currentCompany != nil {
                                    masterDataManager.selectedCategory = .customers
                                    masterDataManager.selectedID = serviceStop.customerId
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Customer")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(serviceStop.customerName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var customerPageLink: some View {
            HStack {
                if let serviceStop {
                    if let role = masterDataManager.role {
                        if role.permissionIdList.contains("10") {
                            CustomerPageLink(
                                serviceStop: serviceStop,
                                job: nil
                            )
                        } else {
                            Text(serviceStop.customerName)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer()
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var addressNavigationLink: some View {
            ZStack {
                if let serviceStop {
                    Button {
                        let address = "\(serviceStop.address.streetAddress) \(serviceStop.address.city) \(serviceStop.address.state) \(serviceStop.address.zip)"
                        let urlText = address.replacingOccurrences(of: " ", with: "?")
                        let url = URL(string: "maps://?saddr=&daddr=\(urlText)")

                        if let url, UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .background(.thinMaterial, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(serviceStop.address.streetAddress)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("\(serviceStop.address.city) \(serviceStop.address.state) \(serviceStop.address.zip)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }

        func detailRow(title: String, value: String, systemImage: String) -> some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

        func onLoad(companyId: String?) {
            guard let companyId else { return }

            Task {
                do {
                    self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: locationId)
                } catch {
                    print("[ServiceLocationContactInfoViewModel][onLoad] Error \(error)")
                }
            }
        }
    }

    struct ServiceLocationContactInfo: View {
        @EnvironmentObject var navigationManager: NavigationStateManager
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService: ProductionDataService

        @StateObject var VM: ServiceLocationContactInfoViewModel

        init(dataService: any ProductionDataServiceProtocol, locationId: String) {
            _VM = StateObject(wrappedValue: ServiceLocationContactInfoViewModel(dataService: dataService, locationId: locationId))
            _locationId = State(wrappedValue: locationId)
        }

        @State var locationId: String
        @State var taskList: [ServiceStopTask] = []
        @State var showSheet: Bool = false

        var body: some View {
            ZStack {
                if let location = VM.serviceLocation {
                    ContactInfo(contact: location.mainContact)
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    HStack(spacing: 10) {
                        ProgressView()

                        Text("Loading contact...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .onAppear {
                VM.onLoad(companyId: masterDataManager.currentCompany?.id)
            }
        }
    }
