//
//  ContractEndView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import SwiftUI

struct ContractEndView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @State private var contract : RecurringContract
    @StateObject private var customerVM : CustomerViewModel
    @StateObject var contractVM : ContractViewModel

    init(dataService:any  ProductionDataServiceProtocol,contract:RecurringContract){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
        _contract = State(wrappedValue: contract)
    }
    
    @State var customer:Customer? = nil

    @State var selectedCustomer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
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

    @State var daysToAccept:String = "15"
    @State var rate:String = ""
    @State var rateType:String = "Per Month"
    @State var rateTypes:[String] = ["Per Month","Per Stop","Per Week"]
    
    @State var laborRate:String = ""
    @State var laborType:String = "Per Stop"
    @State var laborTypes:[String] = ["Per Stop","Per Week","Per Month"]

    @State var chemType:String = "With Chems"
    @State var chemTypes:[String] = ["With Chems","With Out Chems","Specific Chems"]

    @State var terms:String = ""
    @State var notes:String = ""

    @State var nextView:String = ""
    @State var reason:String = ""
    @State var deleteConfirmation:Bool = false
    @State var confirmDeleteAndRepalce:Bool = false
    @State var showAlert:Bool = false

    @State var alertMessage:String = ""
    
    var body: some View {
        VStack{
            ScrollView{
                edit
                if nextView == "Remove Contract" {
                    removeContract
                } else if nextView == "Add Another" {
                    removeAndAddAnother
                } else {
                    Text("Please Select One")
                }
            }
        }
        .alert(isPresented: $deleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $confirmDeleteAndRepalce) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
    }
}

extension ContractEndView {
    var edit: some View {
        VStack{
            Text("Contract Holder : \(contract.internalCustomerName)")
            HStack{
                Button(action: {
                    nextView = "Remove Contract"
                }, label: {
                    Text("Remove Contract")
                })
                .padding(5)
                .background(Color.red)
                .cornerRadius(5)
                .padding(5)
                .foregroundColor(Color.basicFontText)
                Button(action: {
                    nextView = "Add Another"

                }, label: {
                    Text("Remove Contract And Add Another")
                })
                .padding(5)
                .background(Color.green)
                .cornerRadius(5)
                .padding(5)
                .foregroundColor(Color.white)
            }
        }
    }
    var removeContract: some View {
        VStack{
            Text("remove Contract")
       
            TextField("Reason: ",
                      text: $reason,
                      prompt: Text("Reason"))
            Button(action: {
                alertMessage = "Please Confirm you want to Make Contract invalid"
                deleteConfirmation.toggle()
            }, label: {
                Text("Delete")
                    .padding(5)
                    .background(Color.red)
                    .cornerRadius(5)
                    .padding(5)
                    .foregroundColor(Color.basicFontText)
            })
        }
    }
    var removeAndAddAnother: some View {
        VStack{
            Text("remove And Add Another")
            addNewContractView
            button
        }
    }
    var addNewContractView: some View {
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
                    Text("Labor Rate")
                    TextField(
                        "Labor Rate",
                        text: $laborRate
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
                    Text("days To Accept")
                    Picker("Days To Accept", selection: $daysToAccept) {
                        //                    Text("Pick Customer")
                        ForEach(1...100,id: \.self){
                            Text(String($0)).tag(String($0))
                        }
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
    var button: some View {
        HStack{
            Text("Button Disabled until I add the correct Logic of ending the previous contract and adding this one at the same time")
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany {
                        guard let pushRate = Double(rate) else {
                            alertMessage = "Rate is not Number"
                            print(alertMessage)
                            showAlert = true
                            return
                        }
                        guard let pushLaborRate = Double(laborRate) else {
                            alertMessage = "Labor Rate is not Number"
                            print(alertMessage)
                            showAlert = true
                            return
                        }
                        
                        guard let pushDaysToAccept = Int(daysToAccept) else {
                            alertMessage = "Days To Accept is not Number"
                            print(alertMessage)
                            showAlert = true
                            return
                        }
                        let calendar = Calendar.current
                        guard let dateToAccept = calendar.date(byAdding: .day, value: pushDaysToAccept, to: Date()) else {
                            alertMessage = "Error Converting Time to Date"
                            print(alertMessage)
                            showAlert = true
                            return
                        }
                        
                        let fullName = selectedCustomer.firstName + " " + selectedCustomer.lastName
                        //DEVELOPER FIX
//                        try await contractVM.uploadContract(companyId: company.id, contract: Contract(id: UUID().uuidString, customerName: fullName, customerId: selectedCustomer.id, dateSent: Date(), dateToAccept: dateToAccept, status: .pending, locations: 1, rate: pushRate, rateType: rateType, laborRate: pushLaborRate, laborType: laborType, chemType: chemType, terms: terms, notes: notes))
                    }
                }
            }, label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())

            })
            .disabled(true)
        }
    }

}
