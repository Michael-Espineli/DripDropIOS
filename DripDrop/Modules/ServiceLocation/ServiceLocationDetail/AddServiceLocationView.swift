//
//  AddServiceLocationView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct AddServiceLocationView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var masterDataManager : MasterDataManager
    @State var customer:Customer
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    let onSave: (String) -> Void
    
    init(dataService:any ProductionDataServiceProtocol,customer:Customer,onSave: @escaping (String) -> Void = { _ in }){
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService ))
        _customer = State(wrappedValue: customer)
        self.onSave = onSave
    }
    //Service Location
    let serviceLocationId: String = UUID().uuidString
    @State var serviceLocationAddressStreetAddress:String = ""
    @State var serviceLocationAddressCity:String = ""
    @State var serviceLocationAddressState:String = ""
    @State var serviceLocationAddressZip:String = ""
    
    @State var serviceLocationMainContactName:String = ""
    @State var serviceLocationMainContactPhoneNumber:String = ""
    @State var serviceLocationMainContactEmail:String = ""
    @State var serviceLocationMainContactNotes:String = ""
    @State private var customerContacts: [Contact] = []
    @State private var selectedContactId: String = ""
    @State private var createNewContact: Bool = false
    
    
    @State var estimatedTime:String = "15"
    @State var dogNames:[String] = []
    @State var dogName:String = ""
    
    @State var gateCode:String = ""
    
    @State var nickName:String = ""
    @State var generalNotes:String = ""
    @State var trees:[String] = []
    @State var tree:String = ""
    
    @State var bushes:[String] = []
    @State var bush:String = ""
    
    @State var others:[String] = []
    @State var other:String = ""
    //Body Of Water
    @State var bodyOfWaterList:[BodyOfWater] = []
    
    @State var name:String = "Body 1"
    @State var gallons:String = ""
    @State var material:String = ""
    @State var notes:String = ""
    @State var shape:String = ""
    
    @State var length1:String = ""
    @State var depth1:String = ""
    @State var width1:String = ""
    
    @State var length2:String = ""
    @State var depth2:String = ""
    @State var width2:String = ""
    @State var lastFilled:Date = Date()

    //Alerts
    
    @State var preText:Bool = false

    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showOtherSheet:Bool = false
    
    @State var addFirstBodyOfWater:Bool = false
    @State var showCustomMeasurments:Bool = false
    @State private var serviceLocationAddressQuery: String = ""
    @State private var serviceLocationAddress: Address? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView(showsIndicators: false){
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Service Location")
                            .font(.largeTitle)
                            .bold()
                        Text(customerDisplayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                    
                serviceLocation
                bodyOfWater
                submitButton
                }
            }
            .padding()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            await loadCustomerContacts()
            seedDefaultLocationData()
        }
    }
}

extension AddServiceLocationView {
    private var customerDisplayName: String {
        if customer.displayAsCompany, let company = customer.company, !company.isEmpty {
            return company
        }
        return "\(customer.firstName) \(customer.lastName)"
    }
    
    private func loadCustomerContacts() async {
        guard let company = masterDataManager.currentCompany else { return }
        do {
            customerContacts = try await serviceLocationVM.dataService.getAllContactsByCustomer(companyId: company.id, customerId: customer.id)
            if let firstContact = customerContacts.first {
                selectedContactId = firstContact.id
                createNewContact = false
            } else {
                createNewContact = true
            }
        } catch {
            print("Failed to load customer contacts")
            print(error)
            createNewContact = true
        }
    }
    
    private func seedDefaultLocationData() {
        if nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nickName = "Main"
        }
        
