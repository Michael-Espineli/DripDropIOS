//
//  CustomerBillingView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct CustomerBillingView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var contractVM : ContractViewModel
    @State var customer:Customer? = nil
    
    init(dataService: any ProductionDataServiceProtocol,customer:Customer) {
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
        self.customer = customer
    }
    @State private var billingNotes = ""
    @State private var contractTotal: Double = 0
    

    var body: some View {
        ScrollView{
            if UIDevice.isIPhone {
                iphone
            } else {
                largeScreen
            }
        }
            .onAppear(perform: {
                //Initialize Billing Notes On Load
                billingNotes = customer?.billingNotes ?? ""
            })
        .toolbar{
            ToolbarItem(content: {
                if let selectedCustomer = masterDataManager.selectedCustomer {
                    NavigationLink(destination: {
                        AddNewContractView(dataService: dataService,customer: selectedCustomer)
                    }, label: {
                        Text("Add New Contract")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                    })
                }
            })
        }
        
        .task{
                if let company = masterDataManager.selectedCompany,let customer = masterDataManager.selectedCustomer {
                    do {
                        print("Get Contractacts For Customer Id: \(customer.id)")
                        try await contractVM.getContractsByCustomer(companyId: company.id, customerId: customer.id)
                        print("Successfully Got Contracts")
                        contractTotal = contractVM.totalContracts(contracts: contractVM.listOfContrats)
                        print("Successfully Totaled Contracts")
                    } catch{
                        print("No Contracts")
                    }
                }
       
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            print("Selected Customer Changed \(cus?.firstName)")
            Task{
                guard let selectedCustomer = cus else {
                    print("Error For Change in Customer With New Valid Selected Customer ")
                    return
                }
                
                if let company = masterDataManager.selectedCompany {
                    do {
                        print("Get Contractacts For Customer Id: \(selectedCustomer.id)")
                        try await contractVM.getContractsByCustomer(companyId: company.id, customerId: selectedCustomer.id)
                        print("Successfully Got Contracts")
                        contractTotal = contractVM.totalContracts(contracts: contractVM.listOfContrats)
                        print("Successfully Totaled Contracts")
                    } catch{
                        print("No Contracts")
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
          
                    contracts
                
            
        }
    }
    var largeScreen: some View {
        VStack{
            HStack{
                VStack{
                    billingInfoLarge
                }
                VStack{
                    contracts
                }
            }
        }
    }
    var billingInfoSmall: some View {
        VStack{
            VStack{
                Text("Billing Notes:")
                TextEditor(text: $billingNotes)
                    .padding(5)
                    .background(Color.poolBlue.opacity(0.2))
                    .cornerRadius(5.0)
                    .frame(width: 200, height: 100)
                    .padding()
            }
            Text("Last Raised: 03/14/2024")
            Text("")
            Spacer()
        }
    }
    var billingInfoLarge: some View {
        VStack{
            VStack{
                Text("Billing Notes:")
                TextEditor(text: $billingNotes)
                    .padding(5)
                    .background(Color.poolBlue.opacity(0.2))
                    .cornerRadius(5.0)
                    .frame(width: 400, height: 200)
                    .padding()
            }
            Text("Last Raised: 03/14/2024")
            Text("")
            Spacer()
        }
    }
    var contracts: some View {
        VStack{
            ScrollView(showsIndicators: false){
                HStack{
                    Spacer()
                    Text("Contracts - \(contractVM.listOfContrats.count)")
                        .font(.headline)
                    
                    Spacer()
                    Button(action: {
                        
                    }, label: {
                        Text("See Old Contracts")
                    })
                }
                .padding()
                HStack{
                    Text("Contract Total: \(contractTotal, format: .currency(code: "USD").precision(.fractionLength(0)))")
                }
                ForEach(contractVM.listOfContrats){ contract in
                    HStack{
                        ContractCardView(contract: contract)
                        Button(action: {
                            masterDataManager.selectedCategory = .contract
                            masterDataManager.selectedID = contract.id
                        }, label: {
                            Text("See Details")
                                .foregroundColor(Color.basicFontText)
                                .padding(5)
                                .background(Color.accentColor)
                                .cornerRadius(5)
                        })
                    }
                }
            }
        }
    }
}
