//
//  AddNewServiceStop.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/7/24.

import SwiftUI

struct AddNewServiceStop: View {
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

    @State var estimatedTime:String = ""
    @State var dogName:String = ""

    @State var preText:Bool = false
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
                    Text("Service Stop Info")
                        .font(.title)
                    Button(action: {
                        firstName = "Michael"
                        lastName = "Espineli"
                companyName = "Murdock Pool Service"
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
                    HStack{
                        Text("First Name")
                            .font(.headline)
                        TextField(
                            "Jon",
                            text: $firstName
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                                    }
                    HStack{
                        Text("Last Name")
                            .font(.headline)
                        
                        TextField(
                            "Doe",
                            text: $lastName
                        )
                        .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                    
                    }
                    Toggle(isOn: $displayAsCompany, label: {
                        Text("Display as Company")
                    })
                    if displayAsCompany {
                        HStack{
                            Text("Company Name")
                                .font(.headline)
                            
                            TextField(
                                "Doe",
                                text: $companyName
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                    }
             
                    HStack{
                        Text("Phone Number")
                        TextField(
                            "phone Number",
                            text: $phoneNumber
                        )
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
                            "email@gamil.com",
                            text: $email
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                    }
                }
                VStack{
                    Text("Billing Address")
                        .font(.title)
                    
                    HStack{
                        TextField(
                            "streetAddress",
                            text: $billingAddressStreetAddress
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    }
                    HStack{
                      
                        TextField(
                            "City",
                            text: $billingAddressCity
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    
                        TextField(
                            "State",
                            text: $billingAddressState
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                  
                        TextField(
                            "Zip",
                            text: $billingAddressZip
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        
                    }
                }
                // here
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
                    
                        }
                        Toggle(isOn: $preText, label: {
                            Text("Requires Pre Text")
                        })
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
                        }
                        HStack{
                  
                            TextField(
                                "City",
                                text: $serviceLocationAddressCity
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        
                            TextField(
                                "State",
                                text: $serviceLocationAddressState
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                    
                            TextField(
                                "Zip",
                                text: $serviceLocationAddressZip
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            
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
                            #if os(iOS)
                            .keyboardType(.namePhonePad)
#endif

                        }
                        HStack{
                            Text("email")
                                .font(.headline)
                            
                            TextField(
                                "email",
                                text: $serviceLocationMainContactEmail
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
#if os(iOS)

                            .keyboardType(.emailAddress)
                            #endif
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
                    
                        }
                    }
                    
                }
                
                HStack{
                    Text("rate")
                    TextField("",value: $rate, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
#if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
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
                                    preText:preText
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
                            showAlert = true
                            alertMessage = "upload Failed"
                            print(alertMessage)
                            return
                        }
                    }
                },
                       label: {
                    Text("Submit")
                        .modifier(SubmitButtonModifier())

                })
                
            }
            .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
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




