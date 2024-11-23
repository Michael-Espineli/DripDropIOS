//
//  LaborContractRecurringWorkPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/9/24.
//

import SwiftUI

struct LaborContractRecurringWorkPicker: View {
    //Init
    init(dataService:ProductionDataService,laborContractRecurringWork:Binding<LaborContractRecurringWork>){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        self._laborContractRecurringWork = laborContractRecurringWork
    }

    //Objects
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractViewModel

    @Binding var laborContractRecurringWork:LaborContractRecurringWork
    
    @State var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @State var serviceLocation:ServiceLocation = ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: "")
    
    @State var rateStr:String = "0"
    @State var perFrequencyTime:String = "1"

    @State var startDate:Date = Date()

    @State var showCustomerPicker:Bool = false
    @State var locationPicker:Bool = false
    @State var showTemplatePicker:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                form
                buttons
            }
            .padding(8)
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadLaborContractRecurringWorkPicker(companyId: currentCompany.id)
                    showCustomerPicker = true
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: rateStr, perform: { datum in
            if datum != "" {
                if let rate = Double(rateStr){
                    laborContractRecurringWork.rate = rate
                } else {
                    rateStr = "0"
                }
            }
        })
        .onChange(of: perFrequencyTime, perform: { datum in
            if datum != "" {
                if let rate = Int(perFrequencyTime){
                    laborContractRecurringWork.timesPerFrequency = rate
                } else {
                    perFrequencyTime = "1"
                }
            }
        })
        .onChange(of: VM.selectedJobTemplate, perform: { template in
            laborContractRecurringWork.jobTemplateId = template.id

        })
    }
}

