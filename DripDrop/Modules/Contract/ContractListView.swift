//
//  ContractListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import SwiftUI
@MainActor
final class ContractListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var listOfContrats:[RecurringContract] = []
    @Published var displayContracts:[RecurringContract] = []
    @Published var searchTerm : String = ""
    @Published var totalContracts : Int = 0
    @Published var totalYearlyContractAmount : Int = 0
    @Published var totalMonthlyContractAmount : Int = 0

    func onLoad(companyId:String) async throws {
        self.listOfContrats = try await dataService.getAllContrats(companyId: companyId)
        self.displayContracts = listOfContrats
        for contract in listOfContrats {
            self.totalMonthlyContractAmount = contract.rate + totalMonthlyContractAmount
        }
        self.totalYearlyContractAmount = totalMonthlyContractAmount*12
    }
    func filterContractList() {
        if searchTerm != "" {
            var contractList:[RecurringContract] = []
            for contract in listOfContrats {
                if contract.internalCustomerName.lowercased().contains(searchTerm.lowercased()) {
                    contractList.append(contract)
                }
            }
            self.displayContracts = contractList
        }
    }
}
struct ContractListView: View {
    
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : ContractListViewModel

    init(dataService:any  ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: ContractListViewModel(dataService: dataService))

    }
    @State var showInfo : Bool = false
    @State var showSearch : Bool = false
    @State var showFilters : Bool = false
    @State var showAddNewContract : Bool = false
    @State var priceFilter : String = ""
    @State var dateFilter : String = ""
    @State var status : String = "All"
    @State var filteredList:[RecurringContract] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            if VM.searchTerm == "" {
                list
            } else {
                filteredContractList
            }
            icons
        }
        .navigationTitle("Recurring Contracts")
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id)
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: VM.searchTerm, perform: { term in
            VM.filterContractList()
            
        })
    }
}

extension ContractListView{
var list: some View {
    ScrollView{
        ForEach(VM.listOfContrats){ contract in
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
                        showInfo.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                            Image(systemName: "info.circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color.white)
                            )
                        }
                    })
                    .padding(10)
                    .sheet(isPresented: $showInfo, content: {
                        VStack{
                            Text("Info")
                                .font(.headline)
                            HStack{
                                Text("Total Contracts : ")
                                Spacer()
                                Text("\(VM.totalContracts)")
                            }
                            HStack{
                                Text("Yearly Contract Billed : ")
                                Spacer()
                                Text("\(Double(VM.totalYearlyContractAmount)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            }
                            HStack{
                                Text("Monthly Contract Billed : ")
                                Spacer()
                                Text("\(Double(VM.totalMonthlyContractAmount)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            }
                            Text("Info")
                            Text("Info")

                        }
                        .padding(8)
                    })
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
                        .padding(8)
                        .presentationDetents([.fraction(0.4)])
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
                        text: $VM.searchTerm
                    )
                    Button(action: {
                        VM.searchTerm = ""
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
