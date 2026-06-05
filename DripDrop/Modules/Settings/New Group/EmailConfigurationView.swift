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
    init(dataService:any ProductionDataServiceProtocol){
        _viewModel = StateObject(wrappedValue: EmailConfigurationViewModel(dataService: dataService))
    }
    @StateObject private var viewModel : EmailConfigurationViewModel

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
                    if viewModel.hasAnyCategoryEmailOn {
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
                    print("Error On Load Email Configuration")
                    viewModel.isLoading = false
                    print(error)
                }
            }
        }
    }
}

#Preview {
    EmailConfigurationView(dataService: MockDataService())
}
extension EmailConfigurationView {
    var header: some View {
        VStack{
            Text("")
        }
    }
    var content: some View {
        VStack{
            if viewModel.hasChanges {
                HStack{
                    Button(action: {
                        viewModel.resetChanges()
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
            categorySettingsList
        }
        .padding(8)
    }

    var categorySettingsList: some View {
        VStack(spacing: 12) {
            ForEach(ServiceStopCategory.allCases) { category in
                categorySettingsRow(for: category)
            }
        }
    }

    func categorySettingsRow(for category: ServiceStopCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(category.title, systemImage: category.systemImage)
                .font(.headline)

            HStack{
                Button(action: {
                    updateCategorySetting(for: category) { setting in
                        setting.sendEmailOnFinish.toggle()
                    }
                }, label: {
                    if categorySetting(for: category).sendEmailOnFinish {
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
                Text("Send Email When Finished")
            }

            HStack{
                Button(action: {
                    updateCategorySetting(for: category) { setting in
                        setting.requirePhotoOnFinish.toggle()
                    }
                }, label: {
                    if categorySetting(for: category).requirePhotoOnFinish {
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
                Text("Require Photo To Finish")
            }

            Text("Subject")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(
                "Subject",
                text: categoryStringBinding(for: category, keyPath: \.emailSubject)
            )
            .padding(6)
            .background(Color.poolBlue.opacity(0.3))
            .cornerRadius(5.0)

            Text("Body")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(
                "",
                text: categoryStringBinding(for: category, keyPath: \.emailBody),
                axis: .vertical
            )
            .padding(6)
            .background(Color.poolBlue.opacity(0.3))
            .cornerRadius(5.0)
            .submitLabel(.return)

            Text("Footer")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(
                "Footer",
                text: categoryStringBinding(for: category, keyPath: \.emailFooter),
                axis: .vertical
            )
            .padding(6)
            .background(Color.poolBlue.opacity(0.3))
            .cornerRadius(5.0)
            .submitLabel(.return)
        }
        .padding(10)
        .background(Color.white.opacity(0.45))
        .cornerRadius(8)
    }

    func categorySetting(for category: ServiceStopCategory) -> ServiceStopCategoryCompletionSettings {
        viewModel.categorySettings[category.rawValue] ?? ServiceStopCategoryCompletionSettings.defaultSettings(for: category)
    }

    func updateCategorySetting(
        for category: ServiceStopCategory,
        update: (inout ServiceStopCategoryCompletionSettings) -> Void
    ) {
        var setting = categorySetting(for: category)
        update(&setting)
        viewModel.categorySettings[category.rawValue] = setting
        viewModel.checkChanges()
    }

    func categoryStringBinding(
        for category: ServiceStopCategory,
        keyPath: WritableKeyPath<ServiceStopCategoryCompletionSettings, String>
    ) -> Binding<String> {
        Binding(
            get: {
                categorySetting(for: category)[keyPath: keyPath]
            },
            set: { newValue in
                updateCategorySetting(for: category) { setting in
                    setting[keyPath: keyPath] = newValue
                }
            }
        )
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
