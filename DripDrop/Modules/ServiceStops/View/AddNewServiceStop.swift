import SwiftUI

@MainActor
final class AddNewServiceStopViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) { self.dataService = dataService }

    @Published var serviceDate: Date = Date()
    @Published var description: String = ""
    @Published var selectedCompanyServiceStopType: CompanyServiceStopType?
    
    @Published var selectedLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        gateCode: "",
        mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
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
    @Published var selectedCustomer: Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var showPicker: Bool = false

    @Published var customerId: String = ""
    @Published var customerName: String = ""
    @Published var serviceLocationId: String = ""
    @Published var jobId: String = ""

    @Published var selectedUser: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )
    @Published private(set) var companyUserList: [CompanyUser] = []

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoading: Bool = false

    func onLoad(companyId: String) async throws {
        self.companyUserList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        if let first = companyUserList.first { self.selectedUser = first }
    }

    func createServiceStop(companyId: String) async throws {
        if isLoading { return }
        guard !selectedCustomer.id.isEmpty, !selectedLocation.id.isEmpty else { throw FireBasePublish.unableToPublish }
        guard !selectedUser.id.isEmpty else { throw FireBasePublish.unableToPublish }
        isLoading = true
        defer { isLoading = false }

        let serviceStopCount: Int = try await dataService.getServiceOrderCount(companyId: companyId)
        let internalId = "SS" + String(serviceStopCount)
        let serviceStopId = "comp_ss_" + UUID().uuidString
        let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: selectedCompanyServiceStopType,
            useCase: .customerRelationship
        )

        let serviceStop = ServiceStop(
            id: serviceStopId,
            internalId: internalId,
            companyId: companyId,
            companyName: "",
            customerId: selectedCustomer.id,
            customerName: customerName,
            address: selectedLocation.address,
            dateCreated: Date(),
            serviceDate: serviceDate,
            duration: 0,
            estimatedDuration: 0,
            tech: selectedUser.userName,
            techId: selectedUser.userId,
            recurringServiceStopId: "",
            description: description,
            serviceLocationId: selectedLocation.id,
            typeId: typeFields.typeId,
            type: typeFields.type,
            typeImage: typeFields.typeImage,
            category: typeFields.category,
            jobId: jobId,
            operationStatus: .notFinished,
            billingStatus: .notInvoiced,
            includeReadings: true,
            includeDosages: true,
            otherCompany: false,
            laborContractId: "",
            contractedCompanyId: "",
            isInvoiced: false
        )
        try await dataService.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
        alertMessage = "Successfully Created Service Stop"
        showAlert = true
    }
}

struct AddNewServiceStop: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: AddNewServiceStopViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AddNewServiceStopViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false) { form }
                .padding(8)
            if VM.isLoading {
                ProgressView().padding(8)
            }
        }
        .navigationTitle("Add New Service Stop")
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do { try await VM.onLoad(companyId: currentCompany.id) } catch { print(error) }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK") { dismiss() }
        }
    }
}
extension AddNewServiceStop {
    var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                HStack {
                    Text("Employee").bold(true)
                    Picker("Employee", selection: $VM.selectedUser) {
                        Text("Select User").tag(CompanyUser(
                            id: "",
                            userId: "",
                            userName: "",
                            roleId: "",
                            roleName: "",
                            dateCreated: Date(),
                            status: .active,
                            workerType: .notAssigned
                        ))
                        ForEach(VM.companyUserList) { user in
                            Text(user.userName).tag(user)
                        }
                    }
                }
                DatePicker("Service Date", selection: $VM.serviceDate, in: Date()..., displayedComponents: .date)
                    .bold()
                Button(action: {
                    VM.showPicker.toggle()
                }, label: {
                    if VM.selectedCustomer.id == "" {
                        HStack{
                            Spacer()
                            Text("Pick Customer")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    } else {
                        HStack{
                            Spacer()
                            Text("\(VM.selectedCustomer.firstName) \(VM.selectedCustomer.lastName) \(VM.selectedLocation.address.streetAddress)")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                        
                    }
                })
                .sheet(isPresented: $VM.showPicker,
                   onDismiss: {
                    
                },
                   content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $VM.selectedCustomer, location: $VM.selectedLocation)
                })
                HStack {
                    Text("Description").bold(true)
                    TextField("Description", text: $VM.description).modifier(PlainTextFieldModifier())
                }

                if let currentCompany = masterDataManager.currentCompany {
                    CompanyServiceStopTypePickerView(
                        companyId: currentCompany.id,
                        dataService: dataService,
                        selectedType: $VM.selectedCompanyServiceStopType,
                        useCase: .customerRelationship,
                        subtitle: "Choose what kind of one-time stop this is. Payroll can use this to resolve the correct work type."
                    )
                }
            }
            Button(action: {
                Task {
                    if let currentCompany = masterDataManager.currentCompany {
                        do { try await VM.createServiceStop(companyId: currentCompany.id) } catch { VM.alertMessage = error.localizedDescription; VM.showAlert = true }
                    }
                }
            }) {
                HStack { Spacer(); Text("Create Service Stop"); Spacer() }
                    .modifier(SubmitButtonModifier())
            }
            .disabled(VM.isLoading)
            .opacity(VM.isLoading ? 0.7 : 1)
        }
    }
}