        if serviceLocationMainContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            serviceLocationMainContactName = customerDisplayName
            serviceLocationMainContactEmail = customer.email
            serviceLocationMainContactPhoneNumber = customer.phoneNumber ?? ""
        }
        
        if bodyOfWaterList.isEmpty {
            bodyOfWaterList = [
                BodyOfWater(
                    id: UUID().uuidString,
                    name: "Main",
                    gallons: "16000",
                    material: "Plaster",
                    customerId: customer.id,
                    serviceLocationId: serviceLocationId,
                    notes: "",
                    shape: "",
                    length: [],
                    depth: [],
                    width: [],
                    lastFilled: Date(),
                    isActive: true
                )
            ]
        }
    }
    
    private var selectedMainContact: Contact {
        if !createNewContact, let contact = customerContacts.first(where: { $0.id == selectedContactId }) {
            return contact
        }
        
        return Contact(
            id: UUID().uuidString,
            name: serviceLocationMainContactName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: serviceLocationMainContactPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            email: serviceLocationMainContactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: serviceLocationMainContactNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    var serviceLocation: some View {
        VStack(alignment: .leading, spacing: 18){
            VStack(alignment: .leading, spacing: 12){
                HStack{
                    Text("Service Location Info")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Button(action: {
                        nickName = "Main"
                        serviceLocationAddress = customer.billingAddress
                        serviceLocationAddressQuery = "\(customer.billingAddress.streetAddress) \(customer.billingAddress.city), \(customer.billingAddress.state) \(customer.billingAddress.zip)"
                    }, label: {
                        Label("Use Billing", systemImage: "arrow.down.doc")
                            .font(.subheadline.bold())
                    })
                    .buttonStyle(.borderedProminent)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location Nickname")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(
                        "Main",
                        text: $nickName
                    )
                    .textFieldStyle(.roundedBorder)
                }
                AddressAutocompleteView(
                    text: $serviceLocationAddressQuery,
                    selectedAddress: $serviceLocationAddress
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            VStack(alignment: .leading, spacing: 12){
                HStack{
                    Text("Main Contact")
                        .font(.title3)
                        .bold()
                    Spacer()
                }
                Picker("Contact Source", selection: $createNewContact) {
                    Text("Existing").tag(false)
                    Text("New").tag(true)
                }
                .pickerStyle(.segmented)
                .disabled(customerContacts.isEmpty)
                
                if !createNewContact, !customerContacts.isEmpty {
                    Picker("Customer Contact", selection: $selectedContactId) {
                        ForEach(customerContacts) { contact in
                            Text(contact.name.isEmpty ? "Unnamed Contact" : contact.name).tag(contact.id)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    TextField("Name", text: $serviceLocationMainContactName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Phone Number", text: $serviceLocationMainContactPhoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Email", text: $serviceLocationMainContactEmail)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    TextField("Contact Notes", text: $serviceLocationMainContactNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }
                
                TextField("Estimated Time", text: $estimatedTime)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Toggle("Requires Pre-Service Text", isOn: $preText)
                TextField("Gate Code", text: $gateCode)
                    .textFieldStyle(.roundedBorder)
                TextField("Location Notes", text: $generalNotes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
//            yardInfo
            
        }
    }
    var bodyOfWater: some View {
        VStack{
            HStack{
                Button(action: {
                    addFirstBodyOfWater.toggle()
                }, label: {
                
                    Label(bodyOfWaterList.isEmpty ? "Add First Body Of Water": "Add Another", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                })
                .sheet(
                    isPresented: $addFirstBodyOfWater,
                    content: {
                        ZStack{
                            Color.listColor.ignoresSafeArea()
                            VStack{
                                VStack{
                                    HStack{
                                        Text("Name")
                                            .bold(true)
                                        Spacer()
                                        TextField(
                                            "Name",
                                            text: $name
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("gallons")
                                            .bold(true)
                                        TextField(
                                            "gallons",
                                            text: $gallons
                                        )
                                        .keyboardType(.decimalPad)
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                    HStack{
                                        Text("Material")
                                        Spacer()
                                        Picker("Material", selection: $material) {
                                            Text("Plaster").tag("Plaster")
                                            Text("Vinyl").tag("Vinyl")
                                            Text("Pebble").tag("Pebble")
                                        }
                                    }
                                    DatePicker("Last Filled", selection: $lastFilled, in: ...Date(),displayedComponents: .date)
                                    
                                    HStack{
                                        Text("Shape")
                                        Spacer()
                                        Picker("Shape", selection: $shape) {
                                            Text("Square").tag("Square")
                                            Text("Rectangle").tag("Rectangle")
                                            Text("Circle").tag("Circle")
                                            Text("Roman").tag("Roman")
                                        }
                                    }
                                    HStack{
                                        Spacer()
                                        Button(action: {
                                            showCustomMeasurments.toggle()
                                        }, label: {
                                            Text("Measurments")
                                                .padding(8)
                                                .background(Color.poolBlue)
                                                .cornerRadius(8)
                                                .foregroundColor(Color.white)
                                        })
                                    }
                                    if showCustomMeasurments {
                                        VStack{
                                            HStack{
                                                Text("length 1")
                                                    .bold(true)
                                                TextField(
                                                    "length 1",
                                                    text: $length1
                                                )
                                                .padding(3)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(3)
                                            }
                                            HStack{
                                                Text("length 2")
                                                    .bold(true)
                                                TextField(
                                                    "length 2",
                                                    text: $length2
                                                )
                                                .padding(3)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(3)
                                            }
                                            HStack{
                                                Text("depth 1")
                                                    .bold(true)
                                                TextField(
                                                    "depth 1",
                                                    text: $depth1
                                                )
                                                .padding(3)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(3)
                                            }
                                            HStack{
                                                Text("depth 2")
                                                    .bold(true)
                                                TextField(
                                                    "depth 2",
                                                    text: $depth2
                                                )
                                                .padding(3)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(3)
                                            }
                                            HStack{
                                                Text("width 1")
                                                    .bold(true)
                                                TextField(
                                                    "width 1",
                                                    text: $width1
                                                )
                                                .padding(3)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(3)
                                            }
                                            HStack{
                                                Text("width 2")
                                                    .bold(true)
                                                TextField(
                                                    "width 2",
                                                    text: $width2
                                                )
                                                .padding(3)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(3)
                                            }
                                            
                                        }
                                    }
                                    HStack{
                                        Text("notes")
                                            .bold(true)
                                        TextField(
                                            "notes",
                                            text: $notes
                                        )
                                        .padding(3)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(3)
                                    }
                                }
                                VStack{
                                    Button(
                                        action: {
                                            var id = UUID().uuidString
                                                //Add Some Valid Dation
                                            let bodyOfWater = BodyOfWater(
                                                id: id,
                                                name: name,
                                                gallons: gallons,
                                                material: material,
                                                customerId: customer.id,
                                                serviceLocationId: serviceLocationId,
                                                notes: notes,
                                                shape: shape,
                                                length: [length1,length2],
                                                depth: [depth1,depth2],
                                                width: [width1,width2],
                                                lastFilled: lastFilled,
                                                isActive: true
                                            )
                                            bodyOfWaterList.append(bodyOfWater)
                                            id = UUID().uuidString
                                            
                                            name = "Body " + String(bodyOfWaterList.count + 1)
                                            gallons = ""
                                            material = ""
                                            notes = ""
                                            shape = ""
                                            
                                            length1 = ""
                                            length2 = ""
                                            
                                            depth1 = ""
                                            depth2 = ""
                                            
                                            width1 = ""
                                            width2 = ""
                                            
                                            trees = []
                                            tree = ""
                                            
                                            bushes = []
                                            bush = ""
                                            
                                            others = []
                                            other = ""
                                        },
                                        label: {
                                    Text("Add Body Of Water")
                                })
                            }
                        }
                        .padding(16)
                    }
                })
                Button(action: {
                    showBodyOfWaterSheet.toggle()
                }, label: {
                    Text("Body Of Water - \(String(bodyOfWaterList.count))")
                        .padding(8)
                        .background(Color.gray)
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                })
                .disabled(bodyOfWaterList.count == 0)
                
            }
            .sheet(isPresented: $showBodyOfWaterSheet, content: {
                VStack{
                    ForEach(bodyOfWaterList){ BOW in
                        Text(BOW.name)
                    }
                }
            })
            
        }
    }
    var submitButton: some View {
        VStack{
            Button(action: {
                Task{
                    do {
                        guard let company = masterDataManager.currentCompany else {
                            return
                        }
                        guard let newServiceLocationAddress = serviceLocationAddress else {
                            alertMessage = "Invalid Street Address"
                            showAlert = true
                            return
                        }
                        try await serviceLocationVM.addNewCustomerServiceLocationWithValidation(
                            companyId: company.id,
                            customer: customer,
                            serviceLocationId:serviceLocationId,
                            nickName: nickName,
                            address: newServiceLocationAddress,
                            gateCode: gateCode,
                            dogNames: dogNames,
                            estimatedTime: estimatedTime,
                            mainContact: selectedMainContact,
                            notes: generalNotes,
                            trees: trees,
                            bushes: bushes,
                            other: others,
                            bodyOfWaterList:bodyOfWaterList,
                            preText:preText
                        )
                        alertMessage = "Successfully Updated"
                        print(alertMessage)
                        showAlert = true
                        onSave(serviceLocationId)
                        dismiss()
                    } catch ServiceLocationError.invalidCustomerId{
                        alertMessage = "Invalid Customer Selected"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidCustomerName{
                        alertMessage = "Invalid Customer Selected"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidNickName{
                        alertMessage = "Please Add Nick Name"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidStreetAddress{
                        alertMessage = "Invalid Street Address"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidCity{
                        alertMessage = "Invalid City"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidState{
                        alertMessage = "Invalid State"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidZip{
                        alertMessage = "Invalid Zip"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidContactName{
                        alertMessage = "Invalid Contact Name"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidContactPhoneNumber{
                        alertMessage = "Invalid Phone Number"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidContactEmail{
                        alertMessage = "Invalid Contact Email "
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidContactNotes{
                        alertMessage = "Invalid Contact NToes"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidGateCode{
                        alertMessage = "Invalid Gate Code"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidTime{
                        alertMessage = "Invalid Time"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.bodyOfWaterListEmpty {
                        alertMessage = "Empty Body Of Water List"
                        print(alertMessage)
                        showAlert = true
                    } catch {
                        alertMessage = "Invalid Something"
                        print(alertMessage)
                        showAlert = true
                    }
                }
            },
                   label: {
                HStack{
                    Text("Submit")
                }
                .frame(maxWidth: .infinity)
                .modifier(SubmitButtonModifier())

            })
        }
    }
    var yardInfo: some View {
        VStack{
            HStack{
                Text("Yard Info")
                    .font(.headline)
                Spacer()
                
            }

            HStack{
                Text("tree Name")
                    .bold(true)
                TextField(
                    "tree Name",
                    text: $tree
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                Button(action: {
                    trees.append(tree)
                    tree = ""
                }, label: {
                    Text("Add Tree")
                })
                Button(action: {
                    showTreeSheet.toggle()
                }, label: {
                    Text(String(trees.count))
                })
                .padding()
                .sheet(isPresented: $showTreeSheet, content: {
                    VStack{
                        ForEach(trees,id: \.self){ tree in
                            Text(tree)
                        }
                    }
                })
            }
            HStack{
                Text("bush Name")
                    .bold(true)
                TextField(
                    "bush Name",
                    text: $bush
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                Button(action: {
                    bushes.append(bush)
                    bush = ""
                }, label: {
                    Text("Add Bush")
                })
                Button(action: {
                    showBushSheet.toggle()
                }, label: {
                    Text(String(trees.count))
                })
                .padding()
                .sheet(isPresented: $showBushSheet, content: {
                    VStack{
                        ForEach(bushes,id: \.self){ tree in
                            Text(tree)
                        }
                    }
                })
            }
            HStack{
                Text("other Name")
                    .bold(true)
                TextField(
                    "other Name",
                    text: $other
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                Button(action: {
                    others.append(other)
                    other = ""
                }, label: {
                    Text("Add Other")
                })
                Button(action: {
                    showOtherSheet.toggle()
                }, label: {
                    Text(String(others.count))
                })
                .padding()
                .sheet(isPresented: $showOtherSheet, content: {
                    VStack{
                        ForEach(others,id: \.self){ tree in
                            Text(tree)
                        }
                    }
                })
            }
        }
    }
}
