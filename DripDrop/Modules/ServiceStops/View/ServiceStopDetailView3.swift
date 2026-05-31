//
//  ServiceStopDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//
// For Customer Detail View
import SwiftUI

struct ServiceStopDetailView3: View {
    
    init(
        dataService: any ProductionDataServiceProtocol,
        serviceStopId: String
    ) {
        _VM = StateObject(
            wrappedValue: ServiceStopDetailViewModel(dataService: dataService)
        )
        _serviceStopId = State(wrappedValue: serviceStopId)
    }
    
    // MARK: State

    @StateObject private var VM: ServiceStopDetailViewModel
    
    @EnvironmentObject private var customerProfileVM : CustomerProfileViewModel
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject private var routeVM: MobileDailyRouteDisplayViewModel
    
    @State private var serviceStopId: String
    
    @State private var stopData: StopData = StopData(
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
    
    @State private var title: String = "Service Stop"
    
    private var serviceStop: ServiceStop? {
        customerProfileVM.serviceStops.first { $0.id == serviceStopId }
    }
    
    // MARK: UI
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            if let stop = serviceStop {
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 16) {
                        
                        headerCard(stop)
                        if let location = customerProfileVM.serviceLocation {
                            infoSection(stop,location)
                        }
                        contactSection(stop)
                        taskSection(stop)
                        waterEquipmentSection
                        observationSection
                        photosSection
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(title)
        .task { await load() }
    }
}

// MARK: Load

extension ServiceStopDetailView3 {
    
    private func load() async {
        guard
            let company = masterDataManager.currentCompany,
            let user = masterDataManager.user,
            let serviceStop
        else { return }
        
        title = serviceStop.customerName
        customerProfileVM.onLoadCustomerProfileView(companyId: company.id, serviceStop:serviceStop)

//        do {
//            try await VM.onInitalLoad(
//                companyId: company.id,
//                serviceStop: serviceStop,
//                userId: user.id
//            )
//            
//            if let received = VM.stopData {
//                stopData = received
//            }
//        } catch {
//            print("Load error", error)
//        }
    }
}

// MARK: Sections

extension ServiceStopDetailView3 {
    
    private func headerCard(_ stop: ServiceStop) -> some View {
        HStack(spacing: 14) {
            
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.poolBlue.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: stop.typeImage)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.poolBlue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.customerName)
                    .font(.title3.weight(.semibold))
                Text(fullDateAndDay(date: stop.serviceDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack{
                    Text(stop.type)
                        .font(.subheadline)
                    Text("Tech: \(stop.tech)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private func infoSection(_ stop: ServiceStop,_ location: ServiceLocation) -> some View {
        VStack(spacing: 12) {
            
            // MARK: - Address & Contact
            infoCard(title: "Contact") {
                //Need to get service Location
                infoRow(icon: "mappin.and.ellipse", label: "Address", value: "\(location.address.streetAddress) \(location.address.city), \(location.address.state)")
                
                Divider().opacity(0.4)
                
                infoRow(icon: "person.fill", label: "Name", value: location.mainContact.name)
                infoRow(icon: "phone.fill", label: "Phone", value: location.mainContact.phoneNumber)
                infoRow(icon: "envelope.fill", label: "Email", value: location.mainContact.email)
                infoRow(icon: "note.text", label: "Notes", value: "\(location.mainContact.notes ?? "")")
            }
            
            // MARK: - Technician & Timing
            infoCard(title: "Service Details") {
                infoRow(icon: "note.text", label: "Location Notes", value: "\(location.notes ?? "")")

                infoRow(icon: "person.crop.circle", label: "Tech", value: stop.tech)
                
                Divider().opacity(0.4)
                
                infoRow(icon: "clock", label: "Estimated", value: displayMinAsMinAndHour(min: stop.estimatedDuration))
                
                infoRow(icon: "play.circle", label: "Start", value: shortDateAndTime(date: stop.startTime))
                infoRow(icon: "stop.circle", label: "End", value: shortDateAndTime(date: stop.endTime))
                if let endTime = stop.endTime, let startTime = stop.startTime {
                    infoRow(icon: "timer", label: "Duration", value: displayMinAsMinAndHour(min: minBetween(start: startTime, end: endTime)))
                }
                Divider().opacity(0.4)
                
                infoRow(icon: "text.alignleft", label: "Description", value: stop.description)
            }
        }
        .padding(.horizontal, 12)

    }
    private func infoCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 10) {
            
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content()
        }
        .padding(12)
        .background(Color.darkGray.opacity(0.35))
        .cornerRadius(14)
    }
    private func infoRow(
        icon: String,
        label: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            
            Image(systemName: icon)
                .frame(width: 18)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }

    private func contactSection(_ stop: ServiceStop) -> some View {
        sectionCard(title: "Contact") {
            ServiceLocationContactInfo(
                dataService: dataService,
                locationId: stop.serviceLocationId
            )
        }
    }
    
    private func taskSection(_ stop: ServiceStop) -> some View {
        sectionCard(title: "Tasks") {
            ServiceStopTaskView(
                dataService: dataService,
                taskList: $VM.taskList,
                serviceStopId: stop.id
            )
            .frame(minHeight: 200)
        }
    }
    
    private var waterEquipmentSection: some View {
        sectionCard(title: "Water & Equipment") {
            waterRecap
        }
    }
    
    private var observationSection: some View {
        sectionCard(title: "Observations") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(stopData.observation, id: \.self) { Text($0) }
            }
        }
    }
    
    private var photosSection: some View {
        sectionCard(title: "Photos") {
            DripDropStoredImageRow(images: VM.loadedImages)
        }
    }
}

// MARK: Reusable Styles

extension ServiceStopDetailView3 {
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(.systemBackground).opacity(0.85))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }
    
    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)
            
            content()
        }
        .padding(14)
        .background(cardBackground)
    }
}

// MARK: Water Recap

extension ServiceStopDetailView3 {
    
    private var waterRecap: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VM.bodiesOfWater) { bow in
                    VStack(spacing: 8) {
                        
                        Text(bow.name)
                            .font(.headline)
                        
                        ChemReadingRecap(
                            dataService: dataService,
                            templates: VM.readingTemplates,
                            BOW: bow
                        )
                        
                        ChemDosageRecap(
                            dataService: dataService,
                            templates: VM.dosageTemplates,
                            BOW: bow
                        )
                    }
                    .frame(width: 190)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.listColor)
                    )
                }
            }
        }
    }
}
