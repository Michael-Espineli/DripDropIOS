//
//  EmailConfigurationView.swift
//  DripDrop
//
//  Created by Michael Espineli on 9/26/24.
//

import SwiftUI
enum EmailConfigLabel {
    case email
case name
}
struct EmailConfigurationView: View {
    @StateObject var viewModel = EmailConfigurationViewModel(dataService: ProductionDataService())
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @FocusState var emailLabel:EmailConfigLabel?

    @State var selectAll:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                header
                ScrollView{
                    content
                    if viewModel.emailIsOn {
                        Rectangle()
                            .frame(height: 1)
                        customerList
                    }
                }
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Email Configuration")
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await viewModel.onLoad(companyId: currentCompany.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: viewModel.emailIsOn, perform: { on in
            viewModel.checkChanges()
        })
    }
}

#Preview {
    EmailConfigurationView()
}
extension EmailConfigurationView {
    var header: some View {
        VStack{
            
        }
    }
    var content: some View {
        VStack{
            if viewModel.hasChanges {
                HStack{
                    Button(action: {
                        if let emailConfig = viewModel.emailConfig {
                            viewModel.emailIsOn = emailConfig.emailIsOn
                            viewModel.emailBody = emailConfig.emailBody
                        }
                    }, label: {
                        Text("Undo")
                            .modifier(DismissButtonModifier())
                    })
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1)
                    Spacer()
                    Button(action: {
                        Task{
                            if let currentCompany = masterDataManager.currentCompany {
                                do {
                                    try await viewModel.saveChanges(companyId: currentCompany.id)
                                } catch {
                                    print(error)
                                }
                            }
                            
                        }
                    }, label: {
                        Text("Save")
                            .modifier(AddButtonModifier())
                    })
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1)
                }
            }
            HStack{
                Button(action: {
                    viewModel.emailIsOn.toggle()
                }, label: {
                    if viewModel.emailIsOn {
                        
                        Image(systemName:"checkmark.square")
                            .modifier(SubmitButtonModifier())
                    } else {
                        Image(systemName:"square")
                            .modifier(AddButtonModifier())
                    }
                })
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.6 : 1)
                Spacer()
                Text("Turn On Email Reports")
            }
            if viewModel.emailIsOn {
                VStack{
                    HStack{
                        if let emailConfig = viewModel.emailConfig {
                            if viewModel.emailBody != emailConfig.emailBody {
                                
                                Button(action: {
                                    if let emailConfig = viewModel.emailConfig {
                                        viewModel.emailIsOn = emailConfig.emailIsOn
                                    }
                                }, label: {
                                    Image(systemName: "gobackward")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                    }
                        Spacer()
                        Text("Email Body")
                        Spacer()
                        if let emailConfig = viewModel.emailConfig {
                            if viewModel.emailBody != emailConfig.emailBody {
                                Button(action: {                            emailLabel = nil
                                    Task{
                                        if let currentCompany = masterDataManager.currentCompany {
                                            do {
                                                try await viewModel.saveChanges(companyId: currentCompany.id)
                                            } catch {
                                                print(error)
                                            }
                                        }
                                        
                                    }
                                }, label: {
                                    Text("Save")
                                        .modifier(AddButtonModifier())
                                })
                            }
                        }
                    }
                    TextField(
                        "",
                        text: $viewModel.emailBody,
                        axis: .vertical
                    )
                    .padding(3)
                    .background(Color.poolBlue.opacity(0.3))
                    .cornerRadius(5.0)
                    .padding(8)
                    .focused($emailLabel, equals: .email)
                    .submitLabel(.return)
                }
                HStack{
                    Button(action: {
                        viewModel.requiresPhoto.toggle()
                    }, label: {
                        if viewModel.requiresPhoto {
                            
                            Image(systemName:"checkmark.square")
                                .modifier(SubmitButtonModifier())
                        } else {
                            Image(systemName:"square")
                                .modifier(AddButtonModifier())
                        }
                    })
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1)
                    Spacer()
                    Text("Require Photo On Complete")
                }
            }
        }
        .padding(8)
    }
    var customerList: some View {
        VStack{
            HStack{
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            
                            do {
                                try await viewModel.updateAllCustomerEmailConfig(companyId: currentCompany.id, emailIsOn: viewModel.allCustomersSelected)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    if viewModel.allCustomersSelected {
                        Image(systemName:"checkmark.square")
                            .modifier(SubmitButtonModifier())
                    } else {
                        Image(systemName:"square")
                            .modifier(AddButtonModifier())
                    }
                })
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.6 : 1)
                Spacer()
                Text("All Customers")
            }
            .padding(.horizontal,8)
            Divider()
            ForEach(viewModel.customers) { customer in
                    HStack{
                        if var customerEmailConfig = viewModel.customerConfigList.first(where: {$0.customerId == customer.id}) {
                            Button(action: {
                                customerEmailConfig.emailIsOn.toggle()
                                Task{
                                    if let currentCompany = masterDataManager.currentCompany {
                                        do {
                                            try await viewModel.updateCustomerConfig(companyId: currentCompany.id, customerEmailConfig: customerEmailConfig, customer: customer, emailIsOn: customerEmailConfig.emailIsOn)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }, label: {
                                if customerEmailConfig.emailIsOn {
                                    
                                    Image(systemName:"checkmark.square")
                                        .modifier(SubmitButtonModifier())
                                } else {
                                    Image(systemName:"square")
                                        .modifier(AddButtonModifier())
                                }
                            })
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.6 : 1)
                        } else {
                            Button(action: {
                                Task{
                                    if let currentCompany = masterDataManager.currentCompany {
                                        do {
                                            try await viewModel.updateCustomerConfig(companyId: currentCompany.id, customerEmailConfig: nil, customer: customer, emailIsOn: true)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }, label: {
                                Image(systemName:"square")
                                    .modifier(AddButtonModifier())
                            })
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.6 : 1)
                        }
                        Spacer()
                        if customer.displayAsCompany {
                            if let company = customer.company {
                                Text("\(company)")
                            }
                        } else {
                            Text("\(customer.firstName) \(customer.lastName)")
                        }
                    }
                    .padding(.horizontal,8)
                
            }
        }
    }
}
