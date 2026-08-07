//
//  CustomerServiceHistoryView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/10/23.
//
///There are a whole Bunch of duplicate functions in here if I call one it calls them all, so fix that
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

enum CustomerTimelineEventKind: String, CaseIterable {
    case serviceStop = "Service Stop"
    case chemistry = "Readings & Dosages"
    case equipmentMaintenance = "Maintenance"
    case equipmentRepair = "Repair"
    case waterFill = "Water Fill"
    case waterEmpty = "Water Empty"
    case workOrder = "Work Order"
    case outstandingWork = "Outstanding Work"
    case note = "Note"

    var systemImage: String {
        switch self {
        case .serviceStop: return "checklist"
        case .chemistry: return "testtube.2"
        case .equipmentMaintenance: return "wrench.and.screwdriver"
        case .equipmentRepair: return "cross.case"
        case .waterFill: return "drop.fill"
        case .waterEmpty: return "drop"
        case .workOrder: return "briefcase"
        case .outstandingWork: return "exclamationmark.circle"
        case .note: return "text.bubble"
        }
    }

    var color: Color {
        switch self {
        case .serviceStop: return .blue
        case .chemistry: return .cyan
        case .equipmentMaintenance: return .orange
        case .equipmentRepair: return .red
        case .waterFill: return .indigo
        case .waterEmpty: return .orange
        case .workOrder: return .purple
        case .outstandingWork: return .orange
        case .note: return .green
        }
    }
}

enum CustomerTimelineFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case service = "Service"
    case jobs = "Jobs"
    case notes = "Notes"
    case chemistry = "Chemistry"
    case equipment = "Equipment"
    case water = "Water"

    var id: String { rawValue }

    func contains(_ kind: CustomerTimelineEventKind) -> Bool {
        switch self {
        case .all:
            return true
        case .service:
            return kind == .serviceStop
        case .jobs:
            return kind == .workOrder || kind == .outstandingWork
        case .notes:
            return kind == .note
        case .chemistry:
            return kind == .chemistry
        case .equipment:
            return kind == .equipmentMaintenance || kind == .equipmentRepair
        case .water:
            return kind == .waterFill || kind == .waterEmpty
        }
    }
}

struct CustomerTimelineEvent: Identifiable, Hashable {
    let id: String
    let kind: CustomerTimelineEventKind
    let title: String
    let subtitle: String
    let detail: String
    let date: Date
}

@MainActor
final class CustomerTimelineViewModel: ObservableObject {
    @Published private(set) var events: [CustomerTimelineEvent] = []
    @Published private(set) var isLoading = false

    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    func load(companyId: String, customer: Customer) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let serviceStopEvents = loadServiceStopEvents(companyId: companyId, customer: customer)
            async let stopDataEvents = loadStopDataEvents(companyId: companyId, customerId: customer.id)
            async let equipmentEvents = loadEquipmentEvents(companyId: companyId, customerId: customer.id)
            async let waterEvents = loadWaterEvents(companyId: companyId, customerId: customer.id)
            async let jobEvents = loadJobEvents(companyId: companyId, customerId: customer.id)
            async let customerNoteEvents = loadCustomerNoteEvents(companyId: companyId, customerId: customer.id)
            async let outstandingWorkEvents = loadOutstandingWorkEvents(companyId: companyId, customerId: customer.id)