//#Preview {
//    LaborContractRecurringWorkPicker()
//}
extension LaborContractRecurringWorkPicker {
    var form: some View {
        VStack{
            HStack{
                Text("Customer:")
                    .fontWeight(.bold)
                Spacer()

                Button(action: {
                    showCustomerPicker.toggle()
                }, label: {
                    if customer.id == "" {
                        Text("Pick Customer")
                            .modifier(AddButtonModifier())
                    } else {
                        Text("\(customer.firstName) \(customer.lastName)")
                            .modifier(AddButtonModifier())
                    }
                })
                .sheet(isPresented: $showCustomerPicker, onDismiss: {
                    if customer.id != "" {
                        laborContractRecurringWork.customerId = customer.id
                        laborContractRecurringWork.customerName = customer.firstName + " " + customer.lastName
                        
                        laborContractRecurringWork.serviceLocationId = serviceLocation.id
                        laborContractRecurringWork.serviceLocationName = serviceLocation.address.streetAddress
                    }
                }, content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $customer, location: $serviceLocation)
                    
                })
            }
            HStack{
                Text("Service Location:")
                    .fontWeight(.bold)
                Spacer()

                Button(action: {
                    locationPicker.toggle()
                }, label: {
                    if serviceLocation.id == "" {
                        Text("Pick Location")
                            .modifier(AddButtonModifier())
                    } else {
                        Text("\(serviceLocation.address.streetAddress)")
                            .modifier(AddButtonModifier())
                    }
                })
                .sheet(isPresented: $locationPicker, onDismiss: {
                    if serviceLocation.id != "" {
                        laborContractRecurringWork.serviceLocationId = serviceLocation.id
                        laborContractRecurringWork.serviceLocationName = serviceLocation.address.streetAddress
                    }
                }, content: {
                    ServiceLocationPicker(dataService: dataService, customerId: customer.id, location: $serviceLocation)
                    
                })
            }
            HStack{
                Text("Job Template:")
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    showTemplatePicker.toggle()
                }, label: {
                    if VM.selectedJobTemplate.id == "" {
                        Text("Select Job Type")
                            .modifier(AddButtonModifier())
                    } else {
                        Text("\(VM.selectedJobTemplate.name)")
                            .modifier(AddButtonModifier())
                    }
                })
                .sheet(isPresented: $showTemplatePicker, onDismiss: {
                    if VM.selectedJobTemplate.id != "" {
                        laborContractRecurringWork.jobTemplateId = VM.selectedJobTemplate.id
                        laborContractRecurringWork.jobTemplateName = VM.selectedJobTemplate.name
                    }
                }, content: {
                    JobTemplatePicker(dataService: dataService, jobTemplate: $VM.selectedJobTemplate)
                })
            }
            Divider()
            HStack{
                Text("Rate:")
                    .fontWeight(.semibold)
                Spacer()
            }
            HStack{
                HStack{
                    TextField(
                        "Rate",
                        text: $rateStr
                    )
                    .keyboardType(.decimalPad)
                    Button(action: {
                        rateStr = "0"
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(TextFieldModifier())
                .padding(.vertical,8)
                .padding(.trailing,8)
                VStack{
                    Button(action: {
                        if var rate = Double(rateStr){
                            rate += 1
                            rateStr = String(rate)
                        }
                    }, label: {
                        Image(systemName: "chevron.up.square.fill")
                            .modifier(SubmitButtonModifier())
                            .padding(3)
                    })
                    Button(action: {
                        if var rate = Double(rateStr){
                            rate -= 1
                            rateStr = String(rate)
                        }
                    }, label: {
                        Image(systemName: "chevron.down.square.fill")
                            .modifier(DismissButtonModifier())
                            .padding(3)
                    })
                }
                Picker("Labor Type", selection: $laborContractRecurringWork.laborType, content: {
                    Text("Hour").tag(RateSheetLaborType.hour)
                    Text("Job").tag(RateSheetLaborType.job)
                })
                .pickerStyle(.segmented)
            }
            Divider()
            HStack{
                Text("Frequency:")
                    .fontWeight(.semibold)
                Spacer()
            }
            HStack{
                HStack{
                    TextField(
                        "Frequency",
                        text: $perFrequencyTime
                    )
                    .keyboardType(.decimalPad)
                    Button(action: {
                        perFrequencyTime = "0"
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(TextFieldModifier())
                .padding(.vertical,8)
                .padding(.trailing,8)
                VStack{
                    Button(action: {
                        if var rate = Int(perFrequencyTime){
                            rate += 1
                            perFrequencyTime = String(rate)
                        }
                    }, label: {
                        Image(systemName: "chevron.up.square.fill")
                            .modifier(SubmitButtonModifier())
                            .padding(3)
                    })
                    Button(action: {
                        if var rate = Int(perFrequencyTime){
                            rate -= 1
                            perFrequencyTime = String(rate)
                        }
                    }, label: {
                        Image(systemName: "chevron.down.square.fill")
                            .modifier(DismissButtonModifier())
                            .padding(3)
                    })
                }
                Picker("Labor Type", selection: $laborContractRecurringWork.frequency, content: {
                    Text("Daily").tag(LaborContractFrequency.daily)
                    Text("Weekly").tag(LaborContractFrequency.weekly)
                    Text("Monthly").tag(LaborContractFrequency.monthly)
                    
                })
                .pickerStyle(.segmented)
            }
            
    
            HStack{
                Text("Offered Start Date:")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                    
                }
            }
        }

    }
    var buttons: some View {
        HStack{
            Button(action: {
                laborContractRecurringWork = LaborContractRecurringWork(
                    id: UUID().uuidString,
                    customerId: "",
                    customerName: "",
                    serviceLocationId: "",
                    serviceLocationName: "",
                    jobTemplateId: "",
                    jobTemplateName: "",
                    rate: 0,
                    laborType: .job,
                    frequency: .weekly,
                    timesPerFrequency: 1,
                    timesPerFrequencySetUp: 1,
                    routeSetUp: false,
                    recurringServiceStopIdList: []
                )
                
                customer = Customer(
                    id: "",
                    firstName: "",
                    lastName: "",
                    email: "",
                    billingAddress: Address(
                        streetAddress: "",
                        city: "",
                        state: "",
                        zip: "",
                        latitude: 0,
                        longitude: 0
                    ),
                    active: true,
                    displayAsCompany: false,
                    hireDate: Date(),
                    billingNotes: "",
                    linkedInviteId: UUID().uuidString
                )
                serviceLocation = ServiceLocation(
                    id: "",
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
                    mainContact: Contact(
                        id: "",
                        name: "",
                        phoneNumber: "",
                        email: ""
                    ),
                    bodiesOfWaterId: [],
                    rateType: "",
                    laborType: "",
                    chemicalCost: "",
                    laborCost: "",
                    rate: "",
                    customerId: "",
                    customerName: ""
                )
                
                VM.selectedJobTemplate = VM.weeklyCleaning
                rateStr = "0"
                startDate = Date()
            },
                   label: {
                Text("Clear")
                    .modifier(DismissButtonModifier())

            })
            Spacer()
            Button(action: {
                dismiss()
            }, label: {
                Text("Add")
                    .modifier(SubmitButtonModifier())
            })
        }
    }
}
