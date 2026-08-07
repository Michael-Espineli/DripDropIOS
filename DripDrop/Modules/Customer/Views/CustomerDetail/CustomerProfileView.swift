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
    @EnvironmentObject var VM : CustomerListViewModel
    private var customer: Customer? {
        VM.customers.first { $0.id == customerId }
    }
    let customerId: String
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
                if let customer {
                    if UIDevice.isIPhone {
                        mobileProfile(customer)
                    } else {
                        image
                        info
                    }
                }
            }
        }
        .sheet(isPresented: $showNewChat, onDismiss: {
            phoneNumberPickerType = nil
        }, content: {
            if let customer {
                NavigationStack {
                    AddNewChatView(dataService: dataService, receivedCustomer: customer)
                }
            }
        })
        .sheet(isPresented: $showEditView, content: {
            if let customer {
                CustomerProfileEditView(dataService: dataService, customer: customer)
            }
        })
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing){
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("16") {
                        Button(action: {
                            showEditView.toggle()
                        }, label: {
                            Text("Edit")
                        })
                    }
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }

        .onChange(of: phoneNumberPickerType, perform: { type in
            if let selectedType = type{
                if let customer {
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
            }
        })
    }
}
extension CustomerProfileView {
    private func mobileProfile(_ customer: Customer) -> some View {
        VStack(spacing: 12) {
            accountLinkCard(customer)
            contactCard(customer)
            addressCard(customer)

            CustomerBillingView(
                dataService: dataService,
                customer: customer
            )
        }
    }

    private func accountLinkCard(_ customer: Customer) -> some View {
        profileSection(
            title: "Account",
            systemImage: "person.crop.circle.badge.checkmark",
            tint: .poolGreen
        ) {
            let hasLinkedAccount = customer.linkedCustomerIds?.isEmpty == false

            HStack(spacing: 10) {
                Label(hasLinkedAccount ? "Linked Account" : "No Account Linked", systemImage: hasLinkedAccount ? "checkmark.circle.fill" : "person.crop.circle.badge.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasLinkedAccount ? Color.poolGreen : Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background((hasLinkedAccount ? Color.poolGreen : Color.orange).opacity(0.10), in: Capsule())

                Spacer()

                if !hasLinkedAccount {
                    Button {
                        showInviteLinkedCustomer.toggle()
                    } label: {
                        Label("Invite", systemImage: "paperplane.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showInviteLinkedCustomer, onDismiss: {
                        selectedInviteTypes = []
                    }, content: {
                        inviteSheet(customer)
                    })
                }
            }
        }
    }

    private func contactCard(_ customer: Customer) -> some View {
        profileSection(
            title: "Contact",
            systemImage: "bubble.left.and.text.bubble.right.fill",
            tint: .poolBlue
        ) {
            VStack(spacing: 8) {
                profileInfoRow(
                    title: customer.displayAsCompany ? "Company" : "Name",
                    value: customer.displayAsCompany ? (customer.company ?? "") : "\(customer.firstName) \(customer.lastName)",
                    systemImage: customer.displayAsCompany ? "building.2.fill" : "person.fill",
                    tint: .poolBlue
                )

                profileInfoRow(
                    title: "Email",
                    value: customer.email,
                    systemImage: "envelope.fill",
                    tint: .orange
                )

                profileInfoRow(
                    title: "Phone",
                    value: customer.phoneNumber ?? "",
                    systemImage: "phone.fill",
                    tint: .poolGreen,
                    actionSystemImage: customer.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? "message.fill" : nil
                ) {
                    showPhoneNumberPicker.toggle()
                }
                .confirmationDialog("Select Type", isPresented: self.$showPhoneNumberPicker, actions: {
                    if customer.linkedCustomerIds?.isEmpty == false {
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

                profileInfoRow(
                    title: "Phone Label",
                    value: customer.phoneLabel ?? "",
                    systemImage: "tag.fill",
                    tint: .secondary
                )
            }
        }
    }

    private func addressCard(_ customer: Customer) -> some View {
        profileSection(
            title: "Billing Address",
            systemImage: "map.fill",
            tint: .poolGreen
        ) {
            Button {
                openCustomerAddress(customer)
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.poolGreen)
                        .frame(width: 34, height: 34)
                        .background(Color.poolGreen.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(customer.billingAddress.streetAddress.isEmpty ? "No street address" : customer.billingAddress.streetAddress)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(customerAddressLine(customer))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func profileSection<Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.13), in: Circle())

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            content()
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func profileInfoRow(
        title: String,
        value: String,
        systemImage: String,
        tint: Color,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Missing" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.orange : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            if let actionSystemImage, let action {
                Button(action: action) {
                    Image(systemName: actionSystemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 30, height: 30)
                        .background(Color.poolBlue, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func inviteSheet(_ customer: Customer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())

                Text("Invite Customer")
                    .font(.headline.weight(.semibold))

                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Invite Code")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(customer.linkedInviteId)
                        .font(.subheadline.weight(.semibold))
                        .textSelection(.enabled)
                }

                Spacer()

#if os(iOS)
                Button {
                    UIPasteboard.general.setValue("\(customer.linkedInviteId)",forPasteboardType: UTType.plainText.identifier)
                    alertMessage = "Invite Code Copied"
                    showAlert.toggle()
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolBlue)
                        .frame(width: 32, height: 32)
                        .background(Color.poolBlue.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
#endif
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            if let phone = customer.phoneNumber, !phone.isEmpty {
                inviteToggleRow(title: "Phone: \(phone)", type: "Phone", systemImage: "phone.fill")
            }

            inviteToggleRow(title: "Email: \(customer.email)", type: "Email", systemImage: "envelope.fill")

            Spacer()

            Button {
                alertMessage = "Invite Sent"
                showAlert.toggle()
                showInviteLinkedCustomer.toggle()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send Invite")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.listColor.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func inviteToggleRow(title: String, type: String, systemImage: String) -> some View {
        Button {
            if selectedInviteTypes.contains(type) {
                selectedInviteTypes.removeAll(where: {$0 == type})
            } else {
                selectedInviteTypes.append(type)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 28, height: 28)
                    .background(Color.poolBlue.opacity(0.10), in: Circle())

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: selectedInviteTypes.contains(type) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedInviteTypes.contains(type) ? Color.poolGreen : Color.secondary)
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func customerAddressLine(_ customer: Customer) -> String {
        let cityStateZip = [
            customer.billingAddress.city,
            customer.billingAddress.state,
            customer.billingAddress.zip
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cityStateZip.isEmpty ? "No city, state, or zip" : cityStateZip
    }

    private func openCustomerAddress(_ customer: Customer) {
        let address = "\(customer.billingAddress.streetAddress) \(customer.billingAddress.city) \(customer.billingAddress.state) \(customer.billingAddress.zip)"
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "maps://?saddr=&daddr=\(encodedAddress)"),
              UIApplication.shared.canOpenURL(url) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    var info: some View {
        VStack{
            if let customer {
                
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
                CustomerBillingView(
                    dataService: dataService,
                    customer: customer
                )
            }
        }
    }
    var image: some View {
        ZStack{
            if let customer {
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
}
