//
//  BusinessDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BusinessDetailView: View {
    init( dataService:any ProductionDataServiceProtocol,business:AssociatedBusiness){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
        _business = State(wrappedValue: business)
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : BuisnessViewModel
    
    @State var business:AssociatedBusiness
    @State var showNewContract:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders,.sectionFooters], content: {
                    Section(content: {
                        detail
                    }, header: {
                            header
                        
                        .padding(8)
                        .background(Color.darkGray)
                        .foregroundColor(Color.poolWhite)
                    },footer: {
                        complaints
                    })
                })
                .clipped()
            }
            Text("")
                .sheet(isPresented: $showNewContract, onDismiss: {
                    Task{
                        if let selectedCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.getWorkContracts(companyId: selectedCompany.id,associatedBusinessCompanyId:business.companyId)
                            } catch {
                                print("Error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    AddNewLaborContractFromAssociatedBusiness(dataService: dataService, associatedBusiness: business,isPresented: $showNewContract,isFullScreen: true)
                })
        }
        .fontDesign(.monospaced)
        .navigationTitle(business.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadBusinessDetailView(companyId: selectedCompany.id,associatedBusinessCompanyId:business.companyId)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
        .toolbar {
            NavigationLink(destination: {
                Text("Create Update Logic Maybe Check if the person is the owner of the business.")
            }, label: {
                Text("Update")
            })
        }
        .onChange(of: masterDataManager.selectedBuisness, perform: { datum in
            Task{
                if let datum  = datum, let selectedCompany = masterDataManager.currentCompany {
                    business = datum
                    do {
                        try await VM.onLoadBusinessDetailView(companyId : selectedCompany.id , associatedBusinessCompanyId : datum.companyId)
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }
        })
    }
}

#Preview {
    BusinessDetailView(dataService: MockDataService(), business: AssociatedBusiness(companyId: "", companyName: ""))
}

extension BusinessDetailView {
    var header: some View {
        VStack{
            saveButton
            businessInfo
        }
        .frame(maxWidth: .infinity)
    }
    var businessInfo: some View {
        HStack{
            VStack{
                if let owner = VM.owner {
                    HStack{
                        Text("Owner:")
                            .fontWeight(.bold)
                            Text("\(owner.firstName)")
                        
                            Text("\(owner.lastName)")
                        
                        Spacer()
                    }
                }
                if let company = VM.company {
                    HStack{
                        Text(company.verified ? "Verified" : "")
                        Image(systemName: company.verified ? "checkmark.circle" : "")
                        Spacer()
                    }
                    .foregroundColor(company.verified ? Color.poolGreen : Color.poolRed)
                    .padding(8)
                    .background(company.verified ? Color.poolWhite : Color.clear)
                    .cornerRadius(8)
                    HStack{
                        Text("Phone number:")
                            .fontWeight(.bold)

                        Text("\(company.phoneNumber)")
                        
                        Spacer()
                    }
                    HStack{
                        Text("Email:")
                            .fontWeight(.bold)

                        Text("\(company.email)")
                        
                        Spacer()
                    }
                    .lineLimit(1)
                }
               
            }
            VStack{
                HStack{
                    
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "message.fill")
                            .modifier(AddButtonModifier())
                    })
                }
                HStack{
                    
                }
                Spacer()
            }
        }
    }
    var saveButton: some View {
        HStack{
            Spacer()
            Button(action: {
                Task{
                    if let selectedCompany = masterDataManager.currentCompany {
                        do {
                            if VM.buisnessList.contains(where: {$0.id == business.id}) {
                                print("Business List Contains Company")
                                try await VM.deleteAssociatedBusinessToCompany(
                                    companyId: selectedCompany.id,
                                    businessId: business.id
                                )
                                
                            } else {
                                print("Business List Does Not Contains Company")
                                
                                try await VM.saveAssociatedBusinessToCompany(
                                    companyId: selectedCompany.id,
                                    business: business
                                )
                            }
                            try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                            
                        } catch {
                            print("error")
                            print(error)
                        }
                    }
                }
            },
                   label: {
                if VM.buisnessList.contains(where: {$0.id == business.id}) {
                    Image(systemName: "heart.fill")
                        .modifier(AddButtonModifier())
                } else {
                    Image(systemName: "heart")
                        .modifier(AddButtonModifier())
                }
            })
        }
    }
    var detail: some View {
        VStack{
            HStack{
                Text("Out Standing: $ 2,765.50")
                Spacer()
                NavigationLink(value: Route.compileInvoice(dataService: dataService), label: {
                    Text("Send Invoice")
                        .modifier(BasicButtonModifier())
                    
                })
            }
            
            Rectangle()
                .frame(height: 1)
           sentContracts
            receivedContracts
   
        }
        .padding(.horizontal,8)
        .frame(maxWidth: .infinity)
    }
    var sentContracts: some View {
        VStack{
            HStack{
                Text("Sent Contracts")
                    .font(.headline)
                Text("\(VM.sentContracts.count)")

                Spacer()
                Button(action: {
                    showNewContract.toggle()
                }, label: {
                    Text("Send New Contract")
                        .modifier(AddButtonModifier())
                })
           
            }
            Divider()
            ForEach(VM.sentContracts){ contract in
                VStack{
                    HStack{
                        Spacer()
                        if UIDevice.isIPhone{
                            NavigationLink(value: Route.recurringLaborContractDetailView(contract: contract, dataService: dataService), label: {
                                Text("See Details")
                                Image(systemName: "arrow.right")
                            })
                            .foregroundColor(Color.red)
                            
                        } else {
                            NavigationLink(value: Route.recurringLaborContractDetailView(contract: contract, dataService: dataService), label: {
                                Text("See Details")
                                Image(systemName: "arrow.right")
                            })
                            .foregroundColor(Color.red)
                        }
                    }
                    LaborContractMediumCardView(laborContract: contract)
                }
                Divider()
            }
            Rectangle()
                .frame(height: 1)
        }
    }
    var receivedContracts: some View {
        VStack{
            HStack{
                Text("Received Contracts")
                    .font(.headline)
                Text("\(VM.receivedContracts.count)")
                Spacer()
            }
            Divider()
          
            ForEach(VM.receivedContracts){ contract in
                VStack{
                    HStack{
                        Spacer()
                        if UIDevice.isIPhone{
                            NavigationLink(value: Route.recurringLaborContractDetailView(contract: contract, dataService: dataService), label: {
                                Text("See Details")
                                Image(systemName: "arrow.right")
                            })
                            .foregroundColor(Color.red)
                            
                        } else {
                            NavigationLink(value: Route.recurringLaborContractDetailView(contract: contract, dataService: dataService), label: {
                                Text("See Details")
                                Image(systemName: "arrow.right")
                            })
                            .foregroundColor(Color.red)
                        }
                    }
                    LaborContractMediumCardView(laborContract: contract)
                }
Divider()
            }
            
            Rectangle()
                .frame(height: 1)
        }
    }

    var complaints: some View {
        HStack{
            Spacer()
                     NavigationLink(destination: {
                         Text("Create Complaint Logic")
                     }, label: {
                         Text("File Complaint")
                             .modifier(DismissButtonModifier())
                     })
            Spacer()
        }
        .padding(.horizontal,16)
    }
}
