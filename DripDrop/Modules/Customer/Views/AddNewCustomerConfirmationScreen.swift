//
//  AddNewCustomerConfirmationScreen.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import Contacts
struct AddNewCustomerConfirmationScreen: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    //State Object
    @StateObject private var customerVM : CustomerViewModel

    init(dataService:any  ProductionDataServiceProtocol,contact:CNContact){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _contact = State(wrappedValue: contact)
    }

    //received variables
    @State var contact:CNContact
    @State var testAddress:Address = Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0)
    //Variables for use
    //string
    //Form Variables
    //Customer info
    @State var firstName:String = ""
    @State var lastName:String = ""
    @State var companyName:String = ""
    @State var rate:Double = 0
    @State var email:String = ""

    @State var notes:String = ""
    @State var contactNotes:String = ""
    @State var phoneNumber:String = ""
    //Billing Address

    @State var billingAddressStreetAddress:String = ""
    @State var billingAddressCity:String = ""
    @State var billingAddressState:String = ""
    @State var billingAddressZip:String = ""
    
    //Service Location

    @State var serviceLocationAddressStreetAddress:String = ""
    @State var serviceLocationAddressCity:String = ""
    @State var serviceLocationAddressState:String = ""
    @State var serviceLocationAddressZip:String = ""
    @State var preText:Bool = false

    @State var serviceLocationMainContactName:String = ""
    @State var serviceLocationMainContactPhoneNumber:String = ""
    @State var serviceLocationMainContactEmail:String = ""
    @State var serviceLocationMainContactNotes:String = ""
    
    @State var serviceLocationMainContactGateCode:String = ""
    @State var serviceLocationMainContactNickName:String = ""

    @State var estimatedTime:String = "15"
    @State var dogName:String = ""


    
    //bool
    @State var displayAsCompany:Bool = false
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    //Custom
    @State var billingAddress:Address = Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0)
    @State var serviceLocation:ServiceLocation = ServiceLocation(
        id: UUID().uuidString,
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
        dogName: nil,
        estimatedTime: 15,
        mainContact: Contact(
            id: UUID().uuidString,
            name: "",
            phoneNumber: "",
            email: "",
            notes: ""
        ),
        notes: "",
        bodiesOfWaterId: [""],
        rateType: "",
        laborType:"",
        chemicalCost:"",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false
    )
    @State var addFirstServiceLocation:Bool = false


    @FocusState private var focusedField: NewCustomerFormLabels?

    var body: some View {
        ZStack{
            ScrollView{
                Text("Confirm Information")
                    .font(.title)
                    .bold()
                basicInfo
                Rectangle()
                    .frame(height: 1)
                billingAddressView
                Rectangle()
                    .frame(height: 1)
                serviceLocationView
                Rectangle()
                    .frame(height: 1)
                buttonView
            }
            .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
        }
        

//        .navigationTitle("Create Customer")
        .alert(isPresented:$showAlert) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
        .task {
            firstName = contact.givenName
            lastName = contact.familyName
            phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
            email = contact.emailAddresses.first?.value.description ?? ""
            billingAddressStreetAddress = contact.postalAddresses.first?.value.street ?? ""
            billingAddressCity = contact.postalAddresses.first?.value.city ?? ""
            billingAddressState = contact.postalAddresses.first?.value.state ?? ""
            billingAddressZip = contact.postalAddresses.first?.value.postalCode ?? ""
            
            serviceLocationAddressStreetAddress = contact.postalAddresses.first?.value.street ?? ""
            serviceLocationAddressCity = contact.postalAddresses.first?.value.city ?? ""
            serviceLocationAddressState = contact.postalAddresses.first?.value.state ?? ""
            serviceLocationAddressZip = contact.postalAddresses.first?.value.postalCode ?? ""
            serviceLocationMainContactName = firstName + " " + lastName
            serviceLocationMainContactPhoneNumber = phoneNumber
            serviceLocationMainContactEmail = email
            print(contact)
        }
        .onSubmit {
               switch focusedField {
               case .firstName:
                   focusedField = .lastName
               case .lastName:
                   if displayAsCompany {
                       focusedField = .companyName
                   } else {
                       focusedField = .phoneNumber
                   }
               case .companyName:
                   focusedField = .phoneNumber
               case .phoneNumber:
                   focusedField = .email
               case .email:
                   focusedField = .billingAddressStreetAddress
               case .billingAddressStreetAddress:
                   focusedField = .billingAddressCity
               case .billingAddressCity:
                   focusedField = .billingAddressState
               case .billingAddressState:
                   focusedField = .billingAddressZip
               case .billingAddressZip:
                   if addFirstServiceLocation {
                       focusedField = .serviceLocationMainContactNickName
                   }
               case .serviceLocationMainContactNickName:
                   focusedField = .serviceLocationMainContactGateCode
               case .serviceLocationMainContactGateCode:
                   focusedField = .dogName
               case .dogName:
                   focusedField = .estimatedTime
               case .estimatedTime:
                   focusedField = .contactNotes
               case .contactNotes:
                   focusedField = .serviceLocationAddressStreetAddress
                   
               case .serviceLocationAddressStreetAddress:
                   focusedField = .serviceLocationAddressCity
               case .serviceLocationAddressCity:
                   focusedField = .serviceLocationAddressState
               case .serviceLocationAddressState:
                   focusedField = .serviceLocationAddressZip
               case .serviceLocationAddressZip:
                   focusedField = .serviceLocationMainContactName
               case .serviceLocationMainContactName:
                   focusedField = .serviceLocationMainContactPhoneNumber
               case .serviceLocationMainContactPhoneNumber:
                   focusedField = .serviceLocationMainContactEmail
               case .serviceLocationMainContactEmail:
                   focusedField = .serviceLocationMainContactNotes
               default:
                   focusedField = .serviceLocationMainContactNotes
               }
           }
    }
}

