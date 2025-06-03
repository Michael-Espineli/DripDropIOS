//
//  AddNewRepairRequest.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
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
struct AddNewRepairRequest: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = CameraDataModel()

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @Binding var isPresented:Bool

    @StateObject var repairRequestVM : RepairRequestViewModel
    @StateObject var customerVM : CustomerViewModel
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    init(dataService:any ProductionDataServiceProtocol,isPresented:Binding<Bool>){
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))

        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _isPresented = isPresented
    }
    
    @State var description:String = ""
    @State var showCustomerSelector:Bool = false
    @State var showLocationSelector:Bool = false
    @State var showBodyOfWaterSelector:Bool = false

    @State var showAddPhoto:Bool = false
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var showAvatarPicker:Bool = false
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    @State var photoUrls:[String] = []
    @State var customer:Customer = Customer(
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
    
    @State var serviceLocations:[ServiceLocation] = []
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
        preText: false
    )
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date()
    )
    
    @State var equipmentList:[Equipment] = []
    @State var equipment:Equipment = Equipment(
        id: "",
        name: "",
        category: .filter,
        make: "",
        model: "",
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

    @State var repairRequestId:String = "1"
    @State var selectedPhotos:[PhotoAsset] = []
    @State var loadImages:Bool = true
    @State var screenLoading:Bool = false
    @State var selectedDripDropPhotos:[DripDropImage] = []

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                HStack{
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }, label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonModifier())
                    })
                }
                .padding(8)
                info
                submitButton
            }
            if screenLoading {
                ProgressView()
            }
        }
        .fontDesign(.monospaced)
        .navigationTitle("Add Repair Request")
        .toolbar{
            ToolbarItem{
                submitButton
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
                await model.camera.start()
                await model.loadSelectedPhotos()
                await model.loadThumbnail()
            
            do {
                if let company = masterDataManager.currentCompany {
                    try await customerVM.filterAndSortSelected(companyId: company.id, filter: .active, sort: .firstNameHigh)
                    
                    repairRequestId =  "RR" + String(try await settingsVM.getRepairRequestCount(companyId: company.id))
                    if let selectedCustomer = masterDataManager.selectedCustomer {
                        customer = selectedCustomer
                    }
                }
            } catch {
                
            }
        }

        .onChange(of: customer, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if cus.id != "" {
                            try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
                            serviceLocations = serviceLocationVM.serviceLocations
                            if serviceLocations.count != 0 {
                                serviceLocation = serviceLocations.first!
                            } else {
                                serviceLocation = ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: "")
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        })

        .onChange(of: serviceLocation, perform: { loc in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if loc.id != "" {
                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: loc)
                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                            
                            if bodyOfWaterList.count != 0 {
                                bodyOfWater = bodyOfWaterList.first!
                            } else {
                                bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled:Date())
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        })
        .onChange(of: bodyOfWater,
                  perform: {
            BOW in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if BOW.id != "" {
                            try await equipmentVM.getAllEquipmentFromBodyOfWater(companyId: company.id, bodyOfWater: BOW)
                            equipmentList = equipmentVM.listOfEquipment
                            
                            if equipmentList.count != 0 {
                                equipment = equipmentList.first!
                            } else {
                                equipment = Equipment(
                                    id: "",
                                    name: "",
                                    category: .filter,
                                    make: "",
                                    model: "",
                                    dateInstalled: Date(),
                                    status: .operational,
                                    needsService: true,
                                    notes: "",
                                    customerName:"",
                                    customerId: "",
                                    serviceLocationId: "",
                                    bodyOfWaterId: "", isActive:true
                                )
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        })
   
    }
}


extension AddNewRepairRequest{
    var info: some View {
        VStack{
            Text("Add New Repair Request")
                .font(.headline)
            customerView
            Rectangle()
                .frame(height: 1)
            PhotoContentView(selectedImages: $selectedDripDropPhotos)
            Rectangle()
                .frame(height: 1)
            VStack{
                Text("Description")
                TextField(
                    "Description",
                    text: $description,
                    axis: .vertical
                )
                .submitLabel(.done)
                .padding(5)
                .background(Color.gray.opacity(0.5))
                .foregroundColor(Color.black)
                .cornerRadius(5)
                .padding(5)
            }
            
            
        }
    }
    var submitButton: some View {
        Button(action: {
            Task{
                screenLoading = true
                do{
                    if let company = masterDataManager.currentCompany {
                        let customerFullName = (customer.firstName ) + " " + (customer.lastName )
                        if let user = masterDataManager.user {
                            let userFullName = (user.firstName ?? "") + " " + (user.lastName ?? "")
                            
                            try await repairRequestVM.uploadRepairRequestWithValidation(
                                companyId: company.id,
                                repairRequestId:repairRequestId,
                                customerId: customer.id,
                                customerName: customerFullName,
                                requesterId: user.id,
                                requesterName: userFullName,
                                date: Date(),
                                status: .unresolved,
                                description: description,
                                jobIds: [],
                                images: selectedDripDropPhotos,
                                serviceLocationId: serviceLocation.id,
                                bodyOfWaterId: bodyOfWater.id,
                                equipmentId: equipment.id
                            )
                            alertMessage = "Successfully"
                            print(alertMessage)
                            showAlert = true
                            isPresented = false
                            
                        }
                    }
                    
                } catch RepairRequestError.invalidCustomer {
                    alertMessage = "Add Request Error Invalid Customer"
                    print(alertMessage)
                    showAlert = true
                    
                } catch RepairRequestError.invalidUser {
                    alertMessage = "Add Request Error Invalid User"
                    
                    print(alertMessage)
                    showAlert = true
                } catch RepairRequestError.invalidStatus {
                    alertMessage = "Add Request Error Invalid Status"
                    
                    print(alertMessage)
                    showAlert = true
                    
                } catch RepairRequestError.noDescription {
                    alertMessage = "Add Request Error No Description"
                    
                    print(alertMessage)
                    showAlert = true
                    
                } catch RepairRequestError.imagesNotLoaded {
                    alertMessage = "Add Request Error images Not Loaded"
                    
                    print(alertMessage)
                    showAlert = true
                    
                } catch {
                    alertMessage = "Add Request Error Other"
                    
                    print(alertMessage)
                    showAlert = true
                    
                }
                screenLoading = false
            }
        },
               label: {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .modifier(SubmitButtonModifier())
                .clipShape(Capsule())
        })
        .padding(.horizontal,16)
    }
    var customerView: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Customer: ")
                    .bold(true)
                Spacer()
                Button(action: {
                    showCustomerSelector.toggle()
                }, label: {
                    Group{
                        if customer.id == "" {
                            Text("Select Customer")
                        } else {
                            Text("\(customer.firstName) \(customer.lastName)")
                        }
                    }
                    .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $showCustomerSelector, content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $customer, location: $serviceLocation)
                })
            }
            HStack{
                Text("Service Location: ")
                    .bold(true)
                Spacer()
                Button(action: {
                    showLocationSelector.toggle()
                }, label: {
                    Group{
                        if customer.id == "" {
                            Text("Select location")
                        } else {
                            Text("\(serviceLocation.nickName) \(serviceLocation.address.streetAddress)")
                        }
                    }
                    .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $showLocationSelector, content: {
                    
                    ServiceLocationPicker(dataService: dataService, customerId:customer.id, location: $serviceLocation)
                })
            }
            HStack{
                Text("Body Of Water:")
                    .bold(true)
                Spacer()
                Button(action: {
                    showBodyOfWaterSelector.toggle()
                }, label: {
                    Group{
                        if bodyOfWater.id == "" {
                            Text("Select Body Of Water")
                        } else {
                            Text("\(bodyOfWater.name)")
                        }
                    }
                    .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $showBodyOfWaterSelector, content: {
                    BodyOfWaterPicker(dataService: dataService, serviceLocationId: serviceLocation.id, bodyOfWater: $bodyOfWater)
                })
            }
            HStack{
                Text("Equipment:")
                    .bold(true)
                Spacer()
                Picker("Equipment", selection: $equipment) {
                    Text(
                        "Pick Equipment"
                    ).tag(
                        Equipment(
                            id: "",
                            name: "",
                            category: .filter,
                            make: "",
                            model: "",
                            dateInstalled: Date(),
                            status: .operational,
                            needsService: true,
                            notes: "",
                            customerName: "",
                            customerId: "",
                            serviceLocationId: "",
                            bodyOfWaterId: "",
                            isActive:true
                        )
                    )
                    ForEach(equipmentList){ equipment in
                        Text(equipment.name).tag(equipment)
                    }
                }
            }

        }
        .padding(5)
        .cornerRadius(5)
    }

}

