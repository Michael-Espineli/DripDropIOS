//
//  EditRepairRequest.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/2/26.
//

import SwiftUI

@MainActor
final class EditRepairRequestViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    // The full model
    @Published var repairRequest: RepairRequest
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var showDeleteConfirmation:Bool = false

    // Editable fields (based on provided schema)
    @Published var date: Date
    @Published var status: RepairRequestStatus
    @Published var description: String
    @Published var locationId: String?
    @Published var bodyOfWaterId: String?
    @Published var equipmentId: String?
    
    //Pickers
    @Published var selectedLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
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
        isActive: true
    )
    @Published var selectedBodyOfWater: BodyOfWater = BodyOfWater(
        id: "" ,
        name: "",
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
    @Published var selectedEquipment: Equipment = Equipment(
        id: "",
        name: "",
        type: .filter,
        typeId: "",
        make: "",
        makeId: "",
        model: "",
        modelId: "",
        dateInstalled: Date(),
        status: .operational,
        needsService: true,
        notes: "",
        customerName: "",
        customerId: "",
        serviceLocationId: "",
        bodyOfWaterId: "",
        isActive: true
    )
    
    @Published var showBodyOfWaterPicker: Bool = false
    @Published var showLocationPicker: Bool = false
    @Published var showEquipmentPicker: Bool = false

    // Non-editable but displayed for context
    let id: String
    let customerId: String
    let customerName: String
    let requesterId: String
    let requesterName: String
    let jobIds: [String]
    let photoUrls: [DripDropStoredImage]



    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    init(dataService: any ProductionDataServiceProtocol, repairRequest: RepairRequest) {
        self.dataService = dataService
        self.repairRequest = repairRequest

        // Non-editable mirrors
        self.id = repairRequest.id
        self.customerId = repairRequest.customerId
        self.customerName = repairRequest.customerName
        self.requesterId = repairRequest.requesterId
        self.requesterName = repairRequest.requesterName
        self.jobIds = repairRequest.jobIds
        self.photoUrls = repairRequest.photoUrls

        // Editable mirrors
        self.date = repairRequest.date
        self.status = repairRequest.status
        self.description = repairRequest.description
        self.locationId = repairRequest.locationId
        self.bodyOfWaterId = repairRequest.bodyOfWaterId
        self.equipmentId = repairRequest.equipmentId
    }

    func save(companyId:String?) async {
        if let companyId {
            guard !isSaving else { return }
            isSaving = true
            defer { isSaving = false }
            errorMessage = nil
            
            var updated = repairRequest
            updated.date = date
            updated.status = status
            updated.description = description
            updated.locationId = locationId
            updated.bodyOfWaterId = bodyOfWaterId
            updated.equipmentId = equipmentId
            
            do {
                try await dataService.updateRepairRequest(companyId: companyId, repairRequest: updated)
                self.repairRequest = updated
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    func ondelete(companyId: String?){
        Task{
            if let companyId {
                do {
                    //I dont think I want to delete all of thes things
//                    for job in repairRequest.jobIds {
//                        try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: job)
//                        if let job = jobVM.workOrder {
//                            for stop in job.serviceStopIds {
//                                try await dataService.deleteServiceStopById(companyId: company.id, serviceStopId: stop)
//                            }
//                        }
//                        try await jobVM.deleteJob(companyId: company.id, jobId: job)
//                    }
                    
                    try await dataService.deleteRepairRequest(companyId: companyId, repairRequestId: repairRequest.id)
                } catch {
                    print("[RepairRequestDetailViewModel][ondelete] Error: \(error)")
                }
            }
        }
    }
}

struct EditRepairRequest: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService

    @StateObject var viewModel: EditRepairRequestViewModel

    init(dataService: any ProductionDataServiceProtocol, repairRequest: RepairRequest) {
        _viewModel = StateObject(wrappedValue: EditRepairRequestViewModel(dataService: dataService, repairRequest: repairRequest))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    formCard
                    footerActions
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Edit Repair Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .alert(isPresented: $viewModel.showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(viewModel.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                    viewModel.ondelete(companyId: masterDataManager.currentCompany?.id)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Repair Request")
                .font(.title3.weight(.semibold))
            Text("Customer: \(viewModel.customerName) • Requester: \(viewModel.requesterName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Status
            LabeledContent("Status") {
                Picker("Status", selection: $viewModel.status) {
                    ForEach(RepairRequestStatus.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Date
            LabeledContent("Date") {
                DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.poolGray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }
            // Optional IDs
            Group {
                LabeledContent("Customer") { Text(viewModel.customerName).foregroundStyle(.secondary) }

                LabeledContent("Location ID") {
                    Button(action: {
                        viewModel.showLocationPicker.toggle()
                    }, label: {
                        if viewModel.selectedLocation.id != "" {
                            Text("Select Location")
                        } else {
                            Text(viewModel.selectedLocation.address.streetAddress)
                        }
                    })
                    .sheet(isPresented: $viewModel.showLocationPicker, onDismiss: {
                        
                    }, content: {
                        ServiceLocationPicker(dataService: dataService, customerId: viewModel.repairRequest.customerId, location: $viewModel.selectedLocation)
                    })
                }
                if viewModel.selectedLocation.id != "" {
                    LabeledContent("Body of Water ID") {
                        Button(action: {
                            viewModel.showBodyOfWaterPicker.toggle()
                        }, label: {
                            if viewModel.selectedBodyOfWater.id != "" {
                                Text("Select Body Of Water")
                            } else {
                                Text(viewModel.selectedBodyOfWater.name)
                            }
                        })
                        .sheet(isPresented: $viewModel.showBodyOfWaterPicker, onDismiss: {
                            
                        }, content: {
                            BodyOfWaterPicker(dataService: dataService, serviceLocationId: viewModel.selectedLocation.id, bodyOfWater: $viewModel.selectedBodyOfWater)
                        })
                    }
                }
//                LabeledContent("Equipment ID") {
//                    Button(action: {
//                        showEquipmentPicker.toggle()
//                    }, label: {
//                        Text("Select Body Of Water")
//                    })
//                    .sheet(isPresented: $showEquipmentPicker, onDismiss: {
//                        
//                    }, content: {
//                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: viewModel.selectedLocation.id, bodyOfWater: $viewModel.selectedEquipment)
//                    })
//                }
            }

            // Read-only context
            Group {
                LabeledContent("Requester") { Text(viewModel.requesterName).foregroundStyle(.secondary) }
                if !viewModel.jobIds.isEmpty {
                    LabeledContent("Jobs") {
                        Text(viewModel.jobIds.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var footerActions: some View {
        VStack{
            HStack(spacing: 12) {
                Button(role: .cancel) { dismiss() } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    Task { await viewModel.save(companyId: masterDataManager.currentCompany?.id); if viewModel.errorMessage == nil { dismiss() } }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Save Changes")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(viewModel.isSaving)
            }
            .padding(.top, 4)
            HStack(spacing: 12) {
                
                Button(action: {
                    viewModel.alertMessage = "Confirm Delete"
                    print(viewModel.alertMessage)
                    viewModel.showDeleteConfirmation.toggle()
                }, label: {
                    Text("Delete")
                        .modifier(DeleteButtonModifier())
                })
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await viewModel.save(companyId: masterDataManager.currentCompany?.id); if viewModel.errorMessage == nil { dismiss() } }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text("Save")
                }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .disabled(viewModel.isSaving)
        }
    }
}

// MARK: - Preview
#Preview {
    // Provide your real companyId, dataService, and a sample RepairRequest here when available.
    // EditRepairRequest(companyId: "company-123", dataService: MockDataService(), repairRequest: sample)
    Text("EditRepairRequest Preview")
}
