//
//  CustomerBillingView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
@MainActor
final class CustomerBillingViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var listOfContrats:[RecurringContract] = []
    @Published private(set) var invoices:[StripeInvoice] = []

    @Published private(set) var total:Double = 0
    
    @Published var billingNotes = ""
    @Published var isPresented:Bool = false
    @Published var isPresentedOldContract:Bool = false
    
    func onLoad(companyId:String,customerId:String) async throws {
        self.listOfContrats = try await dataService.getContractsByCustomer(companyId: companyId, customerId: customerId)
        for contract in listOfContrats {
            self.total = total + Double(contract.rate)/100 // Convert Rate in cents into Dollars
        }
        self.invoices = [
            StripeInvoice(
                id: "",
                internalIdenifier: "",
                senderId: "",
                senderName: "",
                receiverId: "",
                receiverName: "",
                dateSent: Date(),
                total: 14700,
                terms: .net15,
                paymentStatus: .unpaid,
                paymentType: .check,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                ]
            ),
            StripeInvoice(
                id: "",
                internalIdenifier: "",
                senderId: "",
                senderName: "",
                receiverId: "",
                receiverName: "",
                dateSent: Date(),
                total: 500,
                terms: .net15,
                paymentStatus: .unpaid,
                paymentType: .check,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                ]
            )
        ]
    }
    func onChangeBillingNotes(companyId:String,customerId:String) async throws {
        try await dataService.updateCustomerBillingNotes(companyId: companyId, customerId: customerId, billingNotes: billingNotes)
        print("Update Billing Notes - \(billingNotes)")
    }
}
struct CustomerBillingView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var VM : CustomerBillingViewModel

    @State var customer:Customer? = nil
    
    init(dataService: any ProductionDataServiceProtocol,customer:Customer) {
        _VM = StateObject(wrappedValue: CustomerBillingViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
    }
    
    var body: some View {
        ScrollView{
            if UIDevice.isIPhone {
                iphone
            } else {
                largeScreen
            }
            Text("")
                .sheet(isPresented: $VM.isPresented,
                       onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            if let customer = masterDataManager.selectedCustomer {
                                do {
                                    print("Get Contractacts For Customer Id: \(customer.id)")
                                    try await VM.onLoad(companyId: company.id, customerId: customer.id)
                                    print("Successfully Got Contracts")
                                } catch{
                                    print("No Contracts")
                                    print(error)
                                }
                            } else {
                                if let customer = customer {
                                    do {
                                        print("Get Contractacts For Customer Id: \(customer.id)")
                                        try await VM.onLoad(companyId: company.id, customerId: customer.id)
                                        print("Successfully Got Contracts")
                                    } catch{
                                        print("No Contracts")
                                        print(error)
                                    }
                                } else {
                                    print("No Selected Customer")
                                }
                            }
                        }
                    }
                },
                       content: {
                    if let customer = customer {
                        AddNewContractView(
                            dataService: dataService,
                            customer: customer
                        )
                    } else {
                        if let selectedCustomer = masterDataManager.selectedCustomer {
                            AddNewContractView(
                                dataService: dataService,
                                customer: selectedCustomer
                            )
                        } else {
                            AddNewContractView(
                                dataService: dataService,
                                customer: nil
                            )
                        }
                    }
                })
            Text("")
                .sheet(isPresented: $VM.isPresentedOldContract, content: {
                    Text("Is Presented Old Contract")
                })
        }
        .task{
            VM.billingNotes = customer?.billingNotes ?? ""
            if let company = masterDataManager.currentCompany {
                if let customer = masterDataManager.selectedCustomer {
                    do {
                        print("Get Contractacts For Customer Id: \(customer.id)")
                        try await VM.onLoad(companyId: company.id, customerId: customer.id)
                        print("Successfully Got Contracts")
                    } catch{
                        print("No Contracts")
                        print(error)
                    }
                } else {
                    if let customer = customer {
                        do {
                            print("Get Contractacts For Customer Id: \(customer.id)")
                            try await VM.onLoad(companyId: company.id, customerId: customer.id)
                            print("Successfully Got Contracts")
                        } catch{
                            print("No Contracts")
                            print(error)
                        }
                    } else {
                        print("No Selected Customer")
                    }
                }
            }
            
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            Task{
                guard let selectedCustomer = cus else {
                    print("Error For Change in Customer With New Valid Selected Customer ")
                    return
                }
                print("Selected Customer Changed \(selectedCustomer.firstName)")

                VM.billingNotes = customer?.billingNotes ?? ""
                if let company = masterDataManager.currentCompany {
                    if let customer = masterDataManager.selectedCustomer {
                        do {
                            print("Get Contractacts For Customer Id: \(customer.id)")
                            try await VM.onLoad(companyId: company.id, customerId: customer.id)
                            print("Successfully Got Contracts")
                        } catch{
                            print("No Contracts")
                            print(error)
                        }
                    } else {
                        if let customer = customer {
                            do {
                                print("Get Contractacts For Customer Id: \(customer.id)")
                                try await VM.onLoad(companyId: company.id, customerId: customer.id)
                                print("Successfully Got Contracts")
                            } catch{
                                print("No Contracts")
                                print(error)
                            }
                        } else {
                            print("No Selected Customer")
                        }
                    }
                }
            }
        })
        .onChange(of: VM.billingNotes, perform: { notes in
            Task{
                if let currentCompany = masterDataManager.currentCompany {
                    if let customer = masterDataManager.selectedCustomer {
                        if customer.billingNotes != notes {
                            do {
                                try await VM.onChangeBillingNotes(companyId: currentCompany.id, customerId: customer.id)
                            } catch {
                                print(error)
                            }
                        }
                    } else {
                        if let customer = customer {
                            if customer.billingNotes != notes {
                                do {
                                    try await VM.onChangeBillingNotes(companyId: currentCompany.id, customerId: customer.id)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
}
extension CustomerBillingView {
    var iphone: some View {
        VStack(alignment: .leading){
            billingInfoSmall
            Rectangle()
                .frame(height: 1)
            billingStats
            Rectangle()
                .frame(height: 1)
            contracts
            Rectangle()
                .frame(height: 1)
            paymentHistory
            Rectangle()
                .frame(height: 1)
            outStandingInvoices
        }
    }
    var largeScreen: some View {
        VStack{
            HStack{
                billingInfoLarge
                billingStats
            }
            contracts
            Rectangle()
                .frame(height: 1)
            paymentHistory
            Rectangle()
                .frame(height: 1)
            outStandingInvoices
        }
        
    }
    var billingInfoSmall: some View {
        VStack{
            VStack{
                Text("Billing Notes:")
                TextField(
                    "",
                    text: $VM.billingNotes,
                    axis: .vertical
                )
                .padding(4)
                .padding(.horizontal,4)
                .background(Color.poolBlue.opacity(0.2))
                .cornerRadius(5.0)
                .padding(8)
            }
            Text("Last Raised: 03/14/2024")
        }
    }
    var billingInfoLarge: some View {
        VStack{
            VStack{
                Text("Billing Notes:")
                TextField(
                    "",
                    text: $VM.billingNotes,
                    axis: .vertical
                )
                .padding(5)
                .background(Color.poolBlue.opacity(0.2))
                .cornerRadius(5.0)
                .padding()
            }
            Text("Last Raised: 03/14/2024")
            Text("")
            Spacer()
        }
    }
    var billingStats: some View {
        VStack{
            HStack{
                Text("Total Outstanding : ")
                Spacer()
                Text("\(1001, format: .currency(code: "USD").precision(.fractionLength(2)))")
            }
            HStack{
                Text("Recently Paid (30 Days) : ")
                Spacer()
                Text("\(1200, format: .currency(code: "USD").precision(.fractionLength(2)))")

            }
            HStack{
                Text("Total Of Contracts : ")
                Spacer()
                Text("\(VM.listOfContrats.count)")

            }
            HStack{
                Text("Contract Total : ")
                Spacer()
                Text(" \(VM.total, format: .currency(code: "USD").precision(.fractionLength(2)))")

            }
            
        }
    }
    var contracts: some View {
        VStack{
            ScrollView(showsIndicators: false){
                
                HStack{
                    Spacer()
                    Text("Contracts")
                        .font(.headline)
                    
                    Spacer()
                    
                }
                HStack{
                    Button(action: {
                        VM.isPresented.toggle()
                    }, label: {
                        
                        Text("Add New")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                            .fontDesign(.monospaced)
                    })
                    Spacer()
                    Button(action: {
                        VM.isPresentedOldContract.toggle()
                    }, label: {
                        Text("See Past")
                            .foregroundColor(Color.poolRed)
                            .padding(3)
                    })
                }
                
                ForEach(VM.listOfContrats){ contract in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.contract(contract: contract, dataService: dataService), label: {
                            ContractCardView(contract: contract)
                        })
                    } else {
                        HStack{
                            ContractCardView(contract: contract)
                            Button(action: {
                                masterDataManager.selectedCategory = .contract
                                masterDataManager.selectedID = contract.id
                            }, label: {
                                Text("See More")
                                    .foregroundColor(Color.basicFontText)
                                    .padding(5)
                                    .background(Color.poolBlue)
                                    .cornerRadius(5)
                            })
                        }
                    }
                }
            }
        }
    }
    var outStandingInvoices: some View {
        VStack{
            HStack{
                Spacer()
                Text("Out Standing Invoices")
                    .font(.headline)
                Spacer()
                
            }
            HStack{
                Text("Description")
                Spacer()
                Text("Amount")
            }
            Divider()
            ForEach(VM.invoices){  invoice in
                HStack{
                    Text(fullDate(date: invoice.dateSent))
                    Text("Monthly Service")
                    Spacer()
                    Text("\(Double(invoice.total)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "chevron.right")
                    })
                }
                .padding(.vertical,4)
            }
        }
    }
    var paymentHistory: some View {
        VStack{
            HStack{
                Spacer()
                Text("Payment History")
                    .font(.headline)
                
                Spacer()
                
            }
        }
    }
}