extension AddNewCustomerConfirmationScreen {
    var basicInfo: some View {
        VStack{
            HStack{
                Text("First Name")
                    .font(.headline)
                TextField(
                    "First Name",
                    text: $firstName
                )
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .firstName)
                     .submitLabel(.next)
            }
            HStack{
                Text("Last Name")
                    .font(.headline)
                
                TextField(
                    "Last Name",
                    text: $lastName
                )
                .modifier(PlainTextFieldModifier())
                    .focused($focusedField, equals: .lastName)
                         .submitLabel(.next)
            }
            HStack{
                Text("Display as Company")
                Spacer()
                Button(action: {
                    displayAsCompany.toggle()
                }, label: {
                    if displayAsCompany {
                        HStack{
                            Text("Company")
                            Image(systemName: "building.2.fill")
                        }
                        .padding(4)
                        .padding(.horizontal,2)
                        .background(Color.green)
                        .cornerRadius(8)
                        .foregroundColor(Color.white)
                        .padding(8)
                    } else {
                        HStack{
                            Text("Induvidual")
                            Image(systemName: "person.fill")
                        }
                        .padding(4)
                        .padding(.horizontal,2)
                        .background(Color.red)
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                        .padding(8)
                    }
                })
            }
            if displayAsCompany {
                HStack{
                    Text("Company Name")
                        .font(.headline)
                    
                    TextField(
                        "Company Name",
                        text: $companyName
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    .focused($focusedField, equals: .companyName)
                         .submitLabel(.next)
                }
            }
            HStack{
                Text("Phone Number")
                    .font(.headline)
                TextField(
                    "Phone Number",
                    text: $phoneNumber
                )
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .phoneNumber)
                     .submitLabel(.next)
                #if os(iOS)
                .keyboardType(.namePhonePad)
                #endif
            }
            
            HStack{
                Text("Email")
                    .font(.headline)
                TextField(
                    "Email",
                    text: $email
                )
                .modifier(PlainTextFieldModifier())
                .keyboardType(.emailAddress)
                .focused($focusedField, equals: .email)
                     .submitLabel(.next)
            }
        }

    }
    
    var billingAddressView: some View {
        VStack{
                //----------------------------------------
                //Add Back in During Roll out of Phase 2
                //----------------------------------------

//            AddressSearchBar(dataService: dataService, address: $testAddress)
            HStack{
                Text("Billing Address")
                    .font(.title)
                Spacer()
            }
            HStack{
                TextField(
                    "Street Address",
                    text: $billingAddressStreetAddress
                )
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .billingAddressStreetAddress)
                     .submitLabel(.next)
            }
            HStack{
                TextField(
                    "City",
                    text: $billingAddressCity
                )
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .billingAddressCity)
                     .submitLabel(.next)
                TextField(
                    "State",
                    text: $billingAddressState
                )
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .billingAddressState)
                     .submitLabel(.next)
                TextField(
                    "Zip",
                    text: $billingAddressZip
                )
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .billingAddressZip)
                .keyboardType(.decimalPad)
                .submitLabel(addFirstServiceLocation ? .next : .done)
            }
        }
    }
    
    var serviceLocationView: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    addFirstServiceLocation.toggle()
                }, label: {
                    Text(addFirstServiceLocation ?  "Add Location Later" : "Add First Location")
                })
                .modifier(AddButtonModifier())
            }
            if addFirstServiceLocation {
                VStack{
                    Text("Service Location Info")
                    VStack{
                        HStack{
                            Text("Nick Name")
                                .font(.headline)
                            TextField(
                                "Nick Name",
                                text: $serviceLocationMainContactNickName
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationMainContactNickName)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("Gate Code")
                                .font(.headline)
                            TextField(
                                "Gate Code",
                                text: $serviceLocationMainContactGateCode
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationMainContactGateCode)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("Dog Name")
                                .font(.headline)
                            TextField(
                                "Dog Name",
                                text: $dogName
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .dogName)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("Estimated Time")
                                .font(.headline)
                            TextField(
                                "Estimated Time",
                                text: $estimatedTime
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .estimatedTime)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("Notes")
                                .font(.headline)
                            TextField(
                                "Notes",
                                text: $contactNotes
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .contactNotes)
                                 .submitLabel(.next)
                        }
                    }
                    VStack{
                        Text("Service Location")
                            .font(.title)
                        HStack{
                            Spacer()
                            
                            Button(action: {
                                serviceLocationAddressStreetAddress = billingAddressStreetAddress
                                serviceLocationAddressCity = billingAddressCity
                                serviceLocationAddressState = billingAddressState
                                serviceLocationAddressZip = billingAddressZip
                            }, label: {
                                Text("Use Billing Address")
                            })
                            .modifier(AddButtonModifier())
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                        HStack{
                            TextField(
                                "Street Address",
                                text: $serviceLocationAddressStreetAddress
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationAddressStreetAddress)
                                 .submitLabel(.next)
                        }
                        HStack{
                            
                            TextField(
                                "City",
                                text: $serviceLocationAddressCity
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationAddressCity)
                                 .submitLabel(.next)
                            TextField(
                                "State",
                                text: $serviceLocationAddressState
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationAddressState)
                                 .submitLabel(.next)
                            TextField(
                                "Zip",
                                text: $serviceLocationAddressZip
                            )
                            .modifier(PlainTextFieldModifier())
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .serviceLocationAddressZip)
                                 .submitLabel(.next)
                        }
                    }
                    VStack{
                        Text("Service Location Contact")
                            .font(.headline)
                        HStack{
                            Spacer()
                            Button(action: {
                                serviceLocationMainContactName = firstName + " " + lastName
                                serviceLocationMainContactPhoneNumber = phoneNumber
                                serviceLocationMainContactEmail = email
                                
                            }, label: {
                                Text("Use Main Contact")
                                
                            })
                            .modifier(AddButtonModifier())
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                        HStack{
                            Text("Name")
                                .font(.headline)
                            
                            TextField(
                                "Name",
                                text: $serviceLocationMainContactName
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationMainContactName)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("Phone Number")
                                .font(.headline)
                            
                            TextField(
                                "Phone Number",
                                text: $serviceLocationMainContactPhoneNumber
                            )
                            .modifier(PlainTextFieldModifier())
                            .keyboardType(.namePhonePad)
                            .focused($focusedField, equals: .serviceLocationMainContactPhoneNumber)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("Email")
                                .font(.headline)
                            
                            TextField(
                                "Email",
                                text: $serviceLocationMainContactEmail
                            )
                            .modifier(PlainTextFieldModifier())
                            .keyboardType(.emailAddress)
                            .focused($focusedField, equals: .serviceLocationMainContactEmail)
                                 .submitLabel(.next)
                        }
                        HStack{
                            Text("notes")
                                .font(.headline)
                            
                            TextField(
                                "notes",
                                text: $serviceLocationMainContactNotes
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationMainContactNotes)
                                 .submitLabel(.next)
                            
                        }
                    }
                }
            }
        }
    }
    var buttonView: some View {
        Button(action: {
            Task{
                do {
                    let customerId = UUID().uuidString
                    if billingAddressStreetAddress == "" {
                        showAlert = true
                        alertMessage = "Billing Street Address Empty"
                        print(alertMessage)
                        return
                    }
                    if billingAddressCity == "" {
                        showAlert = true
                        alertMessage = "Billing City Empty"
                        print(alertMessage)
                        return
                    }
                    if billingAddressState == "" {
                        showAlert = true
                        alertMessage = "Billing State Empty"
                        print(alertMessage)
                        return
                    }
                    if billingAddressZip == "" {
                        showAlert = true
                        alertMessage = "Billing Zip Empty"
                        print(alertMessage)
                        return
                    }
                    if serviceLocationAddressStreetAddress == "" {
                        showAlert = true
                        alertMessage = "Service Location Street Address Empty"
                        print(alertMessage)
                        return
                    }
                    if serviceLocationAddressCity == "" {
                        showAlert = true
                        alertMessage = "Service Location City Empty"
                        print(alertMessage)
                        return
                    }
                    if serviceLocationAddressState == "" {
                        showAlert = true
                        alertMessage = "Service Location State Empty"
                        print(alertMessage)
                        return
                    }
                    if serviceLocationAddressZip == "" {
                        showAlert = true
                        alertMessage = "Service Location Zip Empty"
                        print(alertMessage)
                        return
                    }
                    guard let time = Int(estimatedTime) else {
                        throw ServiceLocationError.invalidTime
                    }
                    let fullName = firstName + " " + lastName
                    
                    let pushFirstName = firstName
                    let pushLastName = lastName
                    let pushEmail = email
                    let pushAddress = billingAddress
                    let pushPhoneNumber = phoneNumber
                    let pushRate = rate
                    let pushCompany = companyName
                    let pushDisplayAsCompany = displayAsCompany
                    
                    try await customerVM.addNewCustomerWithLocation(
                        customer:Customer(
                            id: customerId,
                            firstName:pushFirstName,
                            lastName:pushLastName,
                            email: pushEmail ,
                            billingAddress: Address(
                                streetAddress: billingAddressStreetAddress,
                                city: billingAddressCity,
                                state: billingAddressState,
                                zip: billingAddressZip,
                                latitude: 0,
                                longitude: 0
                            ),
                            phoneNumber: pushPhoneNumber,
                            active: true,
                            company: pushCompany,
                            displayAsCompany: pushDisplayAsCompany,
                            hireDate:Date(),
                            billingNotes: "",
                            linkedInviteId: UUID().uuidString
                        ),
                        serviceLocation: ServiceLocation(
                            id: UUID().uuidString,
                            nickName: serviceLocationMainContactNickName,
                            address: Address(
                                streetAddress: serviceLocationAddressStreetAddress,
                                city: serviceLocationAddressCity,
                                state: serviceLocationAddressState,
                                zip: serviceLocationAddressZip,
                                latitude: 0,
                                longitude: 0
                            ),
                            gateCode: serviceLocationMainContactGateCode,
                            dogName: [dogName],
                            estimatedTime: time,
                            mainContact: Contact(
                                id: UUID().uuidString,
                                name: serviceLocationMainContactName,
                                phoneNumber: serviceLocationMainContactPhoneNumber,
                                email: serviceLocationMainContactEmail,
                                notes: contactNotes
                            ),
                            notes: notes,
                            bodiesOfWaterId: [""],
                            rateType: "",
                            laborType:"",
                            chemicalCost:"",
                            laborCost: "",
                            rate: String(
                                rate
                            ),
                            customerId: customerId,
                            customerName: fullName,
                            preText: preText
                        ),
                        companyId: masterDataManager.currentCompany!.id
                    )
                    showAlert = true
                    alertMessage = "Success"
                    print(alertMessage)
                    firstName = ""
                    lastName = ""
                    email = ""
                    billingAddress = Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0)
                    phoneNumber = ""
                    rate = 0
                    companyName = ""
                    displayAsCompany = false
                    dismiss()
                    
                    
                } catch {
                    print("Error uploading file: \(error)")
                    showAlert = true
                    alertMessage = "Upload Failed"
                }
            }
        },
       label: {
            Text("Submit")
                .modifier(SubmitButtonModifier())
        })
    }

}


