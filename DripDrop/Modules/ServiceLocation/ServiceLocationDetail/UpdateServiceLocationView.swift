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
    
    init(dataService:any ProductionDataServiceProtocol,serviceLocation:ServiceLocation){
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService ))
        _serviceLocation = State(wrappedValue: serviceLocation)
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
    
        //Alerts
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showOtherSheet:Bool = false
    @State var preText:Bool = false
    
        //Keyboard Info
    @FocusState private var focusedField: ServiceLocationLabel?
    @State var showChangeContact:Bool = false
    
    var body: some View {
        VStack{
            ScrollView{
                serviceLocationView
                submitButton
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
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
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
                Toggle(isOn: $preText, label: {
                    Text("Requires Pre Text")
                })
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
                Toggle(isOn: $requiresPreText, label: {
                    Text("Requires Pre Text")
                        .bold(true)
                })
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
            }
            
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
                        guard let latitude = Double(serviceLocationLatitude) else {
                            
                            throw ServiceLocationError.invalidLatitude
                            
                        }
                        guard let longitude = Double(serviceLocationLongitude) else {
                            
                            throw ServiceLocationError.invalidLongitude
                            
                        }
                        guard let time = Int(estimatedTime) else {
                            
                            throw ServiceLocationError.invalidTime
                        }
                        try await serviceLocationVM.updateCustomerServiceLocation(
                            companyId: company.id,
                            customerId: serviceLocation.customerId,
                            serviceLocation: ServiceLocation(
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
                                notes: serviceLocation.notes,
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
                                preText: preText
                            ),
                            originalServiceLocation: serviceLocation
                        )
                        alertMessage = "Successfully Updated"
                        print(alertMessage)
                        showAlert = true
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
                    } catch ServiceLocationError.invalidLatitude {
                        alertMessage = "Latitude is not a Number"
                        print(alertMessage)
                        showAlert = true
                    } catch ServiceLocationError.invalidLongitude {
                        alertMessage = "Latitude is not a Number"
                        print(alertMessage)
                        showAlert = true
                    }catch ServiceLocationError.invalidContactName{
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
                    } catch {
                        alertMessage = "Error"
                        print(alertMessage)
                        showAlert = true
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
