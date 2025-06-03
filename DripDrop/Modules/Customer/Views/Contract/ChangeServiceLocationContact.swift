//
//  ChangeServiceLocationContact.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//

import SwiftUI

struct ChangeServiceLocationContact: View {
    @StateObject var VM : ChangeContactViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    init(dataService:any ProductionDataServiceProtocol, serviceLocation: ServiceLocation) {
        _VM = StateObject(wrappedValue: ChangeContactViewModel(dataService: dataService))
        self.serviceLocation = serviceLocation
    }
    @State var serviceLocation:ServiceLocation
    @State var isPresented:Bool = false

    var body: some View {
        ScrollView{
            HStack{
                Button(action: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                try await VM.getCustomerContacts(companyId: company.id, customerId: serviceLocation.customerId, serviceLocationId: serviceLocation.id)
                            } catch {
                                print("error")
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Image(systemName: "gobackward")
                        .modifier(AddButtonModifier())
                })
                Spacer()
                Text("Change Contact")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isPresented.toggle()
                }, label: {
                    Image(systemName: "plus")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $isPresented,onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                try await VM.getCustomerContacts(companyId: company.id, customerId: serviceLocation.customerId, serviceLocationId: serviceLocation.id)
                            } catch {
                                print("error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    AddNewContact(dataService: dataService, serviceLocation: serviceLocation)
                    .presentationDetents([.medium])
                })
            }
            Rectangle()
                .frame(height: 1)
            Text("Current Contact")
                .bold(true)
            ContactInfo(contact: serviceLocation.mainContact)
            Rectangle()
                .frame(height: 1)
            ForEach(VM.contactList){ contact in
                if contact.id != serviceLocation.mainContact.id {
                    Button(action: {
                        Task{
                            if let company = masterDataManager.currentCompany {
                                do {
                                    try await VM.changeServiceLocationContact(companyId: company.id, serviceLocationId: serviceLocation.id, contact: contact)
                                } catch {
                                    print("error")
                                    print(error)
                                }
                            }
                        }
                    }, label: {
                        HStack{
                            if contact.id == serviceLocation.mainContact.id {
                                Image(systemName:"checkmark.square")
                                    .modifier(SubmitButtonModifier())
                            } else {
                                Image(systemName:"square")
                                    .modifier(AddButtonModifier())
                            }
                            Spacer()
                            ContactInfo(contact: contact)
                        }
                    })
                }
            }
        }
        .padding(8)
        .task {
            //Get Customer Contacts
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.getCustomerContacts(companyId: company.id, customerId: serviceLocation.customerId, serviceLocationId: serviceLocation.id)
                } catch {
                    print("error")
                    print(error)
                }
            }
        }

    }
}
//
//#Preview {
//    ChangeServiceLocationContact()
//}