            let loadedServiceStops = try await serviceStopEvents
            let loadedStopData = try await stopDataEvents
            let loadedEquipment = try await equipmentEvents
            let loadedWater = try await waterEvents
            let loadedJobs = try await jobEvents
            let loadedCustomerNotes = try await customerNoteEvents
            let loadedOutstandingWork = try await outstandingWorkEvents
            let combined = loadedServiceStops + loadedStopData + loadedEquipment + loadedWater + loadedJobs + loadedCustomerNotes + loadedOutstandingWork
            events = combined.sorted { $0.date > $1.date }
        } catch {
            print("[CustomerTimelineViewModel][load] error: \(error)")
            events = []
        }
    }

    private func loadServiceStopEvents(companyId: String, customer: Customer) async throws -> [CustomerTimelineEvent] {
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let stops = try await dataService.getServiceStopsBetweenDatesAndByCustomer(
            companyId: companyId,
            startDate: startDate,
            endDate: endDate,
            customer: customer
        )

        return stops.map { stop in
            CustomerTimelineEvent(
                id: "service-stop-\(stop.id)",
                kind: .serviceStop,
                title: stop.type.isEmpty ? (stop.jobName ?? "Service stop") : stop.type,
                subtitle: [stop.tech, stop.operationStatus.rawValue, stop.billingStatus.rawValue]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • "),
                detail: stop.description,
                date: stop.serviceDate
            )
        }
    }

    private func loadStopDataEvents(companyId: String, customerId: String) async throws -> [CustomerTimelineEvent] {
        let stopData = try await dataService.getStopDataByCustomer(companyId: companyId, customerId: customerId)
        return stopData
            .filter { !$0.readings.isEmpty || !$0.dosages.isEmpty || !$0.observation.isEmpty }
            .map { data in
                let readingPreview = data.readings.prefix(3).compactMap { reading -> String? in
                    guard let name = reading.name, !name.isEmpty else { return nil }
                    return "\(name) \(reading.amount ?? "")\(reading.UOM.map { " \($0)" } ?? "")"
                }.joined(separator: ", ")

                let dosagePreview = data.dosages.prefix(3).compactMap { dosage -> String? in
                    guard let name = dosage.name, !name.isEmpty else { return nil }
                    return "\(name) \(dosage.amount ?? "")\(dosage.UOM.map { " \($0)" } ?? "")"
                }.joined(separator: ", ")

                return CustomerTimelineEvent(
                    id: "stop-data-\(data.id)",
                    kind: .chemistry,
                    title: "Water readings recorded",
                    subtitle: "\(data.readings.count) readings • \(data.dosages.count) dosages",
                    detail: readingPreview.isEmpty ? dosagePreview : readingPreview,
                    date: data.date
                )
            }
    }

    private func loadEquipmentEvents(companyId: String, customerId: String) async throws -> [CustomerTimelineEvent] {
        let equipment = try await dataService.getAllEquipment(companyId: companyId)
        let customerEquipment = equipment.filter { $0.customerId == customerId }

        var events: [CustomerTimelineEvent] = []
        for item in customerEquipment {
            let history = try await dataService.getEquipmentServiceHistory(companyId: companyId, equipmentId: item.id)
            events.append(contentsOf: history.map { record in
                CustomerTimelineEvent(
                    id: "equipment-\(item.id)-\(record.id)",
                    kind: record.type == .repair ? .equipmentRepair : .equipmentMaintenance,
                    title: record.name.isEmpty ? "\(item.name) \(record.type.rawValue)" : record.name,
                    subtitle: [item.name, record.techName, record.performedBy.rawValue]
                        .filter { !$0.isEmpty }
                        .joined(separator: " • "),
                    detail: record.description,
                    date: record.date
                )
            })
        }

        return events
    }

    private func loadWaterEvents(companyId: String, customerId: String) async throws -> [CustomerTimelineEvent] {
        let locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
        var bodiesOfWater: [BodyOfWater] = []

        for location in locations {
            let locationBodies = try await dataService.getAllBodiesOfWaterByServiceLocationIdAndCustomerId(
                serviceLocationId: location.id,
                customerId: customerId,
                companyId: companyId
            )
            bodiesOfWater.append(contentsOf: locationBodies)
        }

        var events: [CustomerTimelineEvent] = []
        for bodyOfWater in bodiesOfWater {
            let history = try await dataService.getBodyOfWaterHistory(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
            events.append(contentsOf: history.map { record in
                CustomerTimelineEvent(
                    id: "water-\(bodyOfWater.id)-\(record.id)",
                    kind: record.type == .fill ? .waterFill : .waterEmpty,
                    title: "\(record.type.rawValue) - \(bodyOfWater.name)",
                    subtitle: [record.techName, record.gallons.map { "\($0) gal" } ?? ""]
                        .filter { !$0.isEmpty }
                        .joined(separator: " • "),
                    detail: record.description,
                    date: record.date
                )
            })
        }

        return events
    }

    private func loadJobEvents(companyId: String, customerId: String) async throws -> [CustomerTimelineEvent] {
        let jobs = try await dataService.getAllJobsByCustomer(companyId: companyId, customerId: customerId)
        var events: [CustomerTimelineEvent] = jobs.map { job in
            CustomerTimelineEvent(
                id: "work-order-\(job.id)",
                kind: .workOrder,
                title: job.type.isEmpty ? "Work order" : job.type,
                subtitle: [job.adminName, job.operationStatus.rawValue, job.billingStatus.rawValue]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • "),
                detail: job.description,
                date: job.dateCreated
            )
        }

        for job in jobs {
            let comments = try await dataService.getWorkOrderComments(companyId: companyId, workOrderId: job.id)
            events.append(contentsOf: comments.map { comment in
                CustomerTimelineEvent(
                    id: "work-order-comment-\(job.id)-\(comment.id)",
                    kind: .note,
                    title: comment.resolved ? "Work order comment resolved" : "Work order comment",
                    subtitle: [comment.userName ?? comment.authorName ?? "", job.type]
                        .filter { !$0.isEmpty }
                        .joined(separator: " • "),
                    detail: comment.comment,
                    date: comment.date ?? job.dateCreated
                )
            })
        }

        return events
    }

    private func loadCustomerNoteEvents(companyId: String, customerId: String) async throws -> [CustomerTimelineEvent] {
        let snapshot = try await Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("customers")
            .document(customerId)
            .collection("notes")
            .getDocuments()

        return snapshot.documents.compactMap { document in
            do {
                let note = try document.data(as: CustomerNote.self)
                return CustomerTimelineEvent(
                    id: "customer-note-\(note.id)",
                    kind: .note,
                    title: note.resolved == true ? "Customer note resolved" : "Customer note",
                    subtitle: [note.displayAuthor, note.bodyOfWaterName ?? ""]
                        .filter { !$0.isEmpty }
                        .joined(separator: " • "),
                    detail: note.displayText,
                    date: note.displayDate
                )
            } catch {
                print("[CustomerTimelineViewModel][loadCustomerNoteEvents] Decode Error: \(error)")
                return nil
            }
        }
    }

    private func loadOutstandingWorkEvents(companyId: String, customerId: String) async throws -> [CustomerTimelineEvent] {
        let snapshot = try await Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("customers")
            .document(customerId)
            .collection("outstandingWork")
            .getDocuments()

        return snapshot.documents.compactMap { document in
            do {
                let record = try document.data(as: CustomerOutstandingWork.self)
                guard record.billingStatus != JobBillingStatus.expired.rawValue else { return nil }
                let subtitle = [
                    record.displayStatus,
                    record.bodyOfWaterName ?? "",
                    record.serviceLocationName ?? ""
                ]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • ")
                let detail = [record.displayDetail, record.reason ?? ""]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")

                return CustomerTimelineEvent(
                    id: "outstanding-work-\(record.id)",
                    kind: .outstandingWork,
                    title: record.displayTitle,
                    subtitle: subtitle,
                    detail: detail,
                    date: record.displayDate
                )
            } catch {
                print("[CustomerTimelineViewModel][loadOutstandingWorkEvents] Decode Error: \(error)")
                return nil
            }
        }
    }
}

