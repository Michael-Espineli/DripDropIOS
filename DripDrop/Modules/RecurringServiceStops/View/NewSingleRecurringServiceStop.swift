//
//  NewSingleRecurringServiceStop.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/7/24.
//

import SwiftUI
@MainActor
final class NewSingleRecurringServiceStopViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showAlert: Bool = false
    @Published private(set) var alertMessage: String = ""

    @Published private(set) var RSSList: [RecurringServiceStop] = []
    @Published private(set) var locations: [ServiceLocation] = []
    @Published var companyUsers: [CompanyUser] = []

    @Published var showSnapshot: Bool = false
    @Published var startOn: Date = Date()
    @Published var frequency: LaborContractFrequency = .weekly
    @Published var selectedDay: DaysOfWeek = .monday
    @Published var selectedUser: CompanyUser = CompanyUser(
        id: "2",
        userId: "2",
        userName: "2",
        roleId: "2",
        roleName: "2",
        dateCreated: Date(),
        status: .active,
        workerType: .employee
    )
    @Published var selectedLocation : ServiceLocation = ServiceLocation(
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
        mainContact: Contact(id: "", name: "", phoneNumber: "", email: "", notes: ""),
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
    
    @Published var showCompanyUserSelector: Bool = false
    @Published var showServiceLocationPicker: Bool = false

    func onLoad(companyId:String,customerId:String) {
        Task{
            do {
                self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                if !companyUsers.isEmpty  {
                    self.selectedUser = companyUsers.first!
                }
                self.locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
                if !locations.isEmpty  {
                    self.selectedLocation = locations.first!
                }
            } catch {
                print(error)
            }
        }
    }
    func onChange(companyId:String) {
        Task{
            if selectedUser.id != "" {
                do {
                    self.RSSList = try await dataService.getRecurringServiceStopsByDayAndTech(companyId: companyId, techId: selectedUser.userId, day: selectedDay)
                } catch {
                    print(error)
                }
            }
        }
    }
    func submit(
        companyId:String,
        customerId:String,
        serviceStopTypeFields: ServiceStopTypeFields
    ) {
        Task{
            if selectedUser.id != "" {
                print("")
                print("[NewSingleRecurringServiceStopViewModel][submit] selectedUserId: \(selectedUser.id)")
                if selectedLocation.id != "" {
                    print("")
                    print("[NewSingleRecurringServiceStopViewModel][submit] selectedLocationId: \(selectedLocation.id)")
                    do {
                        var name = ""
                        let customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
                        if customer.displayAsCompany {
                            name = customer.company ?? "Company Name"
                        }else {
                            name = customer.firstName + " " + customer.lastName
                        }
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] 1")
                        let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)
                        
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] New Count \(rssCount)")
                        let rss = RecurringServiceStop(
                            id: "comp_rss_" + UUID().uuidString,
                            internalId: "RSS" + String(rssCount),
                            type: serviceStopTypeFields.type,
                            typeId: serviceStopTypeFields.typeId,
                            typeImage: serviceStopTypeFields.typeImage,
                            customerName: name,
                            customerId: customer.id,
                            address: selectedLocation.address,
                            tech: selectedUser.userName,
                            techId: selectedUser.userId,
                            dateCreated: Date(),
                            startDate: startOn,
                            endDate: nil,
                            noEndDate: true,
                            frequency: frequency,
                            day: selectedDay,
                            description: "",
                            lastCreated: Date(),
                            serviceLocationId: selectedLocation.id,
                            estimatedTime: selectedLocation.estimatedTime ?? 15,
                            otherCompany: false
                        )
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] rss \(rss)")
                        let id = try await dataService.addNewRecurringServiceStop(companyId: companyId, recurringServiceStop: rss)
                        
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] successfully loaded RSS: \(String(describing: id))")
                        
//                        try await dataService.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: rss)
                        //Developer Add RSS Tasks
                        
                        self.selectedUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .employee)
                        self.selectedDay = .monday
                        self.startOn = Date()
                        self.alertMessage = "Successfully Uplaoded"
                        print(alertMessage)
                        self.showAlert.toggle()
                    } catch {
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] Error \(error)")
                        
                        self.alertMessage = "Failed To Uplaoded"
                        print(alertMessage)
                        self.showAlert.toggle()
                    }
                } else {
                    
                    print("")
                    print("[NewSingleRecurringServiceStopViewModel][submit] no selected Location Id")
                }
            } else {
                print("")
                print("[NewSingleRecurringServiceStopViewModel][submit] no selected user Id")
                
            }
        }
    }
}
struct NewSingleRecurringServiceStop: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : NewSingleRecurringServiceStopViewModel
    @State var customerId:String
    @Environment(\.dismiss) var dismiss
    
    let serviceStopTypeUseCase: ServiceStopTypeUseCase
    
    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    init(
        dataService: any ProductionDataServiceProtocol,
        customerId:String = "",
        serviceStopTypeUseCase: ServiceStopTypeUseCase = .recurringRoute
    ) {
        _customerId = State(wrappedValue: customerId)
        _VM = StateObject(wrappedValue: NewSingleRecurringServiceStopViewModel(dataService: dataService))
        self.serviceStopTypeUseCase = serviceStopTypeUseCase
    }
    var body: some View {
        
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    form
                    snapshot
                    Color.clear.frame(height: 12)
                }
                .padding(12)
                .padding(.horizontal, 8)
            }

        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id,customerId: customerId)
            }
        }
        .onChange(of: VM.selectedDay, perform: { datum in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChange(companyId: currentCompany.id)
            }
        })
        .onChange(of: VM.selectedUser, perform: { datum in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChange(companyId: currentCompany.id)
            }
        })
        
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        
        .sheet(isPresented: $VM.showCompanyUserSelector) {
            CompanyUserPicker(
                dataService: dataService,
                companyUser: $VM.selectedUser
            )
        }
        
        .sheet(isPresented: $VM.showServiceLocationPicker) {
            ServiceLocationPicker(
                dataService: dataService,
                customerId: customerId,
                location: $VM.selectedLocation
            )
        }
    }
}

