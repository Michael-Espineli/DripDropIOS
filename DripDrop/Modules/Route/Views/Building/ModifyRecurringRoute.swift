//
//  ModifyRecurringRoute.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/24/24.
//

import SwiftUI

struct ModifyRecurringRoute: View {
    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser,day:String,recurringRoute:RecurringRoute){
        _VM = StateObject(wrappedValue: ModifyRecurringRouteViewModel(dataService: dataService))
        _day = State(wrappedValue: day)
        _tech = State(wrappedValue: tech)
        _recurringRoute = State(wrappedValue: recurringRoute)

    }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject private var VM : ModifyRecurringRouteViewModel

    @State var tech:CompanyUser
    @State var day:String
    @State var recurringRoute:RecurringRoute

    var body: some View {
        ZStack{
            VStack{
                Text("Modify")
                    .font(.footnote)
                ScrollView{
                    if UIDevice.isIPad{
                        HStack{
                            Spacer()
                            Button(action: {
                                masterDataManager.selectedRouteBuilderTech = nil
                                masterDataManager.selectedRouteBuilderDay = nil
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                    }
                    form
                    button
                }
                .padding(8)
            }
            if VM.isLoading {
                ProgressView()
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            print("on arrival task")
            if let company = masterDataManager.currentCompany {
                print("Company - \(company)")
                print("Day - \(day)")
                print("Tech - \(tech.userName)")
                    do {
                        VM.selectedDay = day
                        VM.selectedCompanyUser = tech
                        VM.selectedRecurringRoute = recurringRoute
                        try await VM.onLoad(companyId: company.id)
                    } catch {
                        print("Error")
                        print(error)
                    }
            }
        }
        //Gets customer locations
        .onChange(of: VM.selectedCustomer, perform: { changedCustomer in
            if !VM.isLoading {
                
                Task{
                    if let company = masterDataManager.currentCompany {
                        print("Change of Customer")
                        do {
                            try await VM.onChangeOfCustomer(companyId: company.id)
                        } catch {
                            print("Error Getting locations")
                        }

                    }
                }
            }
        })
        .onChange(of: VM.customerSearch, perform: { search in
            VM.filterCustomerList()

        })
        .onChange(of: VM.selectedDay, perform: { datum in
            Task{
                if !VM.isLoading {
                    VM.isLoading = true
                    if let company = masterDataManager.currentCompany {
                        print("Company - \(company)")
                        print("Day - \(day)")
                        print("Tech - \(tech.userName)")
                            do {
                                try await VM.onLoad(companyId: company.id)
                            } catch {
                                print("Error")
                                print(error)
                            }
                    }
                    VM.isLoading = true
                }
                
            }
        })
        .onChange(of: VM.selectedCompanyUser, perform: { datum in
            Task{
                if !VM.isLoading {
                    VM.isLoading = true
                    if let company = masterDataManager.currentCompany {
                        print("Company - \(company)")
                        print("Day - \(day)")
                        print("Tech - \(tech.userName)")
                            do {
                                try await VM.onLoad(companyId: company.id)
                            } catch {
                                print("Error")
                                print(error)
                            }
                    }
                    VM.isLoading = true
                }
                
            }
        })
    }
}


extension ModifyRecurringRoute {
    var button: some View {
        HStack{
            Button(action: {
                Task{

                    do {
                        if let currentCompany = masterDataManager.currentCompany {
                            try await VM.modifyRecurringRouteWithVerification(
                                companyId: currentCompany.id
                            )
                        }
                        VM.isLoading = false
                        VM.alertMessage = "Success"
                        print(VM.alertMessage)
                        VM.showAlert = true
                        masterDataManager.selectedRouteBuilderTech = nil
                        masterDataManager.selectedRouteBuilderDay = nil
                        masterDataManager.reloadBuilderView = true
                    } catch {
                        VM.isLoading = false
                        VM.alertMessage = "Failed to Upload"
                        print(VM.alertMessage)
                        VM.showAlert = true
                        
                    }
                }
            },
                   label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())

            })
            .disabled(VM.isLoading)
            .opacity(VM.isLoading ? 0.75 : 1)
            Button(action: {
                dismiss()
            }, label: {
                Text("Discard Changes")
                    .modifier(DismissButtonModifier())
            })
        }
    }
    var form: some View {
        ScrollView{
            Text("Modify Recurring Route")
            technical
            info
        }
    }
 
    var info: some View {
        VStack{
            Text(VM.selectedJobTemplate.name)

            HStack{
                Button(action: {
                    VM.showCustomerPicker.toggle()
                }, label: {
                    Text(VM.listOfRecurringStops.isEmpty ? "Add First Customer":"Add Another")
                        .padding(8)
                        .background(Color.poolBlue)
                        .foregroundColor(Color.basicFontText)
                        .cornerRadius(8)
                })
                .sheet(isPresented: $VM.showCustomerPicker, onDismiss: {
                    VM.onDismissOfCustomerPicker()
                }, content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $VM.selectedCustomer,location: $VM.selectedLocation)
                })
                Spacer()
                if !VM.listOfRecurringStops.isEmpty {
                    Button(action: {
                        VM.showCustomerSheet.toggle()
                    }, label: {
                        Text("Customers - \(VM.listOfRecurringStops.count)")
                            .padding(8)
                            .background(Color.poolBlue)
                            .foregroundColor(Color.basicFontText)
                            .cornerRadius(8)
                    })
                    .disabled(VM.listOfRecurringStops.count == 0)
                    .sheet(isPresented: $VM.showCustomerSheet, content: {
                        VStack{
                            List{
                                ForEach(VM.listOfRecurringStops){ location in
                                    HStack{
                                        VStack{
                                            Text("\(location.customerName)")
                                            Text("\(location.address.streetAddress)")
                                                .font(.footnote)
                                        }
                                        Text(location.frequency.rawValue)
                                    }
                                }
                                .onDelete(perform: VM.removeFromListOfRecurringStops)
                            }
                        }
                    })
                }
            }
        }
    }
    var technical: some View {
        VStack{
            DatePicker(selection: $VM.startDate, displayedComponents: .date) {
                Text("Start Date")
            }
            Toggle("Never Ends", isOn: $VM.noEndDate)
            if !VM.noEndDate {
                DatePicker(selection: $VM.endDate, displayedComponents: .date) {
                    Text("End Date")
                }
            }
            TextField(
                "Description",
                text: $VM.description
            )
            .modifier(TextFieldModifier())

            TextField(
                "Estimated Time",
                text: $VM.estimatedTime
            )
            .modifier(TextFieldModifier())

            HStack{
                Picker("Tech", selection: $VM.selectedCompanyUser) {
                    Text("Tech").tag(CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor))
                    ForEach(VM.companyUsers){ tech in
                        Text("\(tech.userName)").tag(tech)
                    }
                }
                Spacer()
            }
            HStack{
                Picker("Day", selection: $VM.selectedDay) {
                    Text("Day").tag("")
                    ForEach(VM.days,id:\.self){ day in
                        Text("\(day)").tag(day)
                    }
                }
                Spacer()

            }
            HStack{
                Picker("Frequency", selection: $VM.frequency) {
                    ForEach(LaborContractFrequency.allCases,id:\.self){
                        Text($0.rawValue).tag($0)
                    }
                }
                Spacer()

            }
        }
    }
}
