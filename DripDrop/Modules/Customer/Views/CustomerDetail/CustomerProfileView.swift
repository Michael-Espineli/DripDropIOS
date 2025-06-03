    //
    //  CustomerProfileView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //

import SwiftUI
import MapKit
import UniformTypeIdentifiers

struct CustomerProfileView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    let customer:Customer
    @State var showEditView:Bool = false
    @State var showInviteLinkedCustomer:Bool = false
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    
    @State var selectedInviteTypes:[String] = []
    
    @State var showPhoneNumberPicker:Bool = false
    @State var showNewChat:Bool = false

    @State var phoneNumberPickerType:PhoneNumberPickerType? = nil
    var body: some View {
        ZStack{
            ScrollView(showsIndicators: false){
                image
                    .sheet(isPresented: $showNewChat, onDismiss: {
                        phoneNumberPickerType = nil
                    }, content: {
                        AddNewChatView(dataService: dataService, receivedCustomer: customer)
                    })
                info
                    .sheet(isPresented: $showEditView, content: {
                        CustomerProfileEditView(dataService: dataService, customer: customer)
                    })
            }
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing){
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("16") {
                        HStack{
                            Spacer()
                            Button(action: {
                                showEditView.toggle()
                            }, label: {
                                Text("Edit")
                            })
                        }
                        .padding(5)
                    }
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }

        .onChange(of: phoneNumberPickerType, perform: { type in
            if let selectedType = type{
                if let strNumber = customer.phoneNumber {
                    
                    
                    print(selectedType)
                    switch selectedType {
                    case .call:
                        let tel = "tel://"
                        let formattedString = tel + strNumber
                        guard let url = URL(string: formattedString) else { return }
                        UIApplication.shared.open(url)
                        print(selectedType)
                    case .message:
                        let tel = "sms://"
                        let formattedString = tel + strNumber
                        guard let url = URL(string: formattedString) else { return }
                        UIApplication.shared.open(url)
                        print(selectedType)
                        print(selectedType)
                    case .inApp:
                        print("Need to set up internal App Communication")
                        showNewChat.toggle()
                    }
                }
            }
        })
    }
}
extension CustomerProfileView {
    var info: some View {
        VStack{
            VStack(spacing: 8){
                if let linkedCustomerId = customer.linkedCustomerIds {
                    HStack{
                        Text("Linked Account")
                            .modifier(AddButtonModifier())
                        Spacer()
                        
                    }
                } else {
                    HStack{
                        Text("No Account Linked")
                            .modifier(DismissButtonModifier())
                        Spacer()
                        Button(action: {
                            showInviteLinkedCustomer.toggle()
                        }, label: {
                            Text("Invite")
                                .modifier(AddButtonModifier())
                            
                        })
                        .sheet(isPresented: $showInviteLinkedCustomer, onDismiss: {
                            selectedInviteTypes = []
                        }, content: {
                            VStack(spacing:16){
                                HStack{
                                    Text("Invite Code: ")
                                        .font(.headline)
#if os(iOS)
                                    Button(action: {
                                        UIPasteboard.general.setValue("\(customer.linkedInviteId)",forPasteboardType: UTType.plainText.identifier)
                                        alertMessage = "Invite Code Copied"
                                        showAlert.toggle()
                                    }, label: {
                                        Image(systemName: "square.fill.on.square.fill")
                                    })
#endif
                                }
                                Text(customer.linkedInviteId)
                                    .textSelection(.enabled)
                                if let phone = customer.phoneNumber {
                                    HStack{
                                        Text("Phone: \(phone)")
                                        Button(action: {
                                            if selectedInviteTypes.contains("Phone") {
                                                selectedInviteTypes.removeAll(where: {$0 == "Phone"})
                                            } else {
                                                selectedInviteTypes.append("Phone")
                                            }
                                        }, label: {
                                            Image(systemName: selectedInviteTypes.contains("Phone") ? "checkmark.square.fill" : "square")
                                                .font(.headline)
                                        })
                                        Spacer()
                                    }
                                }
                                HStack{
                                    Text("Email: \(customer.email)")
                                    Button(action: {
                                        if selectedInviteTypes.contains("Email") {
                                            selectedInviteTypes.removeAll(where: {$0 == "Email"})
                                        } else {
                                            selectedInviteTypes.append("Email")
                                        }
                                    }, label: {
                                        Image(systemName: selectedInviteTypes.contains("Email") ? "checkmark.square.fill" : "square")
                                            .font(.headline)
                                    })
                                    Spacer()
                                }
                                Spacer()
                                Button(action: {
                                    alertMessage = "Invite Sent"
                                    showAlert.toggle()
                                    showInviteLinkedCustomer.toggle()
                                }, label: {
                                    Text("Send Invite")
                                        .modifier(AddButtonModifier())
                                })
                                .padding(16)
                            }
                            
                        })
                    }
                }
                Rectangle()
                    .frame(height: 1)
                if customer.displayAsCompany {
                    HStack{
                        Text("Company: ")
                            .bold(true)
                        Spacer()
                        Text("\(customer.company ?? "")")
                    }
                } else {
                    HStack{
                        Text("Name: ")
                            .bold(true)
                        Spacer()
                        
                        Text("\(customer.firstName) \(customer.lastName)")
                        if customer.firstName == "" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.yellow)
                        }
                    }
                    
                }
                HStack{
                    Text("Email: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.email)")
                    if customer.email == "" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.yellow)
                    } else {
                        Button(action: {
                            
                        }, label: {
                            Image(systemName: "mail")
                                .modifier(BlueButtonModifier())
                        })
                    }
                }
                HStack{
                    Text("Phone Number: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.phoneNumber ?? "")")
                    if customer.phoneNumber == "" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.yellow)
                    } else {
                        Button(action: {
                            showPhoneNumberPicker.toggle()
                        }, label: {
                            Image(systemName: "message")
                                .modifier(BlueButtonModifier())
                        })
                    }
                    
                }
                .confirmationDialog("Select Type", isPresented: self.$showPhoneNumberPicker, actions: {
                    if let linkedCustomerId = customer.linkedCustomerIds {
                        Button(action: {
                            self.phoneNumberPickerType = .inApp
                        }, label: {
                            Text("In App")
                        })
                    }
                    if let phoneNumber = customer.phoneNumber {
                        if phoneNumber != "" {
                            Button(action: {
                                self.phoneNumberPickerType = .call
                            }, label: {
                                Text("Call: \(phoneNumber)")
                            })
                            Button(action: {
                                self.phoneNumberPickerType = .message
                            }, label: {
                                Text("Message: \(phoneNumber)")
                            })
                        }
                    }
                })
                HStack{
                    Text("Phone Label: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.phoneLabel ?? "")")
                    if customer.phoneLabel == "" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.yellow)
                    }
                }
                HStack{
                    Text("Active: ")
                        .bold(true)
                    Spacer()
                    Text("\(String(customer.active))")
                }
            }
            Rectangle()
                .frame(height: 1)
            VStack(alignment:.leading){
                Text("Billing Address: ")
                    .bold(true)
                
                Button(action: {
                    let address = "\(customer.billingAddress.streetAddress) \(customer.billingAddress.city) \(customer.billingAddress.state) \(customer.billingAddress.zip)"
                    
                    let urlText = address.replacingOccurrences(of: " ", with: "?")
                    
                    let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
                }, label: {
                    VStack{
                        Text("\(customer.billingAddress.streetAddress)")
                        HStack{
                            Text("\(customer.billingAddress.state)")
                            Text("\(customer.billingAddress.city)")
                            Text("\(customer.billingAddress.zip)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .foregroundColor(Color.basicFontText)
                })
            }
            Rectangle()
                .frame(height: 1)
        }
    }
    var image: some View {
        ZStack{
            VStack{
                BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: customer.billingAddress.latitude, longitude: customer.billingAddress.longitude))
                    .frame(height: 150)
            }
            .padding(0)
            VStack{
                ZStack{
                    Circle()
                        .fill(Color.realYellow)
                        .frame(maxWidth:100 ,maxHeight:100)
                    
                    Image(systemName:"person.circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:90 ,maxHeight:90)
                        .cornerRadius(75)
                }
                    //                .frame(maxWidth: 150,maxHeight:150)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
        }
    }
}