#Preview {
    NewSingleRecurringServiceStop(dataService: MockDataService(),customerId: "")
}
extension NewSingleRecurringServiceStop {
    var form : some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Add New Recurring Service Stop")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            detailsCard
            serviceStopTypeCard
            Button(
                action: {
                    if let currentCompany = masterDataManager.currentCompany {
                        
                        let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                            selectedType: selectedCompanyServiceStopType,
                            useCase: serviceStopTypeUseCase
                        )
                        
                        VM.submit(
                            companyId: currentCompany.id,
                            customerId: customerId,
                            serviceStopTypeFields: typeFields
                        )
                        dismiss()
                    }
                },
                label: {
                    HStack{
                        Spacer()
                        Text("Add")
                        Spacer()
                    }
                    .modifier(AddButtonModifier())
                })
        }
    }
    var snapshot : some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                sectionHeader("Route Snapshot", systemImage: "list.bullet.rectangle")
                Spacer()
                Button(action: {
                    VM.showSnapshot.toggle()
                }, label: {
                    Text(VM.showSnapshot ? "Collapse" : "Expand")
                        .modifier(ListButtonModifier())
                })
            }

            if VM.showSnapshot {
                if VM.RSSList.isEmpty {
                    Text("No recurring stops on this route yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(VM.RSSList){ rss in
                            snapshotRow(rss)
                        }
                    }
                }
            } else {
                Text("\(VM.RSSList.count) stop(s) for \(VM.selectedUser.userName) on \(VM.selectedDay.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

extension NewSingleRecurringServiceStop {
    var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Details", systemImage: "calendar.badge.plus")

            pickerButtonRow(
                title: "Technician",
                value: VM.selectedUser.id == "" ? "Select Technician" : "\(VM.selectedUser.userName) \(VM.selectedUser.roleName)",
                systemImage: "person.crop.circle",
                isSelected: VM.selectedUser.id != ""
            ) {
                VM.showCompanyUserSelector.toggle()
            }
            
            pickerButtonRow(
                title: "Location",
                value: VM.selectedLocation.id == "" ? "Select Location" : "\(VM.selectedLocation.nickName) - \(VM.selectedLocation.address.streetAddress)",
                systemImage: "route",
                isSelected: VM.selectedLocation.id != ""
            ) {
                VM.showServiceLocationPicker.toggle()
            }
            
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                
                Picker("Pick Day", selection: $VM.selectedDay) {
                    ForEach(DaysOfWeek.allCases, id: \.self){ day in
                        Text(day.rawValue).tag(day)
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                
                Picker("Pick Frequency", selection: $VM.frequency) {
                    ForEach(LaborContractFrequency.allCases, id: \.self){ day in
                        Text(day.rawValue).tag(day)
                    }
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                DatePicker(
                    "Start Date",
                    selection: $VM.startOn,
                    in: Date()...,
                    displayedComponents: .date
                )
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var serviceStopTypeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Stop Type", systemImage: "mappin.and.ellipse")

            if let currentCompany = masterDataManager.currentCompany {
                
                    CompanyServiceStopTypePickerView(
                        companyId: currentCompany.id,
                        dataService: VM.dataService,
                        selectedType: $selectedCompanyServiceStopType,
                        useCase: serviceStopTypeUseCase,
                        title: "Service Stop Type",
                        subtitle: "Payroll uses this type to decide which work type rates apply when this stop is finished."
                    )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Missing company", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)

                    Text("Company ID is required to load service stop types. This stop will use the fallback job service stop type if scheduled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
}
extension NewSingleRecurringServiceStop {
    
    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
    
    func pickerButtonRow(
        title: String,
        value: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    func detailDisplayRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func snapshotRow(_ rss: RecurringServiceStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: rss.typeImage.isEmpty ? "mappin.and.ellipse" : rss.typeImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(rss.customerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(rss.address.streetAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(rss.type.isEmpty ? "Recurring Service Stop" : rss.type)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(rss.frequency.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
