//
//  ContractDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct ContractDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var contractVM : ContractViewModel
    var contract:RecurringContract
    init(dataService: any ProductionDataServiceProtocol,contract:RecurringContract) {
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
        self.contract = contract
    }
    
    
    @State var errorMessage = ""
    @State var showAlert = false
    @State var showEditView = false
    @State var status:RecurringContractStatus = .pending
    @State var showPastContract:Bool = false
    var body: some View {
        ZStack{
            ScrollView{
                VStack{
                    toolbar
                    if status == .past {
                        expiredInfo
                    } else {
                        info
                        
                    }
                }
            }
        }
        .sheet(isPresented: $showEditView, content: {
            ContractEditView(dataService: dataService, contract: masterDataManager.selectedContract)
            
        })
        .alert(isPresented:$showAlert) {
            Alert(
                title: Text("Alert"),
                message: Text("\(errorMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            try await contractVM.deleteContract(companyId: company.id,contractId:contract.id)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .task {
            if let selectedContract = masterDataManager.selectedContract{
                status = selectedContract.status
            } else {
                status = contract.status
            }
        }
        .onChange(of: status, perform: { datum in
            if datum == .past {
                showPastContract = true
            }
        })
    }
}

extension ContractDetailView{
    var toolbar:some View{
        HStack{
            if !UIDevice.isIPhone {
                Button(action: {
                    masterDataManager.selectedID = nil
                    masterDataManager.selectedContract = nil
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .modifier(DismissButtonModifier())
                })
                .padding(5)
            }
            Spacer()
            Button(action: {
                showEditView.toggle()
            }, label: {
                Text("Edit")
                    .modifier(AddButtonModifier())
            })
            .padding(5)
        }
    }

    var expiredInfo: some View{
        VStack{
            VStack{
                    Text("\(contract.internalCustomerName)")
                    Spacer()
                    
                    Text("Status: ")
                    Text("\(status.rawValue)")
                    Text("Start Date: ")
                        .font(.footnote)
                    
                    Text("Expiration Date: ")
                        .font(.footnote)
            }
            VStack{
                HStack{
                    Text("Rate Type: ")
                        .font(.footnote)
                    Text("\(contract.rateType)")
                    Text("Rate: ")
                        .font(.footnote)
                    Text("\(contract.rate, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    Spacer()
                }
                HStack{
                    Text("Labor Type: ")
                        .font(.footnote)
                    Text("\(contract.laborType)")
                    Text("Labor Rate: ")
                        .font(.footnote)
                    Text("\(contract.laborRate, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    Spacer()
                }
                HStack{
                    Text("Chem Type: ")
                        .font(.footnote)
                    Text("\(contract.chemType)")
                    Spacer()
                }
                
            }
            
        }
        .padding(5)
        
        
    }
    var info: some View{
        VStack{
            VStack{
                HStack{
                    Text("\(contract.internalCustomerName)")
                    Spacer()
                    
                    Text("Status: ")
                        .font(.footnote)
                    Picker("Status", selection: $status) {
                        ForEach(RecurringContractStatus.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .sheet(isPresented: $showPastContract, content: {
                        ContractEndView(dataService: dataService, contract: contract)
                        
                    })
                }
                if status == .accepted {
                    HStack{
                        Text("Date Accepted: ")
                            .font(.headline)
                    }
                } else {
                    HStack{
                        Text("Date Sent: ")
                            .font(.headline)
                        Text("\(fullDate(date: contract.dateSent))")
                    }
                    HStack{
                        Text("Expiration Date: ")
                            .font(.headline)
                        Text("\(fullDate(date: contract.dateToAccept))")
                    }
                }
                
            }
            VStack{
                VStack(alignment: .leading){
                    
                    HStack{
                        Text("Rate Type: ")
                            .font(.headline)
                        Text("\(contract.rateType.rawValue)")
                        Text("Rate: ")
                            .font(.headline)
                        Text("\(Double(contract.rate)/100, format: .currency(code: "USD").precision(.fractionLength(0)))")
                        Spacer()
                    }
                    
                    HStack{
                        Text("Chem Type: ")
                            .font(.footnote)
                        Text("\(contract.chemType.rawValue)")
                        Spacer()
                    }
                    HStack{
                        Text("Repair Type: ")
                            .font(.footnote)
                        Text("\(contract.chemType.rawValue)")
                        Spacer()
                    }
                    HStack{
                        Text("Cleaning Type: ")
                            .font(.footnote)
                        Text("\(contract.cleaningPlan.rawValue)")
                        Spacer()
                    }
                    HStack{
                        Text("Filter Type: ")
                            .font(.footnote)
                        Text("\(contract.filterServiceType.rawValue)")
                        Spacer()
                    }
                    HStack{
                        Text("Repair Type: ")
                            .font(.footnote)
                        Text("\(contract.repairType.rawValue)")
                        Spacer()
                    }
                    if contract.repairType == .included {
                        HStack{
                            Text("Included Until : ")
                                .font(.footnote)
                            Text("\(Double(contract.repairAmountMax)/100, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            Spacer()
                        }
                    }
                    HStack{
                        Text("External Notes: ")
                            .font(.footnote)
                        Text("\(contract.externalNotes)")
                        Spacer()
                    }
                }
                Rectangle()
                    .frame(height:1)
                VStack(alignment: .leading){
                        HStack{
                            Text("Labor Type: ")
                                .font(.footnote)
                            Text("\(contract.laborType.rawValue)")
                            Spacer()
                        }
                        Text("Labor: ")
                            .font(.headline)
                        Text("\(Double(contract.laborRate)/100, format: .currency(code: "USD").precision(.fractionLength(0)))")
                        Spacer()
                    
                    HStack{
                        Text("Internal Notes: ")
                            .font(.footnote)
                        Text("\(contract.internalNotes)")
                        Spacer()
                    }
                }
                
            }
            
        }
        .padding(8)
    }
    var footer:some View{
        VStack(alignment:.center){
            if status == .pending || status == .draft{
                Button(action: {
                    errorMessage = "Confirm Delete"
                    showAlert = true
                }, label: {
                    Text("Delete")
                        .modifier(DismissButtonModifier())

                })
                .padding(5)
            } else if status == .accepted {
                Button(action: {
                    showPastContract.toggle()
                }, label: {
                    Text("End")
                        .foregroundColor(Color.basicFontText)
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(5)
                })
                .padding(5)
            }
        }
    }
}