struct CustomerTimelineView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var VM: CustomerTimelineViewModel
    @State private var selectedFilter: CustomerTimelineFilter = .all
    let customer: Customer

    private var visibleEvents: [CustomerTimelineEvent] {
        VM.events.filter { selectedFilter.contains($0.kind) }
    }

    init(dataService: any ProductionDataServiceProtocol, customer: Customer) {
        _VM = StateObject(wrappedValue: CustomerTimelineViewModel(dataService: dataService))
        self.customer = customer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())

                Text("Customer Timeline")
                    .font(.headline.weight(.semibold))

                Spacer()

                if VM.isLoading {
                    ProgressView()
                }
            }

            if !VM.isLoading && !VM.events.isEmpty {
                filterPicker
            }

            if VM.isLoading && VM.events.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading customer history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if VM.events.isEmpty {
                ContentUnavailableView(
                    "No Timeline Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Service, jobs, notes, readings, equipment, and water history will appear here.")
                )
                .padding(.vertical, 8)
            } else if visibleEvents.isEmpty {
                ContentUnavailableView(
                    "No \(selectedFilter.rawValue) Events",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try another timeline filter.")
                )
                .padding(.vertical, 8)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(visibleEvents.prefix(25)).indices, id: \.self) { index in
                        timelineRow(
                            event: Array(visibleEvents.prefix(25))[index],
                            isLast: index == min(visibleEvents.count, 25) - 1
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .task(id: customer.id) {
            if let company = masterDataManager.currentCompany {
                await VM.load(companyId: company.id, customer: customer)
            }
        }
    }

    private func timelineRow(event: CustomerTimelineEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.kind.color.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: event.kind.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(event.kind.color)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1)
                        .frame(minHeight: 42)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Text(event.kind.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(event.kind.color)
                        .background(Capsule().fill(event.kind.color.opacity(0.12)))
                }

                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !event.subtitle.isEmpty {
                    Text(event.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !event.detail.isEmpty {
                    Text(event.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.bottom, isLast ? 0 : 14)
        }
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CustomerTimelineFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundStyle(selectedFilter == filter ? Color.white : Color.secondary)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.accentColor : Color.primary.opacity(0.035))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.07), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct CustomerServiceHistoryView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager


    @StateObject var customerVM : CustomerViewModel
    @StateObject var jobVM : JobViewModel
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var stopDataVM : StopDataViewModel
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel

    @State var customer:Customer
    
    init(dataService:any ProductionDataServiceProtocol,customer:Customer) {
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
        
    }
    
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    
    @State var edit:Bool = false
    @State var bodyOfWaterId:String = "1"
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    @State var serviceLocationList:[ServiceLocation] = []
    @State var serviceLocation:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
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
        preText: false,
        isActive: true
    )
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date(),
                                         isActive: true)
    
    @State var viewList:[String] = ["Chem History","Service History","Equipment History"]
    @State var stringView:String = "Chem History"
    var body: some View {
        VStack{
            ScrollView(showsIndicators: false){
                HStack{
                    Button(action: {
                        edit.toggle()
                    }, label: {
                        Text("Edit")
                        
                    })
                    Spacer()
                }
                .padding()
                locationAndBodyOfWaterPicker
                switch stringView{
                case "Chem History":
                    chemHistory
                case "Service History":
                    serviceHistory
                case "Equipment History":
                    equipmentHistory
                default:
                    chemHistory
                }
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany{
                    if let cus = masterDataManager.selectedCustomer {
                        customer = cus
                    } else {
                        masterDataManager.selectedCustomer = customer
                    }
                 
                        try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
                        serviceLocationList = serviceLocationVM.serviceLocations
                        if serviceLocationList.count != 0{
                            serviceLocation = serviceLocationList.first!
                            masterDataManager.selectedServiceLocation = serviceLocationList.first
                        }
                    
          
//                        try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: serviceLocation)
//                        bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
//                        if bodyOfWaterList.count != 0{
//                            bodyOfWater = bodyOfWaterList.first!
//                            masterDataManager.selectedBodyOfWater = bodyOfWaterList.first
//
//                        }
//
//                    try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: bodyOfWater.id)
//                    try await serviceStopVM.getAllServiceStopsByCustomer(companyId: company.id, customerId: customer.id, startDate: startDate, endDate: endDate)

                    try await settingsVM.getDosageTemplates(companyId: company.id)
                    try await settingsVM.getReadingTemplates(companyId: company.id)
                    
                }
            } catch {
                print("Customer History Error On Appear")
            }
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { selectedCustomer in
            Task{
                do {
                    if let company = masterDataManager.currentCompany{
                        if let cus = masterDataManager.selectedCustomer {
                            customer = cus
                        } else {
                            masterDataManager.selectedCustomer = customer
                        }
           
                            try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
                            serviceLocationList = serviceLocationVM.serviceLocations
                            if serviceLocationList.count != 0{
                                serviceLocation = serviceLocationList.first!
                                masterDataManager.selectedServiceLocation = serviceLocationList.first

                            }
//
//
//                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: serviceLocation)
//                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
//                            if bodyOfWaterList.count != 0{
//                                bodyOfWater = bodyOfWaterList.first!
//                                masterDataManager.selectedBodyOfWater = bodyOfWaterList.first
//
//                            }
//
//                        try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: bodyOfWater.id)
//                        try await serviceStopVM.getAllServiceStopsByCustomer(companyId: company.id, customerId: customer.id, startDate: startDate, endDate: endDate)

                    }
                } catch {
                    print("Customer History Error on Change of Customer")
                }
            }
        })
        .onChange(of: serviceLocation, perform: { location in
            Task{
                do {
                    if let company = masterDataManager.currentCompany{
               
                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: location)
                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                            if bodyOfWaterList.count != 0{
                                bodyOfWater = bodyOfWaterList.first!
                                masterDataManager.selectedBodyOfWater = bodyOfWaterList.first
                            }
//
//                        try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: bodyOfWater.id)
//                        try await serviceStopVM.getAllServiceStopsByCustomer(companyId: company.id, customerId: customer.id, startDate: startDate, endDate: endDate)

                    }
                } catch {
                    print("Change Of service Location Error")
                }
            }
        })
        .onChange(of: bodyOfWater, perform: { selectedBodyOfWater in
            Task{
                if let company = masterDataManager.currentCompany{

                do {
    
                                masterDataManager.selectedBodyOfWater = selectedBodyOfWater
                     
                        try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: selectedBodyOfWater.id)
                        

                } catch {
                    print("Change of body of water Error - Get Stop Data Error")
                }
                    do {
                        if let customer = masterDataManager.selectedCustomer {
                            //This should be by body of Water
                            try await serviceStopVM.getServiceStopsBetweenDatesAndByCustomer(companyId: company.id, startDate: startDate, endDate: endDate, customer: customer)
                            
                            //                        try await serviceStopVM.getServiceStopsBetweenDatesAndByType(companyId: company.id, startDate: startDate, endDate: endDate, workOrderType: "All")
                        }
                    } catch {
                        print("Change of body of water Error - Get Service Stop Error")
                    }
                }

            }
        })

    }
}


