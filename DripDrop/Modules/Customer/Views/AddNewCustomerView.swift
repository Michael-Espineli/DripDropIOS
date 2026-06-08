//
//  AddNewCustomerView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 6/24/23.
//


import SwiftUI

struct AddNewCustomerView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

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
    @State var serviceLocationMainContactNickName:String = "Main"
    @State var locationHasSeperateContact:Bool = false

    @State var estimatedTime:String = "15"
    @State var dogName:String = ""
    @State var isPreText:Bool = false


    
    //bool
    @State var displayAsCompany:Bool = false
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var addFirstServiceLocation:Bool = false
    
    //Custom
    @State var billingAddressQuery:String = ""

    @State var billingAddress:Address? = nil
    
    @State var serviceLocationAddressQuery:String = ""
    @State var serviceLocationAddress:Address? = nil
    
    @State var useDifferentBillingAddress:Bool = false

    @State var testAddress:Address = Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0)

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
        preText: false,
        isActive: true
    )
    @FocusState private var focusedField: NewCustomerFormLabels?
    @State var enableSheetDismiss:Bool = false
    @State var confirmDismiss:Bool = false

    var body: some View {
        ZStack{
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView(showsIndicators: false){
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Customer")
                            .font(.largeTitle)
                            .bold()
                        Text("Create the customer, first service location, contact, pool, pump, and filter.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                    
                    basicInfo
                    serviceLocationView
                    submitButton
                }
            }
            .padding(.init(top: 16, leading: 16, bottom: 0, trailing: 16))
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
                           focusedField = .serviceLocationMainContactNickName
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
                       if let company = masterDataManager.currentCompany {
                           Task{
                               do {
                                   let customerId = UUID().uuidString
                                   if displayAsCompany {
                                       if companyName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                           showAlert = true
                                           alertMessage = "Add FIrst Name"
                                           print(alertMessage)
                                           return
                                       }
                                   } else {
                                       if firstName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                           showAlert = true
                                           alertMessage = "Add FIrst Name"
                                           print(alertMessage)
                                           return
                                       }
                                       if firstName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                           showAlert = true
                                           alertMessage = "Add First Name"
                                           print(alertMessage)
                                           return
                                       }
                                   }
                                   
                                   if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                       showAlert = true
                                       alertMessage = "Add phone Number"
                                       print(alertMessage)
                                       return
                                   }
                                   
                                   if email.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                       showAlert = true
                                       alertMessage = "Add email"
                                       print(alertMessage)
                                       return
                                   }
                                   if !useDifferentBillingAddress {
                                       //Only Needs ServiceLocation Address
                                       billingAddress = serviceLocationAddress
                                   }
                                    guard let newServiceLocationAddress = serviceLocationAddress else  {
                                       showAlert = true
                                       alertMessage = "Billing Street Address Empty"
                                       print(alertMessage)
                                       return
                                   }
                                    guard let newBillingAddress = billingAddress else  {
                                       showAlert = true
                                       alertMessage = "Billing Street Address Empty"
                                       print(alertMessage)
                                       return
                                   }
                                   let fullName = firstName + " " + lastName

                                   var contact:Contact? = nil
                                   if locationHasSeperateContact {
                                       //Use Fields
                                       if serviceLocationMainContactName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                          showAlert = true
                                          alertMessage = "Add Contact Name or use Main Contact Information"
                                          print(alertMessage)
                                          return
                                       }
                                       if serviceLocationMainContactPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                          showAlert = true
                                          alertMessage = "Add Phone Number or use Main Contact Information"
                                          print(alertMessage)
                                          return
                                       }
                                       if serviceLocationMainContactEmail.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                          showAlert = true
                                          alertMessage = "Add Email or use Main Contact Information"
                                          print(alertMessage)
                                          return
                                       }
                                       
                                       contact = Contact(
                                        id: UUID().uuidString,
                                        name: serviceLocationMainContactName.trimmingCharacters(in: .whitespacesAndNewlines),
                                        phoneNumber: serviceLocationMainContactPhoneNumber,
                                        email: serviceLocationMainContactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                                        notes: contactNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                                    )

                                   } else {
                                       // Use Primary Information
                                       contact = Contact(
                                        id: UUID().uuidString,
                                        name: fullName,
                                        phoneNumber: phoneNumber,
                                        email: email,
                                        notes: ""
                                       )
                                   }
                                   guard let contact else {
                                       showAlert = true
                                       alertMessage = "Contact Error"
                                       print(alertMessage)
                                       return
                                   }
                                   guard let time = Int(estimatedTime) else {
                                       throw ServiceLocationError.invalidTime
                                   }
                                   
                                   let pushFirstName = firstName
                                   let pushLastName = lastName
                                   let pushEmail = email
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
                                        billingAddress: newBillingAddress,
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
                                        address: newServiceLocationAddress,
                                        gateCode: serviceLocationMainContactGateCode,
                                        dogName: [dogName],
                                        estimatedTime: time,
                                        mainContact: contact,
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
                                        isActive: true
                                    ),
                                    companyId: company.id
                                   )
                                   showAlert = true
                                   alertMessage = "Success"
                                   print(alertMessage)
                                           
                                   
                                   firstName = ""
                                   lastName = ""
                                   email = ""
                                   billingAddress = nil
                                   serviceLocationAddress = nil
                                   phoneNumber = ""
                                   rate = 0
                                   companyName = ""
                                   displayAsCompany = false
                                   enableSheetDismiss = true

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
        .interactiveDismissDisabled(enableSheetDismiss)

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
        .alert(isPresented:$confirmDismiss) {
            Alert(
                title: Text("Confirm"),
                message: Text("Leave Without Saving"),
                primaryButton: .destructive(Text("Delete")) {
                    enableSheetDismiss = true
                    dismiss()
                    print("...")
                },
                secondaryButton: .cancel()
            )
        }
    }
    
}
extension AddNewCustomerView{

