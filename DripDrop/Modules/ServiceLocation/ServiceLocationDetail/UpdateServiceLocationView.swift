    //
    //  EditServiceLocationView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 5/10/24.
    //

import SwiftUI

struct EditServiceLocationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @State var serviceLocation:ServiceLocation
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    let onSave: (ServiceLocation) -> Void
    let onDelete: (String) -> Void
    
    init(
        dataService:any ProductionDataServiceProtocol,
        serviceLocation:ServiceLocation,
        onSave: @escaping (ServiceLocation) -> Void = { _ in },
        onDelete: @escaping (String) -> Void = { _ in }
    ){
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService ))
        _serviceLocation = State(wrappedValue: serviceLocation)
        self.onSave = onSave
        self.onDelete = onDelete
    }
        //Service Location
    @State var serviceLocationId: String = UUID().uuidString
    
    @State var nickName:String = ""
    
    @State var serviceLocationAddressStreetAddress:String = ""
    @State var serviceLocationAddressCity:String = ""
    @State var serviceLocationAddressState:String = ""
    @State var serviceLocationAddressZip:String = ""
    @State var serviceLocationLatitude:String = ""
    @State var serviceLocationLongitude:String = ""
    
    @State var serviceLocationMainContactName:String = ""
    @State var serviceLocationMainContactPhoneNumber:String = ""
    @State var serviceLocationMainContactEmail:String = ""
    @State var serviceLocationMainContactNotes:String = ""
    
    @State var gateCode:String = ""
    
    
    @State var estimatedTime:String = "15"
    @State var dogNames:[String] = []
    @State var dogName:String = ""
    
    
    @State var generalNotes:String = ""
    @State var trees:[String] = []
    @State var tree:String = ""
    
    @State var bushes:[String] = []
    @State var bush:String = ""
    
    @State var others:[String] = []
    @State var other:String = ""
    @State var requiresPreText:Bool = false
    @State var isActive:Bool = true
    @State var cleanupLinkedRecords:Bool = false
    
        //Alerts
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showOtherSheet:Bool = false
    @State var preText:Bool = false
    
        //Keyboard Info
    @FocusState private var focusedField: ServiceLocationLabel?
    @State var showChangeContact:Bool = false
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                buttons
                Divider()
                serviceLocationView
            }
            .padding()
        }
        .onSubmit {
            switch focusedField {
            case .nickName:
                focusedField = .serviceLocationAddressStreetAddress
            case .serviceLocationAddressStreetAddress:
                focusedField = .serviceLocationAddressCity
                
            case .serviceLocationAddressCity:
                focusedField = .serviceLocationAddressState
            case .serviceLocationAddressState:
                focusedField = .serviceLocationAddressZip
            case .serviceLocationAddressZip:
                focusedField = .serviceLocationLatitude
            case .serviceLocationLatitude:
                focusedField = .serviceLocationLongitude
            case .serviceLocationLongitude:
                focusedField = .estimatedTime
            case .estimatedTime:
                focusedField = .gateCode
            case .gateCode:
                print("default")
            default:
                print("default")
            }
        }
        .alert(serviceLocationVM.alertMessage, isPresented: $serviceLocationVM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert(isPresented: $serviceLocationVM.showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(serviceLocationVM.deleteConfirmationMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        do {
                            try await serviceLocationVM.deleteLocationAndWait(
                                companyId: masterDataManager.currentCompany?.id,
                                locationId: serviceLocation.id
                            )
                            onDelete(serviceLocation.id)
                            dismiss()
                        } catch {
                            serviceLocationVM.alertMessage = "Unable to delete service location"
                            serviceLocationVM.showAlert = true
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .task{
            
            serviceLocationAddressStreetAddress = serviceLocation.address.streetAddress
            serviceLocationAddressCity = serviceLocation.address.city
            serviceLocationAddressState = serviceLocation.address.state
            serviceLocationAddressZip = serviceLocation.address.zip
            serviceLocationLatitude = String(serviceLocation.address.latitude)
            serviceLocationLongitude = String(serviceLocation.address.longitude)
            
            serviceLocationMainContactName = serviceLocation.mainContact.name
            serviceLocationMainContactPhoneNumber = serviceLocation.mainContact.phoneNumber
            serviceLocationMainContactEmail = serviceLocation.mainContact.email
            serviceLocationMainContactNotes = serviceLocation.mainContact.notes ?? ""
            
            estimatedTime = String(serviceLocation.estimatedTime ?? 15)
            dogNames = serviceLocation.dogName ?? []
            gateCode = serviceLocation.gateCode
            
            nickName = serviceLocation.nickName
            generalNotes = serviceLocation.notes ?? ""
            requiresPreText = serviceLocation.preText ?? false
            isActive = serviceLocation.isActive
            
        }
        .onChange(of: serviceLocationVM.coordinates, perform: { coor in
            if let coordinates = coor {
                serviceLocationLatitude = String(coordinates.latitude)
                serviceLocationLongitude = String(coordinates.longitude)
                
            }
        })
    }
}

extension EditServiceLocationView {
    var serviceLocationView: some View {
        VStack{
            VStack{
                HStack{
                    Text("Nick Name")
                        .bold(true)
                    TextField(
                        "Nick Name",
                        text: $nickName
                    )
                    .focused($focusedField, equals: .nickName)
                    .submitLabel(.next)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Text("Street Address")
                        .bold(true)
                    TextField(
                        "Street Address...",
                        text: $serviceLocationAddressStreetAddress
                    )
                    .focused($focusedField, equals: .serviceLocationAddressStreetAddress)
                    .submitLabel(.next)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    TextField(
                        "City",
                        text: $serviceLocationAddressCity
                    )
                    .focused($focusedField, equals: .serviceLocationAddressCity)
                    .submitLabel(.next)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                    TextField(
                        "State",
                        text: $serviceLocationAddressState
                    )
                    .focused($focusedField, equals: .serviceLocationAddressState)
                    .submitLabel(.next)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    TextField(
                        "Zip",
                        text: $serviceLocationAddressZip
                    )
                    .focused($focusedField, equals: .serviceLocationAddressZip)
                    .submitLabel(.next)
                    .keyboardType(.decimalPad)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Spacer()
                    Button(action: {
                        Task{
                            await serviceLocationVM.calculateLatitudeLongitude(
                                street: serviceLocationAddressStreetAddress,
                                city: serviceLocationAddressCity,
                                state: serviceLocationAddressState,
                                zip: serviceLocationAddressZip
                            )
                        }
                    },
                   label: {
                        Text("Recalculate")
                    })
                    .modifier(SubmitButtonModifier())
                }
                HStack{
                    Text("Latidude")
                        .bold(true)
                    TextField(
                        "Latitude...",
                        text: $serviceLocationLatitude
                    )
                    .focused($focusedField, equals: .serviceLocationLatitude)
                    .submitLabel(.next)
                    .keyboardType(.decimalPad)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Longitude")
                        .bold(true)
                    TextField(
                        "Longitude...",
                        text: $serviceLocationLongitude
                    )
                    .focused($focusedField, equals: .serviceLocationLongitude)
                    .submitLabel(.next)
                    .keyboardType(.decimalPad)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
            }
            VStack{
                HStack{
                    Text("Contact Info")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showChangeContact.toggle()
                    }, label: {
                        Image(systemName: "gobackward")
                    })
                    .confirmationDialog("Select Type", isPresented: self.$showChangeContact, actions: {
                        
                        Button(action: {
                        }, label: {
                            Text("Add New")
                        })
                        Button(action: {
                        }, label: {
                            Text("Select From List")
                        })
                    })
                }
            }
            VStack{
                HStack{
                    Text("Yard Info")
                        .font(.headline)
                    
                    Spacer()
                    
                }
                HStack{
                    Text("Estimated Time")
                        .bold(true)
                    TextField(
                        "estimated Time",
                        text: $estimatedTime
                    )
                    .focused($focusedField, equals: .estimatedTime)
                    .submitLabel(.next)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Gate Code")
                        .bold(true)
                    TextField(
                        "Gate Code",
                        text: $gateCode
                    )
                    .focused($focusedField, equals: .gateCode)
                    .submitLabel(.next)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location Notes")
                        .bold(true)
                    TextField(
                        "Location Notes",
                        text: $generalNotes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                Toggle(isOn: $requiresPreText, label: {
                    Text("Requires Pre Text")
                        .bold(true)
                })
                Toggle(isOn: $isActive, label: {
                    Text("Active Service Location")
                        .bold(true)
                })
                if !isActive {
                    Toggle(isOn: $cleanupLinkedRecords, label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clean Up Linked Records")
                                .bold(true)
                            Text("Marks bodies of water and equipment inactive, and deletes recurring service stops and service stops.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    })
                }
                Button(action: {
                    serviceLocationVM.deleteConfirmationMessage = "Please confirm you want to delete this service location and all linked bodies of water, equipment, recurring service stops, and service stops."
                    serviceLocationVM.showDeleteConfirmation.toggle()
                }, label: {
                    Text("Delete")
                        .frame(maxWidth: .infinity)
                        .modifier(DeleteButtonModifier())
                })
                /*
                HStack{
                    Text("Tree")
                        .bold(true)
                    TextField(
                        "Tree",
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
                    Text("Bush")
                        .bold(true)
                    TextField(
                        "Bush",
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
                    Text("Other")
                        .bold(true)
                    TextField(
                        "Other",
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
                 */
            }
            
        }
    }
    var buttons: some View {
        HStack{
            Button(action: {
                dismiss()
            }, label: {
                Text("Cancel")
                    .modifier(DeleteButtonModifier())
            })
            Spacer()
            Text("Edit Location")
            Spacer()
            Button(action: {
                Task{
                    do {
                        guard let company = masterDataManager.currentCompany else {
                            return
                        }
                        guard let latitude = Double(serviceLocationLatitude) else {
                            
                            throw ServiceLocationError.invalidLatitude
                            
                        }
                        guard let longitude = Double(serviceLocationLongitude) else {
                            
                            throw ServiceLocationError.invalidLongitude
                            
                        }
                        guard let time = Int(estimatedTime) else {
                            
                            throw ServiceLocationError.invalidTime
                        }
                        let updatedLocation = ServiceLocation(
                            id: serviceLocation.id,
                            nickName: nickName,
                            address: Address(
                                streetAddress: serviceLocationAddressStreetAddress,
                                city: serviceLocationAddressCity,
                                state: serviceLocationAddressState,
                                zip: serviceLocationAddressZip,
                                latitude: latitude,
                                longitude: longitude
                            ),
                            gateCode: gateCode,
                            dogName: dogNames,
                            estimatedTime: time,
                            mainContact: Contact(
                                id: serviceLocation.mainContact.id,
                                name: serviceLocationMainContactName,
                                phoneNumber: serviceLocationMainContactPhoneNumber,
                                email: serviceLocationMainContactEmail,
                                notes: serviceLocationMainContactNotes
                            ),
                            notes: generalNotes,
                            bodiesOfWaterId: serviceLocation.bodiesOfWaterId,
                            rateType: serviceLocation.rateType,
                            laborType: serviceLocation.laborCost,
                            chemicalCost: serviceLocation.chemicalCost,
                            laborCost: serviceLocation.laborCost,
                            rate: serviceLocation.rate,
                            customerId: serviceLocation.customerId,
                            customerName: serviceLocation.customerName,
                            backYardTree: serviceLocation.backYardTree,
                            backYardBushes: serviceLocation.backYardBushes,
                            backYardOther: serviceLocation.backYardOther,
                            preText: requiresPreText,
                            verified: serviceLocation.verified,
                            photoUrls: serviceLocation.photoUrls,
                            isActive: isActive
                        )
                        try await serviceLocationVM.updateCustomerServiceLocation(
                            companyId: company.id,
                            customerId: serviceLocation.customerId,
                            serviceLocation: updatedLocation,
                            originalServiceLocation: serviceLocation,
                            cleanupLinkedRecords: cleanupLinkedRecords
                        )
                        serviceLocationVM.alertMessage = "Successfully Updated"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                        onSave(updatedLocation)
                        dismiss()
                    } catch ServiceLocationError.invalidCustomerId{
                        serviceLocationVM.alertMessage = "Invalid Customer Selected"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidCustomerName{
                        serviceLocationVM.alertMessage = "Invalid Customer Selected"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidNickName{
                        serviceLocationVM.alertMessage = "Please Add Nick Name"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidStreetAddress{
                        serviceLocationVM.alertMessage = "Invalid Street Address"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidCity{
                        serviceLocationVM.alertMessage = "Invalid City"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidState{
                        serviceLocationVM.alertMessage = "Invalid State"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidZip{
                        serviceLocationVM.alertMessage = "Invalid Zip"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidLatitude {
                        serviceLocationVM.alertMessage = "Latitude is not a Number"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidLongitude {
                        serviceLocationVM.alertMessage = "Latitude is not a Number"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    }catch ServiceLocationError.invalidContactName{
                        serviceLocationVM.alertMessage = "Invalid Contact Name"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidContactPhoneNumber{
                        serviceLocationVM.alertMessage = "Invalid Phone Number"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidContactEmail{
                        serviceLocationVM.alertMessage = "Invalid Contact Email "
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidContactNotes{
                        serviceLocationVM.alertMessage = "Invalid Contact Notes"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidGateCode{
                        serviceLocationVM.alertMessage = "Invalid Gate Code"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch ServiceLocationError.invalidTime{
                        serviceLocationVM.alertMessage = "Invalid Time"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    } catch {
                        serviceLocationVM.alertMessage = "Error"
                        print(serviceLocationVM.alertMessage)
                        serviceLocationVM.showAlert = true
                    }
                }
            },
                   label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())
                
            })
        }
    }
}
