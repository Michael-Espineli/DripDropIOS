//
//  ReceiptListView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI

struct ReceiptListView: View{
    //VMS
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var receiptVM = ReceiptViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel(dataService: ProductionDataService())
    @EnvironmentObject var dataService:ProductionDataService
    //Variables Received
    @State var showSignInView:Bool = false
    @State var user:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    //Variables
    @State private var showEditView : Bool = false
    @State private var showDetailsView : Bool = false
    
    
    
    @State var startViewingDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    
    @State var endViewingDate: Date =  Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    @State var viewBillable = true
    @State var viewNonBillable = true
    @State var viewInvoiced = true
    @State var viewNoneInvoiced = true
    @State var showSummary = false
    @State var showFilerOptions = false
    
    @State var showAddNew = false
    @State var showSearch = false
    
    @State var searchTerm:String = ""
    
    @State var receiptList:[Receipt] = []
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView(showsIndicators: false){
                    ForEach(receiptList) { item in
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.receipt(receipt: item, dataService: dataService), label: {
                                ReceiptCardViewSmall(receipt: item)
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedReceipt = item
                            }, label: {
                                ReceiptCardViewSmall(receipt: item)
                            })
                        }
                        Divider()
                    }
                }
                .textSelection(.enabled)
            }
            .padding(10)
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    VStack{
                        if UIDevice.isIPhone {
                            Button(action: {
                                showAddNew.toggle()
                            }, label: {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.green)
                            })
                            .padding(8)

                        }
                        Button(action: {
                            showSearch.toggle()
                        }, label: {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                            
                        })
                        .padding(8)
                        
                    }
                    .sheet(isPresented: $showAddNew, content: {
                        AddNewReceipt(dataService: dataService)
                    })
                }
                if showSearch {
                    HStack{
                        TextField(
                            "Customer Name",
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
        .navigationTitle("Receipts")
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                receiptList = receiptVM.receiptItems
            } else {
                receiptVM.filterReceipts(filter: term, purchases: receiptVM.receiptItems)
                receiptList = receiptVM.filteredReceipts
            }
        }
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await receiptVM.getAllReceipts(companyId: company.id)
                    receiptList = receiptVM.receiptItems
                } catch {
                    print(error)
                }
            }
        }
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    showAddNew.toggle()
                }, label: {
                    Text("Add")
                })
            })
        }
    }
    
}