    var basicInfo: some View {
        VStack(alignment: .leading, spacing: 12){
            Text("Customer Details")
                .font(.title3)
                .bold()
            HStack{
                Text("First Name")
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
                .modifier(PlainTextFieldModifier())
                .focused($focusedField, equals: .phoneNumber)
                     .submitLabel(.next)
                #if os(iOS)
                .keyboardType(.namePhonePad)
                #endif
            }
            HStack{
                Text("Email")
                TextField(
                    "Email",
                    text: $email
                )
                .modifier(PlainTextFieldModifier())
                .keyboardType(.emailAddress)
                .focused($focusedField, equals: .email)
                     .submitLabel(.next)
            }
            Toggle(isOn: $useDifferentBillingAddress, label: {
                Text("Use Different Billing Address")
            })
            if useDifferentBillingAddress {
                AddressAutocompleteView(
                    text: $billingAddressQuery,
                    selectedAddress: $billingAddress
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
 
    var serviceLocationView: some View {
        VStack(alignment: .leading, spacing: 16){
                
                VStack(alignment: .leading, spacing: 12){
                    Text("Service Location")
                        .font(.title3)
                        .bold()
                    
                    AddressAutocompleteView(
        //                        text: $vm.addressQuery,
                        text: $serviceLocationAddressQuery,
                        selectedAddress: $serviceLocationAddress
                    )
                }
                Text("Service Location Info")
                    .font(.headline)

                VStack(spacing: 10){
                    HStack{
                        Text("Nick Name")
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
                        TextField(
                            "Dog Name",
                            text: $dogName
                        )
                        .modifier(PlainTextFieldModifier())
                        .focused($focusedField, equals: .dogName)
                             .submitLabel(.next)
                    }
                    HStack{
                        Toggle(isOn: $isPreText, label: {
                            Text("Has Pre Text")
                        })
                    }
                    HStack{
                        Text("Notes")
                        TextField(
                            "Notes",
                            text: $contactNotes
                        )
                        .modifier(PlainTextFieldModifier())
                        .focused($focusedField, equals: .contactNotes)
                             .submitLabel(.next)
                    }
                }
                VStack(alignment: .leading, spacing: 10){
                    Text("Service Location Contact")
                        .font(.headline)
                    HStack{
                        Spacer()
                        Toggle(isOn: $locationHasSeperateContact, label: {
                            Text("Use Seperate Contact")
                        })
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                    if locationHasSeperateContact {
                        HStack{
                            Text("Name")
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
                            Text("Notes")
                            TextField(
                                "Notes",
                                text: $serviceLocationMainContactNotes
                            )
                            .modifier(PlainTextFieldModifier())
                            .focused($focusedField, equals: .serviceLocationMainContactNotes)
                            .submitLabel(.next)
                        }
                    }
                }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    var submitButton:some View {
        Button(action: {
            if let company = masterDataManager.currentCompany {
                Task{
                    do {
                        let customerId = UUID().uuidString
                        if displayAsCompany {
                            if companyName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                showAlert = true
                                alertMessage = "Add company Name"
                                print(alertMessage)
                                return
                            }
                        } else {
                            if firstName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                showAlert = true
                                alertMessage = "Add First Name"
                                print(alertMessage)
                                return
                            }
                            if firstName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                showAlert = true
                                alertMessage = "Add First Name"
                                print(alertMessage)
                                return
                            }
                        }
                        
                        if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                            showAlert = true
                            alertMessage = "Add phone Number"
                            print(alertMessage)
                            return
                        }
                        
                        if email.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                            showAlert = true
                            alertMessage = "Add email"
                            print(alertMessage)
                            return
                        }
                        if !useDifferentBillingAddress {
                            //Only Needs ServiceLocation Address
                            billingAddress = serviceLocationAddress
                        }
                         guard let newServiceLocationAddress = serviceLocationAddress else  {
                            showAlert = true
                            alertMessage = "Billing Street Address Empty"
                            print(alertMessage)
                            return
                        }
                         guard let newBillingAddress = billingAddress else  {
                            showAlert = true
                            alertMessage = "Billing Street Address Empty"
                            print(alertMessage)
                            return
                        }
                        let fullName = firstName + " " + lastName

                        var contact:Contact? = nil
                        if locationHasSeperateContact {
                            //Use Fields
                            if serviceLocationMainContactName.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                               showAlert = true
                               alertMessage = "Add Contact Name or use Main Contact Information"
                               print(alertMessage)
                               return
                            }
                            if serviceLocationMainContactPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                               showAlert = true
                               alertMessage = "Add Phone Number or use Main Contact Information"
                               print(alertMessage)
                               return
                            }
                            if serviceLocationMainContactEmail.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                               showAlert = true
                               alertMessage = "Add Email or use Main Contact Information"
                               print(alertMessage)
                               return
                            }
                            
                            contact = Contact(
                             id: UUID().uuidString,
                             name: serviceLocationMainContactName.trimmingCharacters(in: .whitespacesAndNewlines),
                             phoneNumber: serviceLocationMainContactPhoneNumber,
                             email: serviceLocationMainContactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                             notes: contactNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                         )

                        } else {
                            // Use Primary Information
                            contact = Contact(
                             id: UUID().uuidString,
                             name: fullName,
                             phoneNumber: phoneNumber,
                             email: email,
                             notes: ""
                            )
                        }
                        guard let contact else {
                            showAlert = true
                            alertMessage = "Contact Error"
                            print(alertMessage)
                            return
                        }
                        guard let time = Int(estimatedTime) else {
                            throw ServiceLocationError.invalidTime
                        }
                        
                        let pushFirstName = firstName
                        let pushLastName = lastName
                        let pushEmail = email
                        let pushPhoneNumber = phoneNumber
                        let pushCompany = companyName
                        let pushDisplayAsCompany = displayAsCompany
                        
                                
                        try await customerVM.addNewCustomerWithLocation(
                         customer:Customer(
                             id: customerId,
                             firstName:pushFirstName,
                             lastName:pushLastName,
                             email: pushEmail ,
                             billingAddress: newBillingAddress,
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
                             address: newServiceLocationAddress,
                             gateCode: serviceLocationMainContactGateCode,
                             dogName: [dogName],
                             estimatedTime: time,
                             mainContact: contact,
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
                             isActive: true
                         ),
                         companyId: company.id
                        )
                        showAlert = true
                        alertMessage = "Success"
                        print(alertMessage)
                                
                        
                        firstName = ""
                        lastName = ""
                        email = ""
                        billingAddress = nil
                        serviceLocationAddress = nil
                        phoneNumber = ""
                        rate = 0
                        companyName = ""
                        displayAsCompany = false
                        enableSheetDismiss = true

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
            
        },
               label: {
            Text("Submit")
                .modifier(SubmitButtonModifier())

        })
    }

}
