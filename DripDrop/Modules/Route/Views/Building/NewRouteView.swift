//
//  NewRouteView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
//Designed to be a sheet Or FullScreen Cover Page
import SwiftUI

struct NewRouteView: View {
    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser,day:String){
        _VM = StateObject(wrappedValue: NewRouteViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
        _day = State(wrappedValue: day)
    }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject var VM : NewRouteViewModel
    
    @State var tech:CompanyUser
    @State var day:String
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                Text("New Route")
                ScrollView{
                    form
                }
                button
            }
            .padding(8)
            if VM.isLoading {
                VStack{
                    Text("Loading ...")
                    ProgressView()
                }
                .padding(8)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
        
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            print("arrived")
            if let company = masterDataManager.currentCompany {
                VM.selectedDay = day
                VM.techEntity = tech
                do {
                    try await VM.onLoad(companyId: company.id)
                    
                } catch {
                    print("")
                    print("New Route View Error >>")
                    print(error)
                    print("")
                }
            }
            
        }
        .onChange(of: VM.companyUser, perform: { tech in
            if let tech {
                VM.techEntity = tech
            }
        })
        .onChange(of: VM.selectedDay, perform: { datum in
            Task{
                if let company = masterDataManager.currentCompany {
                    do {
                        VM.selectedDay = datum
                        try await VM.onLoad(companyId: company.id)
                    } catch {
                        print(error)
                    }
                }
            }
            
        })
        .onChange(of: VM.techEntity, perform: { tech in
            Task{
                if let company = masterDataManager.currentCompany {
                    VM.techEntity = tech
                    do {
                        try await VM.onLoad(companyId: company.id)
                    } catch {
                        print(error)
                    }
                } else {
                    print("Error")
                }
            }
            
        })
    }
}


extension NewRouteView {
    var button: some View {
        VStack{
            Button(action: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.submitOrUpdateRoute(companyId:currentCompany.id)
                            VM.listOfCustomers = []
                            masterDataManager.selectedRouteBuilderTech = nil
                            masterDataManager.selectedRouteBuilderDay = nil
                            masterDataManager.reloadBuilderView = true
                            dismiss()
                        } catch {
                            print("Error")
                            print(error)
                        }
                    }
                }
            },label: {
                HStack{
                    Text(VM.recurringRoute == nil ? "Submit" : "Update")
                }
                .frame(maxWidth: .infinity)
                .modifier(SubmitButtonModifier())
            })
            .disabled(VM.isLoading)
            .opacity(VM.isLoading ? 0.6 : 1)
        }
    }
    var form: some View {
        VStack{
            //            Text("Change Recurring Service stop Id to be not based on day and tech ID")
            technical
            info
        }
        .padding(.horizontal,16)
        
    }
    
    var info: some View {
        VStack{
            
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
                    CustomerAndLocationPicker(dataService: dataService, customer: $VM.customer,location: $VM.location)
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
                                        if !UIDevice.isIPhone {
                                            Button(action: {
                                                VM.listOfRecurringStops.removeAll(where: {$0.id == location.id})
                                            }, label: {
                                                Image(systemName: "trash")
                                            })
                                        }
                                    }
                                }
                                .onDelete(perform: VM.removeRecurringstops)
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
                Picker("Tech", selection: $VM.techEntity) {
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
                Picker("Frequency", selection: $VM.standardFrequencyType) {
                    ForEach(LaborContractFrequency.allCases,id:\.self){
                        Text($0.rawValue).tag($0)
                    }
                }
                Spacer()
            }
        }
    }
}
