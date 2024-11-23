//
//  ContractListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI

struct ContractListView: View {
    
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var contractVM : ContractViewModel
    init(dataService:any  ProductionDataServiceProtocol) {
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
    }
    @State var searchTerm : String = ""
    @State var showSearch : Bool = false
    @State var showFilters : Bool = false
    @State var showAddNewContract : Bool = false
    @State var priceFilter : String = ""
    @State var dateFilter : String = ""
    @State var status : String = "All"
    @State var filteredList:[Contract] = []
    var body: some View {
        ZStack{
            if searchTerm == "" {
                list
            } else {
                filteredContractList
            }
            icons
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await contractVM.getAllContracts(companyId: company.id)
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: searchTerm, perform: { term in
            if term != "" {
                contractVM.filterContractList(list: contractVM.listOfContrats, filterTerm: term)
                filteredList = contractVM.filteredContractList
            }
        })
    }
}

extension ContractListView{
var list: some View {
    ScrollView{
        ForEach(contractVM.listOfContrats){ contract in
            HStack{
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.contract(contract: contract,dataService: dataService), label: {
                        ContractCardView(contract: contract)
                    })
                } else {
                    Button(action: {
                        
                    }, label: {
                        ContractCardView(contract: contract)
                        
                    })
                }
            }
            .padding(.horizontal,8)
            .padding(.vertical,3)
            Divider()
        }
    }
}
    var filteredContractList: some View {
        ScrollView{
            ForEach(filteredList){ contract in
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.contract(contract: contract,dataService: dataService), label: {
                        ContractCardView(contract: contract)
                    })
                } else {
                    Button(action: {
                        
                    }, label: {
                        ContractCardView(contract: contract)

                    })
                }
                Divider()
            }
        }
    }
    var icons: some View{
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        showFilters.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color.white)
                            )
                        }
                    })
                    .padding(10)
                    .sheet(isPresented: $showFilters, content: {
                        VStack{
                            HStack{
                                
                                Picker("Date Filter", selection: $status) {
                                    Text("Pending").tag("Pending")
                                    Text("Pending").tag("Pending")
                                    Text("Pending").tag("Pending")

                                }
                                Picker("Price Filter", selection: $priceFilter) {
                                    Text("Low to High").tag("Low to High")
                                    Text("High to Low").tag("High to Low")
                                }
                                Picker("Date Filter", selection: $dateFilter) {
                                    Text("Oldest To Newest").tag("Oldest To Newest")
                                    Text("Newest To Oldest").tag("Newest To Oldest")
                                }
                            }
                            Spacer()
                        }
                        .padding()
                    })
                            Button(action: {
                                showAddNewContract.toggle()
                            }, label: {
                                ZStack{
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.green)
                                }
                            })
                            .padding(10)
                            .sheet(isPresented: $showAddNewContract, content: {
                                AddNewContractView(dataService: dataService,customer: nil)
                            })
                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                        }
                    })
                    .padding(10)
                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
                        text: $searchTerm
                    )
                    
                    Button(action: {
                        searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(SearchTextFieldModifier())
                .padding(8)
            }
            
        }

    }

}
