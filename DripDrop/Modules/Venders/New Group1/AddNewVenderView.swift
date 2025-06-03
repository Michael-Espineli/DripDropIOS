//
//  AddNewStoreView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import SwiftUI

struct AddNewVenderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    //VMs
    @StateObject private var viewModel = StoreViewModel()

    
    @State var name:String = ""
    @State var email:String = ""
    @State var streetAddress:String = ""
    @State var city:String = ""
    @State var state:String = ""
    @State var zip:String = ""
    
    @State var phoneNumber:String = ""
    
    var body: some View {
        ScrollView{
            HStack{
                Text("name")
                TextField(
                    "name",
                    text: $name
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                
            }
            HStack{
                Text("Phone Number")
                TextField(
                    "phone Number",
                    text: $phoneNumber
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)            }
            HStack{
                Text("email")
                TextField(
                    "email@gamil.com",
                    text: $email
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                
            }
            //Street Address Example
            VStack{
                HStack{
                    TextField(
                        "streetAddress",
                        text: $streetAddress
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    TextField(
                        "City",
                        text: $city
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    TextField(
                        "State",
                        text: $state
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    TextField(
                        "Zip",
                        text: $zip
                    )
                    .keyboardType(.decimalPad)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
            }
            
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany {
                        let pushName = name
                        let pushEmail = email
                        let pushPhoneNumber = phoneNumber
                        do {
                            try await viewModel.addNewStore(
                                companyId: company.id,
                                store:Vender(
                                    id: UUID().uuidString,
                                    name:pushName,
                                    email: pushEmail,
                                    address: Address(
                                        streetAddress: streetAddress,
                                        city: city,
                                        state: state,
                                        zip: zip,
                                        latitude: 0,
                                        longitude: 0
                                    ),
                                    phoneNumber: pushPhoneNumber
                                )
                            )
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                }
            },
                   label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())

            })
            
        }
        .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
        .task{
            
        }
        .navigationTitle("Add New Store")
    }
    
}


