//
//  AddNewContact.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//


import SwiftUI

struct AddNewContact: View {
    @StateObject var VM : ChangeContactViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager

    init(dataService:any ProductionDataServiceProtocol, serviceLocation: ServiceLocation) {
        _VM = StateObject(wrappedValue: ChangeContactViewModel(dataService: dataService))
        self.serviceLocation = serviceLocation
    }
    @State var serviceLocation:ServiceLocation
    @FocusState private var focusedField: NewContactFormLabels?

    @State var name:String = ""
    @State var phoneNumber:String = ""
    @State var email:String = ""
    @State var notes:String = ""
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    Text("Name:")
                        .font(.headline)
                    Spacer()
                    TextField(
                        "Name",
                        text: $name
                    )
                    .modifier(PlainTextFieldModifier())
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                }
                HStack{
                    Text("Phone Number:")
                        .font(.headline)
                    Spacer()
                    
                    TextField(
                        "Phone Number",
                        text: $phoneNumber
                    )
                    .modifier(PlainTextFieldModifier())
                    .keyboardType(.namePhonePad)
                    .focused($focusedField, equals: .phoneNumber)
                    .submitLabel(.next)
                }
                HStack{
                    Text("Email:")
                        .font(.headline)
                    Spacer()
                    
                    TextField(
                        "Email",
                        text: $email
                    )
                    .modifier(PlainTextFieldModifier())
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                }
                HStack{
                    Text("Notes:")
                        .font(.headline)
                    Spacer()
                }
                TextField(
                    "Notes",
                    text: $notes,
                    axis: .vertical
                )
                .modifier(PlainTextFieldModifier())
                .lineLimit(5)
                .focused($focusedField, equals: .notes)
                .submitLabel(.next)
                
                
                button
            }
            .padding(8)
        }
        .onSubmit {
               switch focusedField {
               case .name:
                   focusedField = .phoneNumber
               case .phoneNumber:
                   focusedField = .email
               case .email:
                   focusedField = .notes
               case .notes:
                   Task{
                       if let selectedCompany = masterDataManager.currentCompany{
                           do {
                               try await VM.addNewCustomerContact(
                                   companyId: selectedCompany.id,
                                   customerId: serviceLocation.customerId,
                                   contact: Contact(
                                       id: UUID().uuidString,
                                       name: name,
                                       phoneNumber: phoneNumber,
                                       email: email,
                                       notes: notes
                                   )
                               )
                               alertMessage = "Successfully Updated"
                               showAlert = true
                               print(alertMessage)
                               name = ""
                               phoneNumber = ""
                               email = ""
                               notes = ""
                           } catch {
                               print("error")
                               print(error)
                           }
                       }
                   }
               default:
                   focusedField = .notes

               }
           }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
//
//#Preview {
//    AddNewContact()
//}
extension AddNewContact {
    var button: some View {
        Button(action: {
            Task{
                if let selectedCompany = masterDataManager.currentCompany{
                    do {
                        try await VM.addNewCustomerContact(
                            companyId: selectedCompany.id,
                            customerId: serviceLocation.customerId,
                            contact: Contact(
                                id: UUID().uuidString,
                                name: name,
                                phoneNumber: phoneNumber,
                                email: email,
                                notes: notes
                            )
                        )
                        alertMessage = "Successfully Updated"
                        showAlert = true
                        print(alertMessage)
                        name = ""
                        phoneNumber = ""
                        email = ""
                        notes = ""
                    } catch {
                        print("error")
                        print(error)
                    }
                }
            }
        },
               label: {
          Text("Add")
                .modifier(AddButtonModifier())
        })
    }
}
