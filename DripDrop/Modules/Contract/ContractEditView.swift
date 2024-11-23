//
//  ContractEditView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct ContractEditView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var customerVM : CustomerViewModel
    @StateObject var contractVM : ContractViewModel
    @State var contract: Contract?

    init(dataService:any ProductionDataServiceProtocol,contract:Contract?){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
        _contract = State(wrappedValue: contract)
        
    }

    @State var selectedCustomer:Customer = Customer(
        id: "",
        firstName: "Ron",
        lastName: "Palace",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        active: false,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @State var listOfCustomers:[Customer] = []
    @State var customerSearch:String = ""

    @State var dateToAccept:Date = Date()
    @State var startDate:Date = Date()

    @State var rate:String = ""
    @State var rateType:String = "Per Month"
    @State var rateTypes:[String] = ["Per Month","Per Stop","Per Week"]

    @State var laborType:String = "Per Stop"
    @State var laborTypes:[String] = ["Per Stop","Per Week","Per Month"]

    @State var chemType:String = "With Chems"
    @State var chemTypes:[String] = ["With Chems","With Out Chems","Specific Chems"]

    @State var terms:String = ""
    @State var notes:String = ""
    @State var status:LaborContractStatus = .pending
    @State var statusList = ["Pending","Accepted"]
    
    @State var errorMessage = ""
    @State var showAlert = false
    var body: some View {
        VStack{
            ScrollView{
                HStack{
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Cancel")
                    })
                    Spacer()
                    button
                }
                .padding()
                form
                    .padding(20)
                button
            }
        }
        .onAppear(perform: {
            if let contract = contract {
                dateToAccept = contract.dateToAccept
                rate = String(contract.rate)
                rateType = contract.rateType
                laborType = contract.laborType
                chemType = contract.chemType
                terms = contract.terms
                notes = contract.notes
                status = contract.status
            }
        })
        .alert(errorMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
extension ContractEditView {
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
        
                    
                    let fullName = selectedCustomer.firstName + " " + selectedCustomer.lastName
                    if let company = masterDataManager.currentCompany {
                        if let contract = contract {
                            
                            try await contractVM.updateContractWithValidation(companyId: company.id, contract: contract, dateToAccept: dateToAccept, status: status, locations: 0, rate: 0, rateType: rateType, laborType: laborType, chemType: chemType, terms: terms, notes: notes, startDate: startDate, endDate: nil)
                            
                            dismiss()
                        }
                    }
                }
            }, label: {
                Text("Save")
                    .modifier(SubmitButtonModifier())

            })
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
                            Text("\(contract?.customerName ?? "")")
                            Spacer()
                        }
                    }
                
                }

                Text("Status: ")
                    .font(.footnote)
                Picker("Status", selection: $status) {
                    ForEach(statusList,id:\.self){
                        Text($0).tag($0)
                    }
                }
                HStack{
                    Text("Start Date: ")
                    DatePicker(selection: $startDate, displayedComponents: .date) {
                    }
                }
                HStack{
                    Text("Rate")
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
                }
                HStack{
                    Text("Rate Type:")

                    Picker("rateType", selection: $rateType) {
                        //                    Text("Pick Customer")
                        ForEach(rateTypes,id:\.self){
                            Text($0).tag($0)
                        }
                    }
                }
                HStack{
                    Text("Labor Type:")

                    Picker("laborType", selection: $laborType) {
                        //                    Text("Pick Customer")
                        ForEach(laborTypes,id:\.self){
                            Text($0).tag($0)
                        }
                        
                    }
                }
                HStack{
                    Text("Chem Type:")

                    Picker("chemType", selection: $chemType) {
                        //                    Text("Pick Customer")
                        ForEach(chemTypes,id:\.self){
                            Text($0).tag($0)
                        }
                        
                    }
                }
                HStack{
                    DatePicker(selection: $dateToAccept, displayedComponents: .date) {
                        Text("Date To Accept: ")
                    }
                }
            }
            VStack{
                HStack{
                    Text("terms")
                    TextField(
                        "terms",
                        text: $terms
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                }
                HStack{
                    Text("notes")
                    TextField(
                        "notes",
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