extension CustomerServiceHistoryView{
    var locationAndBodyOfWaterPicker: some View {
        HStack{
            Picker("Service Location", selection: $serviceLocation) {
                Text("Pick Location")
                ForEach(serviceLocationList) {
                    Text($0.address.streetAddress).tag($0)
                }
            }
            Picker("Body Of Water", selection: $bodyOfWater) {
                Text("Pick Body Of Water")
                ForEach(bodyOfWaterList) {
                    Text($0.name).tag($0)
                }
            }
            Picker("View", selection: $stringView) {
                ForEach(viewList,id:\.self){
                    Text($0).tag($0)
            }
        }
    }

}
    var serviceHistory: some View {
        VStack{
            
            Text("Service History")
            ScrollView(.horizontal){
                ForEach(serviceStopVM.serviceStops) { datum in
                    HStack{
                        Text("\(fullDate(date:datum.serviceDate))")
                        Text("\(datum.tech)")
                        Text("\(datum.type)")
                        switch datum.operationStatus {
                        case .finished:
                            Text("\(datum.operationStatus.rawValue)")
                                .foregroundColor(Color.green)
                        case .notFinished:
                            Text("\(datum.operationStatus.rawValue)")
                                .foregroundColor(Color.red)
                        case .skipped:
                            Text("Skipped)")
                                .foregroundColor(Color.realYellow)
                        }
                        Button(action: {
                            
                        }, label: {
                            Text("See Details")
                        })
                        .foregroundColor(Color.basicFontText)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                        .padding(5)
                        
                    }
                }
            }
        }
    }
    var equipmentHistory: some View {
        VStack{
            
            Text("Equipment History")

        }
    }
    var chemHistory: some View {
        VStack{
            
            Text("Chem History")
            ScrollView(.horizontal){
                titleRow
                ForEach(stopDataVM.readingHistory) { datum in
                    
//                        EditStopDataRowView(stopData: $datum, readingTemplates: settingsVM.readingTemplates, dosageTemplate: settingsVM.dosageTemplates,bodyOfWaterId: bodyOfWaterId)
                        
                        StopDataRowView(stopData: datum, readingTemplates: settingsVM.readingTemplates, dosageTemplate: settingsVM.dosageTemplates)
                    
                }
            }
        }
    }
    var titleRow: some View {
        HStack{
            Text("00-00-0000")
                .foregroundColor(Color.clear)
                .overlay(Text("Date"))
            HStack{
                ForEach(settingsVM.readingTemplates){ template in
                    Text("\(template.name)")
                        .frame(minWidth: 35)
                }
            }
            HStack{
                ForEach(settingsVM.dosageTemplates){ template in
                    Text("\(template.name ?? "")")
                        .frame(minWidth: 35)
                }
            }
            Spacer()
        }
    }
}
