//
//  AddNewRepairRequest.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI
enum photoPickerType:Identifiable{
    case album, camera
    var id:Int {
        hashValue
    }
}
struct AddNewRepairRequest: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var repairRequestVM : RepairRequestViewModel
    @StateObject var customerVM : CustomerViewModel
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var settingsVM = SettingsViewModel()
    init(dataService:any ProductionDataServiceProtocol){
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))

        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))

    }
    @State var description:String = ""
    @State var showCustomerSelector:Bool = false
    
    @State var showAddPhoto:Bool = false
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
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
        billingNotes: ""
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
        serviceLocationId: ""
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
        bodyOfWaterId: ""
    )

    @State var repairRequestId:String = "1"
    
    var body: some View {
        VStack{
            ScrollView{
                info
                submitButton
            }
        }

        .navigationTitle("Add Repair Request")
        .toolbar{
            ToolbarItem{
                submitButton
            }
        }
        .task {
            do {
                if let company = masterDataManager.selectedCompany {
                    try await customerVM.filterAndSortSelected(companyId: company.id, filter: .active, sort: .firstNameHigh)
                    
                    repairRequestId =  "RR" + String(try await settingsVM.getRepairRequestCount(companyId: company.id))
                }
            } catch {
                
            }
        }
        .onChange(of: selectedImage, perform: { image in
            Task{
                do {
                    if image != nil {
                        if let company = masterDataManager.selectedCompany {
                            
                            try await repairRequestVM.saveRepairRequestImage(companyId: company.id,requestId: repairRequestId, photo: image!)
                            if let url = repairRequestVM.imageUrlString {
                                photoUrls.append(url)
                            }
                        }
                    }
                    
                } catch {
                    print("Error")
                }
            }
        })
        .onChange(of: customer, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.selectedCompany {
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
                    if let company = masterDataManager.selectedCompany {
                        if loc.id != "" {
                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: loc)
                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                            
                            if bodyOfWaterList.count != 0 {
                                bodyOfWater = bodyOfWaterList.first!
                            } else {
                                bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "")
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
                    if let company = masterDataManager.selectedCompany {
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
                                    bodyOfWaterId: ""
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
    var imageSelector: some View {
        HStack{
            
            Text("Add Photo")
            
            Button(action: {
                print("Add Photo Picker Logic")
                showAddPhoto.toggle()
                
            }, label: {
                Image(systemName: "photo.fill.on.rectangle.fill")
            })
            .padding(10)
            .confirmationDialog("Select Type", isPresented: self.$showAddPhoto, actions: {
                Button(action: {
                    self.pickerType = .album
                    self.selectedNewPicker = .album
                }, label: {
                    Text("From Album")
                })
                Button(action: {
                    self.pickerType = .camera
                    self.selectedNewPicker = .camera
                    
                }, label: {
                    Text("Camera")
                })
                
            })
            .sheet(item: self.$pickerType,onDismiss: {
                
            }){ item in
                switch item {
                case .album:
                    NavigationView{
                        ImagePicker(image: self.$selectedImage)
                    }
                case .camera:
                    NavigationView{
                        Text("Add Camera Logic")
                    }
                    
                }
                
            }}

    }
    var photoListView: some View {
        HStack{
            ScrollView(.horizontal, showsIndicators: false){
                ForEach(photoUrls,id:\.self){ photo in
                    if let url = URL(string: photo){
                        AsyncImage(url: url){ image in
                            image
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        } placeholder: {
                            Image(systemName:"photo.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        }
                    } else {
                        Image(systemName:"photo.circle")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.white)
                            .frame(maxWidth:100 ,maxHeight:100)
                            .cornerRadius(100)
                    }
                    
                }
            }
        }
    }
    var info: some View {
        VStack{
            Text(fullDate(date: Date()))
            customerView
            VStack{
                Text("Description")
                TextField(
                    "Description",
                    text: $description,
                    axis: .vertical
                )
                .padding(5)
                .background(Color.gray.opacity(0.5))
                .foregroundColor(Color.black)
                .cornerRadius(5)
                .padding(5)
            }
            
            imageSelector
        }
    }
    var submitButton: some View {
        Button(action: {
            Task{
                do{
                    if let company = masterDataManager.selectedCompany {
                        let customerFullName = (customer.firstName ) + " " + (customer.lastName )
                        if let user = masterDataManager.user {
                            let userFullName = (user.firstName ?? "") + " " + (user.lastName ?? "")
                            
                            try await repairRequestVM.uploadRepairRequestWithValidation(companyId: company.id, repairRequestId:repairRequestId,customerId: customer.id, customerName: customerFullName, requesterId: user.id, requesterName: userFullName, date: Date(), status: .unresolved,description: description,jobIds: [],photoUrls: photoUrls)
                            print("Successfully")
                            dismiss()
                        }
                    }
                
                } catch RepairRequestError.invalidCustomer {
                    print("Add Request Error Invalid Customer")
                } catch RepairRequestError.invalidUser {
                    print("Add Request Error Invalid User")
                } catch RepairRequestError.invalidStatus {
                    print("Add Request Error Invalid Status")
                } catch RepairRequestError.noDescription {
                    print("Add Request Error No Description")
                } catch {
                    print("Add Request Error Other")

                }
            }
        }, label: {
            Text("Submit")
                .foregroundColor(Color.basicFontText)
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                .padding(5)
        })
    }
    var customerView: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Customer")
                    .bold(true)
                Spacer()
                Button(action: {
                    showCustomerSelector.toggle()
                }, label: {
                    if customer.id == "" {
                        Text("Select Customer")
                    } else {
                        Text("\(customer.firstName) \(customer.lastName)")
                    }
                })
                .padding(5)
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $showCustomerSelector, content: {
                    CustomerPickerScreen(dataService: dataService, customer: $customer)
                })
            }
            HStack{
                Text("Service Location")
                    .bold(true)
                Spacer()
                Picker("Location", selection: $serviceLocation) {
                    Text("Pick Location").tag(ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: ""))
                    ForEach(serviceLocations){ template in
                        Text(template.address.streetAddress).tag(template)
                    }
                }
            }
            HStack{
                Text("Body Of Water")
                    .bold(true)
                Spacer()
                Picker("BOW", selection: $bodyOfWater) {
                    Text("Pick Body Of Water").tag(BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: ""))
                    ForEach(bodyOfWaterList){ BOW in
                        Text(BOW.name).tag(BOW)
                    }
                }
                .lineLimit(1)
            }
            HStack{
                Text("Equipment")
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
                            bodyOfWaterId: ""
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

