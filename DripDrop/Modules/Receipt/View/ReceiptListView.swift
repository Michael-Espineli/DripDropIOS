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
    @StateObject private var settingsViewModel = SettingsViewModel()
    //Variables Received
    @State var showSignInView:Bool = false
    @State var user:DBUser = DBUser(id: "",exp: 0)
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
            VStack{
                ScrollView(showsIndicators: false){
                    ForEach(receiptList) { item in
                        NavigationLink(destination: {
                            ZStack{
                                
#if os(iOS)
                                ReceiptDetailView(receipt: item, showSignInView: $showSignInView, user: user, company: masterDataManager.selectedCompany!)
#endif
#if os(macOS)
                                MacReceiptDetailView(receipt: item, showSignInView: $showSignInView, user: user)
#endif
                            }
                        }, label: {
                            ReceiptCardViewSmall(receipt: item)
                        })
                    }
                }
                .textSelection(.enabled)
            }
            .padding(10)
            VStack{
                Spacer()
                HStack{
                    VStack{
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.green)
                        })
                        .sheet(isPresented: $showAddNew, content: {
                            AddNewReceipt()
                        })
                        .padding()
                        Button(action: {
                            showSearch.toggle()
                        }, label: {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                            
                        })
                        .padding()
                        
                    }
                    Spacer()
                }
                if showSearch {
                    HStack{
                        TextField(
                            "CustomerName",
                            text: $searchTerm
                        )
                        .padding()
                        .background(Color.basicFontText.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                receiptList = receiptVM.receiptItems
            } else {
                receiptVM.filterReceipts(filter: term, purchases: receiptVM.receiptItems)
                receiptList = receiptVM.filteredReceipts
            }
        }
        .task{
            try? await receiptVM.getAllReceipts(companyId: masterDataManager.selectedCompany!.id)
            receiptList = receiptVM.receiptItems
        }
    }
    
}
