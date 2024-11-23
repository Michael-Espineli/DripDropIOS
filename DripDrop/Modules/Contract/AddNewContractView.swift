//
//  AddNewContractView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct AddNewContractView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var customerVM : CustomerViewModel
    @StateObject var contractVM : ContractViewModel

    init(dataService:any ProductionDataServiceProtocol,customer:Customer?){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))

        self.customer = customer
        
    }

    
    @State var customer:Customer? = nil

    @State var selectedCustomer:Customer = Customer(id: "",
                                            firstName: "",
                                            lastName: "",
                                            email: "",
                                            billingAddress: Address(streetAddress: "",
                                                                    city: "",
                                                                    state: "",
                                                                    zip: "0",
                                                                    latitude: 0,
                                                                    longitude: 0),
                                            active: false,
                                            displayAsCompany: false,
                                            hireDate: Date(),
                                            billingNotes: "",
                                                    linkedInviteId: UUID().uuidString)
    @State var listOfCustomers:[Customer] = []
    @State var customerSearch:String = ""

    @State var daysToAccept:String = "15"
    @State var rate:String = ""
    @State var laborRate:String = ""

    @State var rateType:String = "Per Month"
    @State var rateTypes:[String] = ["Per Month","Per Stop","Per Week"]

    @State var laborType:String = "Per Stop"
    @State var laborTypes:[String] = ["Per Stop","Per Week","Per Month"]

    @State var chemType:String = "With Chems"
    @State var chemTypes:[String] = ["With Chems","With Out Chems","Specific Chems"]

    @State var terms:String = ""
    @State var notes:String = ""

    @State var errorMessage = ""
    @State var showAlert = false
    @State var buttonDisabled = false

    var body: some View {
        VStack{
            ScrollView{
                HStack{
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Cancel")
                            .modifier(DismissButtonModifier())
                    })
                    Spacer()
                    button
                }
                .padding()
                form
                    .padding(.horizontal,16)
                button
            }
        }
        .task {
            if let receivedCustomer = customer {
                selectedCustomer = receivedCustomer
            } else {
                if let selected = masterDataManager.selectedCustomer {
                    selectedCustomer = selected
                }
            }
            if let company = masterDataManager.currentCompany {
                do{
                    try await customerVM.getAllCustomers(companyId: company.id)
                    listOfCustomers = customerVM.customers
                } catch{
                    
                }
            }
        }
        .alert(errorMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            if let selectedCus = cus {
                selectedCustomer = selectedCus

            }
        })
        .onChange(of: customerSearch, perform: { search in
            if search == "" {
                listOfCustomers = customerVM.customers
            } else {
                customerVM.filterCustomerList(filterTerm: search, customers: customerVM.customers)
                listOfCustomers = customerVM.filteredCustomers
                if listOfCustomers.count != 0 {
                    selectedCustomer = listOfCustomers.first!
                }
            }
        })
    
        .onChange(of: terms, perform: { datum in
            let customerName = selectedCustomer.firstName + " " + selectedCustomer.lastName
            contractVM.checkContractForm(customerId: selectedCustomer.id, customerName: customerName, terms: datum, notes: notes , rate: rate,laborRate: laborRate)
        })
        .onChange(of: notes, perform: { datum in
            let customerName = selectedCustomer.firstName + " " + selectedCustomer.lastName
            contractVM.checkContractForm(customerId: selectedCustomer.id, customerName: customerName, terms: terms, notes: datum, rate: rate,laborRate: laborRate)
        })
        .onChange(of: selectedCustomer, perform: { datum in
            let customerName = datum.firstName + " " + selectedCustomer.lastName
            contractVM.checkContractForm(customerId: datum.id, customerName: customerName, terms: terms, notes: notes, rate: rate,laborRate: laborRate)
        })
        .onChange(of: rate, perform: { datum in
            let customerName = selectedCustomer.firstName + " " + selectedCustomer.lastName
            contractVM.checkContractForm(customerId: selectedCustomer.id, customerName: customerName, terms: terms, notes: notes, rate: datum,laborRate: laborRate)
            if !datum.isNumber {
                rate = "150"

            }
         
        })
        .onChange(of: laborRate, perform: { datum in
            let customerName = selectedCustomer.firstName + " " + selectedCustomer.lastName
            contractVM.checkContractForm(customerId: selectedCustomer.id, customerName: customerName, terms: terms, notes: notes, rate: rate,laborRate: datum)
            if !datum.isNumber {
                laborRate = "15"

            }
        })
    }
    
}
extension AddNewContractView {
    var button: some View {
        HStack{
            Button(action: {
                Task{
                    guard let pushRate = Double(rate) else {
                        errorMessage = "Rate is not Number"
                        print(errorMessage)
                        showAlert = true
                        return
                    }
                    guard let pushLaborRate = Double(laborRate) else {
                        errorMessage = "Labor Rate is not Number"
                        print(errorMessage)
                        showAlert = true
                        return
                    }
                    guard let pushDaysToAccept = Int(daysToAccept) else {
                        errorMessage = "Days To Accept is not Number"
                        print(errorMessage)
                        showAlert = true
                        return
                    }
                    let calendar = Calendar.current
                    guard let dateToAccept = calendar.date(byAdding: .day, value: pushDaysToAccept, to: Date()) else {
                        errorMessage = "Error Converting Time to Date"
                        print(errorMessage)
                        showAlert = true
                        return
                    }
                    
                    let fullName = selectedCustomer.firstName + " " + selectedCustomer.lastName
                    print("Uploading Contract For \(fullName) - \(selectedCustomer.id)")
                    try await contractVM.uploadContract(companyId: masterDataManager.currentCompany!.id, contract: Contract(id: UUID().uuidString, customerName: fullName, customerId: selectedCustomer.id, dateSent: Date(), dateToAccept: dateToAccept, status: .pending, locations: 1, rate: pushRate, rateType: rateType,laborRate:pushLaborRate, laborType: laborType, chemType: chemType, terms: terms, notes: notes))
                    dismiss()
                }
            }, label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())
            })
            .opacity(contractVM.formDisabled ? 0.75 : 1)
            .disabled(contractVM.formDisabled)
        }
    }
    var form: some View {
        VStack{
            VStack{
                HStack{
                    VStack{
                        HStack{
                            Text("Selected Customer:")
                                .font(.footnote)
                            Spacer()
                        }
                        HStack{
                            Text("\(selectedCustomer.firstName) \(selectedCustomer.lastName)")
                            Spacer()
                        }
                    }
                    HStack{
                        Button(action: {
                            customerSearch = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                        TextField(
                            "Customer Search",
                            text: $customerSearch
                        )
                    }
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                    Spacer()
                    Picker("Customer", selection: $selectedCustomer) {
    //                    Text("Pick Customer")
                        ForEach(listOfCustomers){ customer in
                            Text("\(customer.firstName) \(customer.lastName)").tag(customer)
                        }
                    }
                }
                HStack{
                    Text("Rate Type:")
                    Picker("rateType", selection: $rateType) {
                        //                    Text("Pick Customer")
                        ForEach(rateTypes,id:\.self){
                            Text($0).tag($0)
                        }
                    }
                    Spacer()
                    Text("Rate:")
                    TextField(
                        "Rate",
                        text: $rate
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                    Picker("Rate", selection: $rate) {
                        //                    Text("Pick Customer")
                        ForEach(1...100,id: \.self){
                            let number = 5 * $0
                            Text(String(number)).tag(String(number))
                        }
                    }
                    .pickerStyle(.wheel)
                    Spacer()
                }
                HStack{
                    Text("Labor Type:")
                    Picker("laborType", selection: $laborType) {
                        //                    Text("Pick Customer")
                        ForEach(laborTypes,id:\.self){
                            Text($0).tag($0)
                        }
                    }
                    Spacer()
                    Text("Labor Rate: ")
                    TextField(
                        "Labor Rate",
                        text: $laborRate
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                    Picker("Labor Rate", selection: $laborRate) {
                        ForEach(1...100,id: \.self){
                            let number = $0
                            Text(String(number)).tag(String(number))
                        }
                    }
                    .pickerStyle(.wheel)
                }
                HStack{
                    Text("Chem Type:")
                    Picker("Chem Type", selection: $chemType) {
                        ForEach(chemTypes,id:\.self){
                            Text($0).tag($0)
                        }
                        
                    }
                    Spacer()
                }
                HStack{
                    Text("Days To Accept: ")
                    Picker("Days To Accept", selection: $daysToAccept) {
                        //                    Text("Pick Customer")
                        ForEach(1...100,id: \.self){
                            Text(String($0)).tag(String($0))
                        }
                    }
                    Spacer()
                }
            }
            VStack{
                HStack{
                    Text("Terms:")
                    TextField(
                        "Terms",
                        text: $terms
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                    Spacer()
                }
                HStack{
                    Text("Notes:")
                    TextField(
                        "Notes",
                        text: $notes
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                }
            }
        }
    }
}

