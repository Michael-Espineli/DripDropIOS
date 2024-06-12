//
//  AddNewCustomerView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 6/24/23.
//


import SwiftUI
enum NewCustomerFormLabels {
    case firstName
    case lastName
    case companyName
    case phoneNumber
    case email
    case billingAddressStreetAddress
    case billingAddressCity
    case billingAddressState
    case billingAddressZip
    case serviceLocationMainContactNickName
    case serviceLocationMainContactGateCode
    case dogName
    case estimatedTime
    case contactNotes
    
    case serviceLocationAddressStreetAddress
    case serviceLocationAddressCity
    case serviceLocationAddressState
    case serviceLocationAddressZip
    case serviceLocationMainContactName
    case serviceLocationMainContactPhoneNumber
    case serviceLocationMainContactEmail
    case serviceLocationMainContactNotes

}
struct AddNewCustomerView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    //State Object
    @StateObject private var customerVM : CustomerViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
    }
    //received variables

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
    @State var addFirstServiceLocation:Bool = false
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
    @FocusState private var focusedField: NewCustomerFormLabels?

    var body: some View {
        ZStack{
            ScrollView(showsIndicators: false){
                VStack{
                    #if os(macOS)
                    HStack{
                        Spacer()
                        Button(action: {
                            dismiss()
                            
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonTextModifier())
                        })
                        .modifier(DismissButtonModifier())
                        
                    }
                    #endif
                    /*
                    Text("Customer Info")
                        .font(.title)
                    Button(action: {
                        firstName = "Michael"
                        lastName = "Espineli"
                        companyName = "murdock"
                        rate = 170
                        email = "michaelespineli2000@gmail.com"

                        notes = "some notes"
                        contactNotes = "some contact notes"
                        phoneNumber = "6194906830"
                        //Billing Address

                        billingAddressStreetAddress = "6160 Broadmoor Dr"
                        billingAddressCity = "La Mesa"
                        billingAddressState = "Ca"
                        billingAddressZip = "91942"
                        
                        //Service Location

                        serviceLocationAddressStreetAddress = "6160 Broadmoor Dr"
                        serviceLocationAddressCity = "La Mesa"
                        serviceLocationAddressState = "Ca"
                        serviceLocationAddressZip = "91942"
                        
                        serviceLocationMainContactName = "Michael Espineli"
                        serviceLocationMainContactPhoneNumber = "6194906830"
                        serviceLocationMainContactEmail = "michaelespineli2000@gmail.com"
                        serviceLocationMainContactNotes = "Main Contact Notes"
                        serviceLocationMainContactGateCode = "69240"
                        serviceLocationMainContactNickName = "Nick Name"
                        estimatedTime = "15"
                        dogName = "Scout"

                    }, label: {
                        Text("Auto Fill")
                    })
                     */
                    HStack{
                        Text("First Name")
                            .font(.headline)
                        TextField(
                            "First Name",
                            text: $firstName
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
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
                        .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            .focused($focusedField, equals: .lastName)
                                 .submitLabel(.next)
                    
                    }
                    Toggle(isOn: $displayAsCompany, label: {
                        Text("Display as Company")
                    })
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
                        TextField(
                            "Phone Number",
                            text: $phoneNumber
                        )
                        .focused($focusedField, equals: .phoneNumber)
                             .submitLabel(.next)
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        #if os(iOS)
                        .keyboardType(.namePhonePad)
                        #endif

                    }
                    HStack{
                        Text("email")
                        TextField(
                            "Email",
                            text: $email
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                             .submitLabel(.next)
                    }
                }
                VStack{
                    Text("Billing Address")
                        .font(.title)
                    
                    HStack{
                        TextField(
                            "Street Address",
                            text: $billingAddressStreetAddress
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .focused($focusedField, equals: .billingAddressStreetAddress)
                             .submitLabel(.next)
                    }
                    HStack{
                      
                        TextField(
                            "City",
                            text: $billingAddressCity
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .focused($focusedField, equals: .billingAddressCity)
                             .submitLabel(.next)
                        TextField(
                            "State",
                            text: $billingAddressState
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .focused($focusedField, equals: .billingAddressState)
                             .submitLabel(.next)
                        TextField(
                            "Zip",
                            text: $billingAddressZip
                        )
                        .keyboardType(.decimalPad)
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .focused($focusedField, equals: .billingAddressZip)
                        .submitLabel(addFirstServiceLocation ? .next : .done)
                    }
                }
                // here
                HStack{
                    Spacer()
                    Button(action: {
                        addFirstServiceLocation.toggle()
                    }, label: {
                        Text(addFirstServiceLocation ?  "Add Location Later" : "Add First Location")
                    })
                    .foregroundColor(Color.black)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                    .padding(5)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .focused($focusedField, equals: .estimatedTime)
                                     .submitLabel(.next)
                            }
                            HStack{
                                Text("notes")
                                    .font(.headline)
                                TextField(
                                    "Notes",
                                    text: $contactNotes
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .foregroundColor(Color.black)
                                .padding(5)
                                .background(Color.accentColor)
                                .cornerRadius(5)
                                .padding(5)
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                            
                            HStack{
                                TextField(
                                    "streetAddress",
                                    text: $serviceLocationAddressStreetAddress
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .focused($focusedField, equals: .serviceLocationAddressStreetAddress)
                                     .submitLabel(.next)
                            }
                            HStack{
                                
                                TextField(
                                    "City",
                                    text: $serviceLocationAddressCity
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .focused($focusedField, equals: .serviceLocationAddressCity)
                                     .submitLabel(.next)
                                TextField(
                                    "State",
                                    text: $serviceLocationAddressState
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .focused($focusedField, equals: .serviceLocationAddressState)
                                     .submitLabel(.next)
                                TextField(
                                    "Zip",
                                    text: $serviceLocationAddressZip
                                )
                                .keyboardType(.decimalPad)
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .focused($focusedField, equals: .serviceLocationAddressZip)
                                     .submitLabel(.next)
                            }
                        }
                        VStack{
                            Text("Service Location Contact")
                                .font(.title)
                            HStack{
                                Spacer()
                                Button(action: {
                                    serviceLocationMainContactName = firstName + " " + lastName
                                    serviceLocationMainContactPhoneNumber = phoneNumber
                                    serviceLocationMainContactEmail = email
                                    
                                }, label: {
                                    Text("Use Main Contact")
                                    
                                })
                                .foregroundColor(Color.black)
                                .padding(5)
                                .background(Color.accentColor)
                                .cornerRadius(5)
                                .padding(5)
                            }
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                            
                            
                            HStack{
                                Text("Name")
                                    .font(.headline)
                                
                                TextField(
                                    "name",
                                    text: $serviceLocationMainContactName
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
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
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .focused($focusedField, equals: .serviceLocationMainContactNotes)
                                     .submitLabel(.next)
                                
                            }
                        }
                        
                    }
                }
                submitButton
                
            }
            .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
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
                       } else {
                           
                               Task{
                                   do {
                                       
                               if let company = masterDataManager.selectedCompany {
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
                                   
                         
                                           if addFirstServiceLocation {
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
                                                    rate: pushRate,
                                                    company: pushCompany,
                                                    displayAsCompany: pushDisplayAsCompany,
                                                    hireDate:Date(),
                                                    billingNotes: ""
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
                                                    customerName: fullName
                                                ),
                                                companyId: company.id
                                               )
                                           } else {
                                               try await customerVM.addNewCustomerWithOutLocation(customer:Customer(id: customerId,
                                                                                                                    firstName:pushFirstName,
                                                                                                                    lastName:pushLastName,
                                                                                                                    email: pushEmail ,
                                                                                                                    billingAddress: Address(streetAddress: billingAddressStreetAddress,
                                                                                                                                            city: billingAddressCity,
                                                                                                                                            state: billingAddressState,
                                                                                                                                            zip: billingAddressZip,
                                                                                                                                            latitude: 0,
                                                                                                                                            longitude: 0),
                                                                                                                    phoneNumber: pushPhoneNumber,
                                                                                                                    active: true,
                                                                                                                    rate: pushRate,
                                                                                                                    company: pushCompany,
                                                                                                                    displayAsCompany: pushDisplayAsCompany,
                                                                                                                    hireDate:Date(),
                                                                                                                    billingNotes: ""),
                                                                                                  companyId: company.id)
                                           }
                                           showAlert = true
                                           alertMessage = "Success"
                                           print(alertMessage)
                                           
                                    
                                       
                                   }
                                   
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
                                       showAlert = true
                                       print(error)
                                       alertMessage = "Failed To Upload"
                                       print(alertMessage)
                                       return
                                   }
                           }
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
                       Task{
                           if let company = masterDataManager.selectedCompany {
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
                               
                           
                                       
                                       if addFirstServiceLocation {
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
                                                rate: pushRate,
                                                company: pushCompany,
                                                displayAsCompany: pushDisplayAsCompany,
                                                hireDate:Date(),
                                                billingNotes: ""
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
                                                customerName: fullName
                                            ),
                                            companyId: company.id
                                           )
                                       } else {
                                           try await customerVM.addNewCustomerWithOutLocation(customer:Customer(id: customerId,
                                                                                                                firstName:pushFirstName,
                                                                                                                lastName:pushLastName,
                                                                                                                email: pushEmail ,
                                                                                                                billingAddress: Address(streetAddress: billingAddressStreetAddress,
                                                                                                                                        city: billingAddressCity,
                                                                                                                                        state: billingAddressState,
                                                                                                                                        zip: billingAddressZip,
                                                                                                                                        latitude: 0,
                                                                                                                                        longitude: 0),
                                                                                                                phoneNumber: pushPhoneNumber,
                                                                                                                active: true,
                                                                                                                rate: pushRate,
                                                                                                                company: pushCompany,
                                                                                                                displayAsCompany: pushDisplayAsCompany,
                                                                                                                hireDate:Date(),
                                                                                                                billingNotes: ""),
                                                                                              companyId: company.id)
                                       }
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
                                       print("")
                                       showAlert = true
                                       print(error)
                                       alertMessage = "Failed To Upload"
                                       print(alertMessage)
                                       print(error)
                                       print("")
                                       return
                                   }
                                   
                               }
                           }
                       }
                   }
               }
        }

        .navigationTitle("Add New Customer")
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
    }
    
}
extension AddNewCustomerView{
    var submitButton:some View {
        Button(action: {
            Task{
                do {
                    if let company = masterDataManager.selectedCompany {
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
                        
                        
                        
                        if addFirstServiceLocation {
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
                                    rate: pushRate,
                                    company: pushCompany,
                                    displayAsCompany: pushDisplayAsCompany,
                                    hireDate:Date(),
                                    billingNotes: ""
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
                                    customerName: fullName
                                ),
                                companyId: company.id
                            )
                        } else {
                            try await customerVM.addNewCustomerWithOutLocation(customer:Customer(id: customerId,
                                                                                                 firstName:pushFirstName,
                                                                                                 lastName:pushLastName,
                                                                                                 email: pushEmail ,
                                                                                                 billingAddress: Address(streetAddress: billingAddressStreetAddress,
                                                                                                                         city: billingAddressCity,
                                                                                                                         state: billingAddressState,
                                                                                                                         zip: billingAddressZip,
                                                                                                                         latitude: 0,
                                                                                                                         longitude: 0),
                                                                                                 phoneNumber: pushPhoneNumber,
                                                                                                 active: true,
                                                                                                 rate: pushRate,
                                                                                                 company: pushCompany,
                                                                                                 displayAsCompany: pushDisplayAsCompany,
                                                                                                 hireDate:Date(),
                                                                                                 billingNotes: ""),
                                                                               companyId: company.id)
                        }
                        alertMessage = "Success"
                        print(alertMessage)
                        showAlert = true

                        firstName = ""
                        lastName = ""
                        email = ""
                        billingAddress = Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0)
                        phoneNumber = ""
                        rate = 0
                        companyName = ""
                        displayAsCompany = false
                        
                        dismiss()
                    }
                } catch {
                    print("")
                    print(error)
                    alertMessage = "upload Failed"
                    print(alertMessage)
                    showAlert = true
                    return
                }
            }
        },
               label: {
            Text("Submit")
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                .padding(5)
                .foregroundColor(Color.black)
        })
    }
}



