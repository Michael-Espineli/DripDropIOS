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
    var contract:Contract
    init(dataService: any ProductionDataServiceProtocol,contract:Contract) {
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
        self.contract = contract
    }
    
    
    @State var errorMessage = ""
    @State var showAlert = false
    @State var showEditView = false
    @State var status:LaborContractStatus = .pending
    @State var statusList = ["Pending","Accepted"]
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
    var expiredInfo: some View{
        VStack{
            VStack{
                HStack{
                    Text("\(contract.customerName)")
                    Spacer()
                    
                    Text("Status: ")
                        .font(.footnote)
                    Text("\(status.rawValue)")
                }
                HStack{
                    Text("Start Date: ")
                        .font(.footnote)
                    if let startDate = contract.startDate {
                        
                        Text("\(fullDate(date: startDate))")
                    }
                    
                    Text("Expiration Date: ")
                        .font(.footnote)
                    if let endDate = contract.endDate {
                        Text("\(fullDate(date: endDate))")
                    }
                }
                
                
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
                    Text("\(contract.customerName)")
                    Spacer()
                    
                    Text("Status: ")
                        .font(.footnote)
                    Picker("Status", selection: $status) {
                        ForEach(statusList,id:\.self){
                            Text($0).tag($0)
                        }
                    }
                    .sheet(isPresented: $showPastContract, content: {
                        ContractEndView(dataService: dataService, contract: contract)
                        
                    })
                }
                if status == .accepted {
                    HStack{
                        Text("Date Accepted: ")
                            .font(.footnote)
                        if let date = contract.dateAccepted{
                            Text("\(fullDate(date: date))")
                        }
                        
                    }
                } else {
                    HStack{
                        Text("Date Sent: ")
                            .font(.footnote)
                        Text("\(fullDate(date: contract.dateSent))")
                        
                        Text("Expiration Date: ")
                            .font(.footnote)
                        Text("\(fullDate(date: contract.dateToAccept))")
                    }
                }
                
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
    var toolbar:some View{
        HStack{
            Button(action: {
                masterDataManager.selectedID = nil
                masterDataManager.selectedContract = nil
                dismiss()
            }, label: {
                Text("Dismiss")
                    .modifier(DismissButtonModifier())
                
            })
            .padding(5)
            Spacer()
            Button(action: {
                showEditView.toggle()
            }, label: {
                Text("Edit")
                    .foregroundColor(Color.reverseFontText)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
            })
            .padding(5)
            if status == .pending {
                Button(action: {
                    errorMessage = "Confirm Delete"
                    showAlert = true
                    //Add a check to see if they want to end or just delete it.
                }, label: {
                    Text("Delete")
                        .foregroundColor(Color.basicFontText)
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(5)
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
