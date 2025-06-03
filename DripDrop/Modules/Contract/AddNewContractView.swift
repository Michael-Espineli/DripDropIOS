    //
    //  AddNewContractView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 12/23/23.
    //

import SwiftUI

struct AddNewContractView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var VM : AddNewContractViewModel
    
    init(dataService:any ProductionDataServiceProtocol,customer:Customer?){
        _VM = StateObject(wrappedValue: AddNewContractViewModel(dataService: dataService))
        self.customer = customer
    }
    
    @State var customer:Customer? = nil
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                HStack{
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Cancel")
                            .modifier(DismissButtonModifier())
                    })
                    .disabled(VM.isLoading)
                    Spacer()
                    button
                }
                .padding(.vertical,8)
                form
                HStack{
                    button
                    Spacer()
                    saveAsDraft
                }
                
            }
            .padding(.horizontal,8)
            if VM.isLoading {
                VStack{
                    ProgressView()
                    Text("Loading ...")
                }
                .padding(8)
                .background(Color.gray.opacity(0.75))
                .cornerRadius(8)
            }
        }
        .task {
            //To check if you are creating a contract from a Customer or not from a selected Customer
            if let receivedCustomer = customer {
                VM.selectedCustomer = receivedCustomer
            } else {
                if let selected = masterDataManager.selectedCustomer {
                    VM.selectedCustomer = selected
                }
            }
            if let company = masterDataManager.currentCompany {
                do{
                    try await VM.onLoad(companyId: company.id)
                } catch{
                    print(error)
                }
            }
        }
        .alert(VM.errorMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            if let selectedCus = cus {
                VM.selectedCustomer = selectedCus
            }
        })
        .onChange(of: VM.customerSearchTerm, perform: { search in
            VM.filterCustomerList()
        })
        .onChange(of: VM.terms, perform: { datum in
            VM.checkContractForm()
        })
        .onChange(of: VM.internalNotes, perform: { datum in
            VM.checkContractForm()
        })
        .onChange(of: VM.externalNotes, perform: { datum in
            VM.checkContractForm()
        })
        .onChange(of: VM.selectedCustomer, perform: { datum in
            VM.checkContractForm()
        })
        .onChange(of: VM.rate, perform: { datum in
            VM.checkContractForm()
            if datum != "" {
                if let number = Double(datum) {
                    print("Is Number")
                    print(number)
                    let cents = number*100
                    print(cents)
                    print(Int(cents))
                } else {
                    VM.rate = String(datum.dropLast())
                    
                }
            }
        })
        .onChange(of: VM.laborRate, perform: { datum in
            VM.checkContractForm()
            if datum != "" {
                if let number = Double(datum) {
                    print("Is Number")
                    print(number)
                    let cents = number*100
                    print(cents)
                    print(Int(cents))
                } else {
                    VM.laborRate = String(datum.dropLast())
                }
            }
        })
        .onChange(of: VM.repairMax, perform: { datum in
            VM.checkContractForm()
            if datum != "" {
                if let number = Double(datum) {
                    print("Is Number")
                    print(number)
                    let cents = number*100
                    print(cents)
                    print(Int(cents))
                } else {
                    VM.repairMax = String(datum.dropLast())
                }
            }
        })
    }
}
extension AddNewContractView {
    var button: some View {
        HStack{
            Button(action: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.uploadContractWithValidation(companyId: currentCompany.id)
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
            .opacity(VM.formDisabled ? 0.75 : 1)
            .disabled(VM.formDisabled)
        }
    }
    var saveAsDraft: some View {
        HStack{
            Button(action: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            VM.status = .draft
                            try await VM.uploadContractWithValidation(companyId: currentCompany.id)
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                }
            },
               label: {
            Text("Save Draft")
                .modifier(AddButtonModifier())
            })
            .opacity(VM.formDisabled ? 0.75 : 1)
            .disabled(VM.formDisabled)
        }
    }
    var form: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Selected Customer:")
                    .lineLimit(1, reservesSpace: true)
                Spacer()
                Button(action: {
                    VM.presentNewCustomer.toggle()
                }, label: {
                    Image(systemName: "gobackward")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $VM.presentNewCustomer,
                       onDismiss: {
                },
                       content: {
                    CustomerPickerScreen(
                        dataService: dataService,
                        customer: $VM.selectedCustomer
                    )
                })
            }
            HStack{
                Text("\(VM.selectedCustomer.firstName) \(VM.selectedCustomer.lastName)")
                Spacer()
            }
            VStack(alignment: .leading){
                Text("Customer Facing")
                    .font(.headline)
                HStack{
                    VStack{
                        HStack{
                            Text("Rate Type")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                VM.showWheels.toggle()
                            }, label: {
                                if VM.showWheels {
                                    Image(systemName: "chevron.left")

                                } else {
                                    Image(systemName: "chevron.right")
                                }
                            })
                        }
                        Picker("Rate Type", selection: $VM.rateType) {
                            ForEach(RecurringContractRateType.allCases,id:\.self){
                                Text($0.rawValue).tag($0)
                            }
                            
                        }
                        HStack{
                            Text("Rate:")
                            HStack{
                                Text("$")
                                TextField(
                                    "Rate",
                                    text: $VM.rate
                                )
                            }
                            .padding(5)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                        }
                    }
                    if VM.showWheels {
                        
                        Picker("Rate", selection: $VM.rate) {
                                //                    Text("Pick Customer")
                            ForEach(1...100,id: \.self){
                                let number = 5 * $0
                                Text(String(number)).tag(String(number))
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                HStack{
                    Text("Cleaning Type:")
                    
                    Picker("Cleaning Type", selection: $VM.cleaningType) {
                            //                    Text("Pick Customer")
                        ForEach(RecurringContractCleaningPlan.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                    }
                }
                HStack{
                    Text("Chem Type:")
                    
                    Picker("Chem Type", selection: $VM.chemType) {
                            //                    Text("Pick Customer")
                        ForEach(RecurringContractChemType.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                        
                    }
                }
                HStack{
                    Text("Repair Type:")
                    
                    Picker("Repair Type", selection: $VM.repairType) {
                            //                    Text("Pick Customer")
                        ForEach(BillingType.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                        
                    }
                }
                if VM.repairType == .included {
                    HStack{
                        Text("Included Up Until : ")
                        HStack{
                            Text("$")
                            TextField(
                                "Max Amount",
                                text: $VM.repairMax
                            )
                        }
                        .padding(5)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(5)
                    }
                }
                HStack{
                    Text("Filter Type:")
                    
                    Picker("Filter Type", selection: $VM.filterType) {
                            //                    Text("Pick Customer")
                        ForEach(BillingType.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                        
                    }
                }
                HStack{
                    DatePicker(selection: $VM.dateToAccept, displayedComponents: .date) {
                        Text("Date To Accept: ")
                    }
                }
                HStack{
                    Text("Days To Accept: ")
                    Picker("Days To Accept", selection: $VM.daysToAccept) {
                            //                    Text("Pick Customer")
                        ForEach(1...100,id: \.self){
                            Text(String($0)).tag(String($0))
                        }
                    }
                    Spacer()
                }
                HStack{
                    Text("External Notes: ")
                    TextField(
                        "External Notes",
                        text: $VM.externalNotes
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                }
            }
            Rectangle()
                .fill(Color.basicFontText)
                .frame(height: 1)
            
            VStack(alignment: .leading){
                Text("Internal")
                    .font(.headline)
                HStack{
                    VStack{
                        HStack{
                            Text("Labor Type")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                VM.showWheels.toggle()
                            }, label: {
                                if VM.showWheels {
                                    Image(systemName: "chevron.left")

                                } else {
                                    Image(systemName: "chevron.right")
                                }
                            })
                        }
                        Picker("Labor Type", selection: $VM.laborType) {
                            ForEach(RecurringContractLaborType.allCases,id:\.self){
                                Text($0.rawValue).tag($0)
                            }
                        }
                        HStack{
                            Text("Labor Rate: ")
                            HStack{
                                Text("$")
                                TextField(
                                    "Labor Rate",
                                    text: $VM.laborRate
                                )
                            }
                            .padding(5)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                        }
                    }
                    if VM.showWheels {
                        Picker("Labor Rate", selection: $VM.laborRate) {
                            ForEach(1...100,id: \.self){
                                let number = $0
                                Text(String(number)).tag(String(number))
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                HStack{
                    Text("Internal Notes: ")
                    TextField(
                        "Internal Notes",
                        text: $VM.internalNotes
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                }
            }
        }
        
    }
}

