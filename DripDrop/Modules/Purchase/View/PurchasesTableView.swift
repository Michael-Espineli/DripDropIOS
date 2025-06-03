//
//  PurchasesTableView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/2/23.
//
/*
import SwiftUI

struct purchasesTableView: View{
    init(dataService:any ProductionDataServiceProtocol){
        _purchaseVM = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))

    }
    @StateObject var purchaseVM : PurchasesViewModel
    @StateObject private var receiptViewModel = ReceiptViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager

    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company
    
    @State private var showEditView : Bool = false
    @State private var showDetailsView : Bool = false
    
    @State private var selected: PurchasedItem.ID?
    @State private var purchasedItems:[PurchasedItem] = []
    @State private var sortOrder = [KeyPathComparator(\PurchasedItem.invoiceNum, order: .reverse)]
    @State private var serviceStopDetail: PurchasedItem? = nil
    
    @State var workOrderTemplate:JobTemplate = JobTemplate(id: "", name: "",type: "all")
    
    @State var startViewingDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    
    @State var endViewingDate: Date =  Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    @State private var selection: PurchasedItem.ID? = nil
    @State var viewBillable = true
    @State var viewNonBillable = true
    @State var viewInvoiced = true
    @State var viewNoneInvoiced = true
    
    @State var searchTerm:String = ""


    var body: some View{
        ZStack{
            VStack{
                HStack{
                    Button(action: {
                        Task{
                            viewBillable = true
                            viewNonBillable = true
                            viewInvoiced = true
                            viewNoneInvoiced = true
                            try? await purchaseVM.getallPurchasesLast30Days(companyId: company.id, startDate: startViewingDate, endDate: endViewingDate, viewBillable: viewBillable)

                                purchasedItems = purchaseVM.purchasedItems
    
                        }
                    }, label: {
                        Image(systemName: "gobackward")
                    })
                    Spacer()

                    Text("Total Items Purchased")
                    ZStack{
                        Text("000.00")
                            .foregroundColor(Color.clear)
                        Text(String(format:"%.2f",(purchaseVM.itemsPurchasedBillable ?? 0) + (purchaseVM.itemsPurchased ?? 0)))
                    }

                    Text("Total Spent")
                    ZStack{
                        Text("$00000.00")
                            .foregroundColor(Color.clear)
                        let totalSpent = (purchaseVM.totalSpentBillable ?? 0) + (purchaseVM.totalSpent ?? 0)
                        Text(totalSpent, format: .currency(code: "USD").precision(.fractionLength(0)))
                    }                }
                HStack{
                    Text("Start Date")
                    DatePicker(selection: $startViewingDate, displayedComponents: .date) {
                    }
                    Text("End Date")

                    DatePicker(selection: $endViewingDate, displayedComponents: .date) {
                    }
                }
                HStack{
                    Toggle(isOn: $viewNonBillable, label: {
                        Text("View NonBillable")
                    })
                    Spacer()
                    Text("Total Items Purchased")
                    ZStack{
                        Text("000.00")
                            .foregroundColor(Color.clear)
                        Text(String(format:"%.2f",purchaseVM.itemsPurchased ?? 0))

                    }
                    Text("Total Spent")
                    ZStack{
                        Text("$00000.00")
                            .foregroundColor(Color.clear)
                        let totalSpent = (purchaseVM.totalSpent ?? 0)
                        Text(totalSpent, format: .currency(code: "USD").precision(.fractionLength(0)))

                    }
                }
                HStack{

                Toggle(isOn: $viewBillable, label: {
                    Text("View Billable")
                })
                    if viewBillable && !viewNonBillable {
                        Toggle(isOn: $viewInvoiced, label: {
                            Text("View Invoiced")
                        })
                        Toggle(isOn: $viewNoneInvoiced, label: {
                            Text("View Non Invoiced")
                        })
                    }
                    Spacer()
                    Text("Total Items Purchased")
                    ZStack{
                        Text("000.00")
                            .foregroundColor(Color.clear)
                        Text(String(format:"%.2f",purchaseVM.itemsPurchasedBillable ?? 0))
                    }

                    Text("Total Spent")
                    ZStack{
                        Text("$00000.00")
                            .foregroundColor(Color.clear)
                        let totalSpent = (purchaseVM.totalSpentBillable ?? 0)
                        Text(totalSpent, format: .currency(code: "USD").precision(.fractionLength(0)))

                    }

                }
                HStack{
                    Button(action: {
                        if searchTerm == "" {
                            purchasedItems = purchaseVM.purchasedItems
                        } else {
                            purchaseVM.filterPurchaseList(filterTerm: searchTerm, purchasedItems: purchaseVM.purchasedItems)
                                purchasedItems = purchaseVM.filteredPurchasedItems
                        }
                    }, label: {
                        Image(systemName: "magnifyingglass")
                    })
                    TextField(
                        "Search Term",
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
                Table(of:PurchasedItem.self ,selection:$selection, sortOrder: $sortOrder){
                    TableColumn("Date"){
                        Text(dayMonth(date:$0.date))
                    }
                    .width(min: 25, ideal: 30, max: 50)
                    TableColumn("invoiceNum", value: \.invoiceNum)
                        .width(min: 25, ideal: 30, max: 60)
                    TableColumn("Tech"){
                        Text($0.techName)
                    }
                    .width(min: 25, ideal: 75, max: 100)
                    //
                    //                    TableColumn("Store Name"){
                    //                        Text($0.storeName)
                    //                    }
                    //                    .width(min: 25, ideal: 50, max: 75)
                    TableColumn("Item"){
                        Text($0.name )
                    }
                    .width(min: 45, ideal: 50, max: 125)
                    TableColumn("Sku"){
                        Text($0.sku)
                    }
                    .width(min: 25, ideal: 50, max: 75)
                    TableColumn("WO ID"){
                        Text($0.jobId)
                    }
                    .width(min: 25, ideal: 50, max: 75)
                    //                    TableColumn("price"){
                    //                        Text(String($0.price ))
                    //                    }
                    //                    .width(min: 25, ideal: 50, max: 75)
                                        TableColumn("Quantity"){
                                            Text($0.quantityString )
                                        }
                    .width(min: 25, ideal: 50, max: 75)
                    TableColumn("Total"){
                        Text($0.total , format: .currency(code: "USD").precision(.fractionLength(2)))
                    }
                    .width(min: 25, ideal: 50, max: 75)
                    //                    TableColumn("Billable"){
                    //                        Text($0.billable.description.capitalized)
                    //                    }
                    //                    .width(min: 25, ideal: 40, max: 50)
                    TableColumn("Invoiced"){
                        Text($0.invoiced.description.capitalized)
                    }
                    .width(min: 25, ideal: 40, max: 50)
                    
                    TableColumn("Customer"){
                        if $0.billable {
                            Text($0.customerName)
                            
                        } else {
                            Text("N/A")
                            
                        }
                    }
                    .width(min: 25, ideal: 40, max: 100)
                    
                } rows: {
                    ForEach(purchasedItems) { items in
                        TableRow(items)
                            .contextMenu {
                                Button(action: {

                                }, label: {
                                    Image(systemName: "pencil")
                                        .modifier(EditButtonTextModifier())
                                })
                                .modifier(EditButtonModifier())
                                
                                Button("See Details") {
                                    //                                    showDetailsView = true
                                    
                                }
                                Divider()
                                
                                Button("Delete", role: .destructive) {
                                    //                                            delete(customer)
                                }
                            }
                    }

                }
                    .textSelection(.enabled)

            }
            .padding(10)
            if showEditView {
                Color.basicFontText
                VStack{
                    Text("Edit View")
                }
            }
            if showDetailsView {
                Color.basicFontText
                VStack{
                    Text("Detail View")
                }
            }
        }
        
            .onChange(of: purchasedItems){ purchasedItemsList in
                purchaseVM.summaryOfPurchasedItems(purchasedItems: purchasedItemsList)
            }
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                purchasedItems = purchaseVM.purchasedItems
            } else {
                     purchaseVM.filterPurchaseList(filterTerm: term, purchasedItems: purchaseVM.purchasedItems)
                    purchasedItems = purchaseVM.filteredPurchasedItems
            }
        }
        .task{
            try? await purchaseVM.getallPurchasesLast30Days(companyId: company.id, startDate: startViewingDate, endDate: endViewingDate, viewBillable: viewBillable)
            purchasedItems = purchaseVM.purchasedItems
            
        }
        .onChange(of: endViewingDate) { selected in
            Task{
                try? await purchaseVM.getallPurchasesLast30Days(companyId: company.id, startDate: startViewingDate, endDate: selected, viewBillable: viewBillable)
                if viewBillable && viewNonBillable {
                    purchasedItems = purchaseVM.purchasedItems
                } else if viewBillable {
                    purchaseVM.filterReceiptListByBillable(billable: true, purchasedItems:  purchaseVM.purchasedItems)
                    purchasedItems = purchaseVM.purchasedItem2
                } else if viewNonBillable {
                    purchaseVM.filterReceiptListByBillable(billable: false, purchasedItems:  purchaseVM.purchasedItems)
                    purchasedItems = purchaseVM.purchasedItem2
                } else {
                    purchasedItems = []
                }
            }
        }
        .onChange(of: startViewingDate) { selected in
            Task{
                try? await purchaseVM.getallPurchasesLast30Days(companyId: company.id, startDate: selected, endDate: endViewingDate, viewBillable: viewBillable)
                if viewBillable && viewNonBillable {
                    purchasedItems = purchaseVM.purchasedItems
                } else if viewBillable {
                    purchaseVM.filterReceiptListByBillable(billable: true, purchasedItems:  purchaseVM.purchasedItems)
                    purchasedItems = purchaseVM.purchasedItem2
                } else if viewNonBillable {
                    purchaseVM.filterReceiptListByBillable(billable: false, purchasedItems:  purchaseVM.purchasedItems)
                    purchasedItems = purchaseVM.purchasedItem2
                } else {
                    purchasedItems = []
                }
            }
        }
        
        .onChange(of: viewInvoiced) { selected in
            if viewInvoiced && viewNoneInvoiced {
                purchaseVM.filterReceiptListByBillable(billable: true, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else if viewNoneInvoiced {
                purchaseVM.filterReceiptListByBillableAndInvoice(billable: true,invoiced:false, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else if viewNoneInvoiced {
                purchaseVM.filterReceiptListByBillableAndInvoice(billable: true,invoiced:false, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else {
                purchasedItems = []
            }
        }
        
        .onChange(of: viewNoneInvoiced) { selected in
            if viewInvoiced && viewNoneInvoiced {
                purchaseVM.filterReceiptListByBillable(billable: true, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else if viewInvoiced {
                purchaseVM.filterReceiptListByBillableAndInvoice(billable: true,invoiced:true, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else if viewNoneInvoiced {
                purchaseVM.filterReceiptListByBillableAndInvoice(billable: true,invoiced:false, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else {
                purchasedItems = []
            }
        }
        
        .onChange(of: viewBillable) { selected in
            if viewBillable && viewNonBillable {
                    purchasedItems = purchaseVM.purchasedItems
            } else if viewNonBillable {
                purchaseVM.filterReceiptListByBillable(billable: false, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else if viewBillable {
                purchaseVM.filterReceiptListByBillable(billable: true, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else {
                purchasedItems = []
            }

        }
        
        .onChange(of: viewNonBillable) { selected in
            if viewBillable && viewNonBillable {
                    purchasedItems = purchaseVM.purchasedItems
            } else if viewNonBillable {
                purchaseVM.filterReceiptListByBillable(billable: false, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else if viewBillable {
                purchaseVM.filterReceiptListByBillable(billable: true, purchasedItems:  purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.purchasedItem2
            } else {
                purchasedItems = []
            }
        }
        
        .onChange(of: selection) { selected in
            print("selected Purchase")
            let purchasesObject = purchasedItems.filter{ $0.id == selected }.first
            masterDataManager.selectedPurchases = purchasesObject
            
        }
        .onChange(of: selected) { selected in
            print(selected)
            if selected != nil {
                showEditView = true
            }
        }
        .onChange(of: sortOrder) { newOrder in
            purchasedItems.sort(using: newOrder)
        }
        
        
    }
    
}
*/
