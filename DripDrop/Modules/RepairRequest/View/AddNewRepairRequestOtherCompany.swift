//
//  AddNewRepairRequestOtherCompany.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/2/25.
//

import PhotosUI
import SwiftUI
import Darwin
enum photoPickerType:Identifiable{
    case album, camera
    var id:Int {
        hashValue
    }
}

struct AddNewRepairRequestOtherCompany: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = CameraDataModel()
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    @StateObject var VM : AddRepairRequestViewModel
    
    init(dataService: any ProductionDataServiceProtocol,associatedBusiness: AssociatedBusiness){
        _VM = StateObject(wrappedValue: AddRepairRequestViewModel(dataService: dataService))
        _associatedBusiness = State(initialValue: associatedBusiness)
    }
    @State var associatedBusiness:AssociatedBusiness
    @FocusState var descriptionField:Bool

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                info
                submitButton
            }
            .padding(8)
            if VM.screenLoading {
                ProgressView()
            }
            if descriptionField {
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        Button(action: {
                            descriptionField.toggle()
                        }, label: {
                            Text("Dismiss")
                            .modifier(DismissButtonModifier())
                        })
                    }
                    .padding(8)
                }
            }
        }
        .fontDesign(.monospaced)
        .navigationTitle("Add Repair Request")
        .toolbar{
            if !UIDevice.isIPhone {
                ToolbarItem{
                    submitButton
                }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            print("")
            print("On Load Add Repair Request")
                await model.camera.start()
                await model.loadSelectedPhotos()
                await model.loadThumbnail()
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id, customer: masterDataManager.selectedCustomer)
                }
            } catch {
                print("Error - onLoad - [AddNewRepairRequest]")
            }
        }
        .onChange(of: VM.selectedCustomer, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.onChangeCustomer(companyId: company.id, cus)
                    }
                } catch {
                    print("Error")
                }
            }
        })

        .onChange(of: VM.selectedLocation, perform: { loc in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.onChangeLocation(companyId: company.id, loc)
                    }
                } catch {
                    print("Error")
                }
            }
        })
    }
}


extension AddNewRepairRequestOtherCompany{
    var info: some View {
        VStack{
            customerView
            Rectangle()
                .frame(height: 1)
            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
            Rectangle()
                .frame(height: 1)
            VStack{
                HStack{
                    Text("Description")
                    Spacer()
                }
                TextField(
                    "Description",
                    text: $VM.description,
                    axis: .vertical
                )
                .lineLimit(5, reservesSpace: true)
                .submitLabel(.return)
                .modifier(PlainTextFieldModifier())
                .focused($descriptionField)
            }
        }
    }
    
    var customerView: some View {
        VStack(alignment: .leading){
            HStack{
                if VM.selectedCustomer.id != "" {
                    Text("Customer")
                        .bold(true)
                }
                Spacer()
                Button(action: {
                    VM.showCustomerSelector.toggle()
                }, label: {
                    HStack{
                        if VM.selectedCustomer.id == "" {
                            Text("Select Customer")
                        } else {
                            Text("\(VM.selectedCustomer.firstName) \(VM.selectedCustomer.lastName)")
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $VM.showCustomerSelector, content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $VM.selectedCustomer, location: $VM.selectedLocation)
                })
            }
            HStack{
                if VM.selectedLocation.id != "" {
                    
                    Text("Location")
                        .bold(true)
                }
                Spacer()
                Button(action: {
                    VM.showLocationSelector.toggle()
                }, label: {
                    HStack{
                        if VM.selectedLocation.id == "" {
                            Text("Select location")
                        } else {
                            Text("\(VM.selectedLocation.address.streetAddress)")
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $VM.showLocationSelector, content: {
                    ServiceLocationPicker(dataService: dataService, customerId: VM.selectedCustomer.id, location: $VM.selectedLocation)
                })
            }
            HStack{
                if VM.selectedBodyOfWater.id != "" {
                    Text("Body Of Water")
                        .bold(true)
                }
                Spacer()
                Button(action: {
                    VM.showBodyOfWaterSelector.toggle()
                }, label: {
                    HStack{
                        if VM.selectedBodyOfWater.id == "" {
                            Text("Select Body Of Water")
                        } else {
                            Text("\(VM.selectedBodyOfWater.name)")
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $VM.showBodyOfWaterSelector, content: {
                    BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.selectedLocation.id, bodyOfWater: $VM.selectedBodyOfWater)
                })
            }
        }
    }

    var submitButton: some View {
        Button(action: {
            Task{
                VM.screenLoading = true
                do{
                    if let company = masterDataManager.currentCompany {
                        if let user = masterDataManager.user {
                            let userFullName = (user.firstName) + " " + (user.lastName)
                            
                            try await VM.uploadRepairRequestWithValidation(
                                companyId: company.id,
                                requesterId: user.id,
                                requesterName: userFullName
                            )
                            VM.alertMessage = "Successfully"
                            print(VM.alertMessage)
                            VM.showAlert = true
                        }
                    }
                    
                } catch RepairRequestError.invalidCustomer {
                    VM.alertMessage = "Add Request Error Invalid Customer"
                    print(VM.alertMessage)
                    VM.showAlert = true
                } catch RepairRequestError.invalidUser {
                    VM.alertMessage = "Add Request Error Invalid User"
                    print(VM.alertMessage)
                    VM.showAlert = true
                } catch RepairRequestError.invalidStatus {
                    VM.alertMessage = "Add Request Error Invalid Status"
                    print(VM.alertMessage)
                    VM.showAlert = true
                } catch RepairRequestError.noDescription {
                    VM.alertMessage = "Add Request Error No Description"
                    print(VM.alertMessage)
                    VM.showAlert = true
                } catch RepairRequestError.imagesNotLoaded {
                    VM.alertMessage = "Add Request Error images Not Loaded"
                    
                    print(VM.alertMessage)
                    VM.showAlert = true
                } catch {
                    VM.alertMessage = "Add Request Error Other"
                    print(VM.alertMessage)
                    VM.showAlert = true
                }
                VM.screenLoading = false
            }
        },
        label: {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .modifier(SubmitButtonModifier())
        })
        .opacity(descriptionField ? 0.7 : 1)
        .padding(.horizontal,16)
        .disabled(descriptionField)
    }
}

