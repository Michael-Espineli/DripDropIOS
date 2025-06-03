//
//  OwesMoneyView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/30/25.
//


import SwiftUI
import MapKit
import Firebase
import Charts

struct OwesMoneyView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var VM : MyCompanyViewModel
    
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: MyCompanyViewModel(dataService: dataService))
    }

    @State var showOperations:Bool = false //DEVELOPER LATER MAKE THIS TRUE
    @State var showFinace:Bool = false //DEVELOPER LATER MAKE THIS TRUE
    @State var showManagement:Bool = false //DEVELOPER LATER MAKE THIS TRUE
    
    @State var isLoading: Bool = true
    
    @State var selectedSection: String = ""
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                VStack(alignment: .leading,spacing: 20){
                if let role = masterDataManager.role {
                        if role.permissionIdList.contains("13") {
                            
                            //----------------------------------------
                            //Add Back in During Roll out of Phase 2
                            //----------------------------------------
//                            snapshot
                            finace
                        }
                    }
                }
                .padding(.horizontal,8)
            }
        }
        .onAppear(perform: {
            if !UIDevice.isIPhone {
                showOperations = true
                showFinace = true
                showManagement = true
            }
        })
        .task{
            if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: company.id, userId: user.id,category: "Finance")
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of:  masterDataManager.currentCompany, perform: { selectedCompany in
            Task{
                if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                    do {
                        try await VM.onLoad(companyId: company.id, userId: user.id, category: "Finance")
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.isLoading, perform: { loading in
            if loading {
                isLoading = loading
                
            } else {
                withAnimation(Animation.linear(duration: 0.1)) {
                    isLoading = loading
                }
            }
        })
    }
}

extension OwesMoneyView{
    var quickAccess: some View {
        ZStack{
            if let role = masterDataManager.role {
                VStack(alignment: .leading,spacing: 20){
                    if role.permissionIdList.contains("13") {
                        snapshot
                        finace
                    }
                }
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    
    var snapshot: some View {
        VStack{
            Chart(VM.buildActivities) { buildActivity in
                BarMark(
                    x: .value("Date", buildActivity.date, unit: .month),
                    y: .value("Total Count", buildActivity.numberOfUnits)
                )
                /// Show a different color for each scheme
                .foregroundStyle(
                    by: .value("Name", buildActivity.name)
                )
//                /// Show bars side by side
//                .position(
//                    by: .value("Scheme", buildActivity.name),
//                    axis: .horizontal,
//                    span: .ratio(1)
//                )
            }
            /// Customize the colors for each scheme
            .chartForegroundStyleScale([
                "Jobs" : .blue,
                "Monthly Service": .green,
                "Items Purchased": .red,
                "Labor": .orange

            ])
        }
    }

    var finace: some View {
        VStack{
            HStack{
                Text("Sales")
                Spacer()
            }
            .modifier(HeaderModifier())
            Text("Need to figure out Invoice to and from clients and buisnesses")
                .background(Color.pink)
            finishedJobs
            Divider()
            contracts
            Divider()
            recurringContracts
            Divider()
            invoices
            Divider()
            accountsReceivable
            Divider()
            receivedLaborContract
            Divider()
            receivedRecurringLaborContract
            Divider()
        }
    }
        
    
    var finishedJobs: some View {
        VStack{
            HStack{
                Text("Finished Jobs")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.billingJobs(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .jobs
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
                
            }
     
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        Text("Open: \(String(VM.openJobs ?? 0))")
                        Text("Recently Finished: \(String(VM.recentlyFinishedJobs ?? 0))")
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{

            if VM.jobs.count == 0 {
                HStack{
                    SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Jobs")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.jobs){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(
                                    job: datum,
                                    dataService: dataService
                                ), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.black,text: datum.id, iconName: "wrench.adjustable.fill")
                                    
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedJob = datum
                                    masterDataManager.selectedCategory = .jobs
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.black,text: datum.id, iconName: "wrench.adjustable.fill")
                                })
                            }
                        }
                    }
                    }
                }
            }
        }
    }
    var invoices: some View {
        VStack{
            HStack{
                Text("Invoices")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.invoices(
                        dataService: dataService
                    ), label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .purchases
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading){
                        HStack{
                            if let items = VM.itemsPurchased {
                                Text("Total Items:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalSpent {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            
                        }
                        HStack{
                            if let items = VM.itemsPurchasedBillable {
                                Text("Billable Items:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalSpentOnBillables {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                        }
                        HStack{
                            if let items = VM.itemsPurchasedAndBilled {
                                Text("Billed:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalBilled {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{

            if VM.purchasedItems.count == 0 {
                HStack{
                    SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Purchases")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.purchasedItems){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.purchase(
                                    purchasedItem: datum,
                                    dataService: dataService
                                ), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: datum.name, iconName: "cart.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedPurchases = datum
                                    masterDataManager.selectedCategory = .purchases
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: datum.name, iconName: "cart.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
        }
    }

    var purchases: some View {
        VStack{
            HStack{
                Text("Purchases")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.purchases(
                        dataService: dataService
                    ), label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .purchases
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading){
                        HStack{
                            if let items = VM.itemsPurchased {
                                Text("Total Items:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalSpent {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            
                        }
                        HStack{
                            if let items = VM.itemsPurchasedBillable {
                                Text("Billable Items:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalSpentOnBillables {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                        }
                        HStack{
                            if let items = VM.itemsPurchasedAndBilled {
                                Text("Billed:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalBilled {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{

            if VM.purchasedItems.count == 0 {
                HStack{
                    SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Purchases")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.purchasedItems){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.purchase(
                                    purchasedItem: datum,
                                    dataService: dataService
                                ), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: datum.name, iconName: "cart.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedPurchases = datum
                                    masterDataManager.selectedCategory = .purchases
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: datum.name, iconName: "cart.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
        }
    }
    
    var receipts: some View {
        VStack{
            HStack{
                Text("Receipts")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.receipts(
                        dataService: dataService
                    ), label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .receipts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading){
                        HStack{
                            if let items = VM.itemsPurchased {
                                Text("Total Items:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalSpent {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            
                        }
                        HStack{
                            if let items = VM.itemsPurchasedBillable {
                                Text("Billable Items:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalSpentOnBillables {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                        }
                        HStack{
                            if let items = VM.itemsPurchasedAndBilled {
                                Text("Billed:  \(String(format:  "%.0f", items))")
                            }
                            Spacer()
                            if let amount = VM.totalBilled {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {

            if VM.purchasedItems.count == 0 {
                HStack{
                    SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Purchases")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.purchasedItems){ datum in
                            
                            NavigationLink(value: Route.purchase(
                                purchasedItem: datum,
                                dataService: dataService
                            ), label: {
                                SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: datum.name, iconName: "cart.fill")
                            })
                        }
                    }
                }
            }
            }
        }
    }
    
  
    var accountsPayable: some View {
        VStack{
            HStack{
                Text("Accounts Payable")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                    .background(Color.pink)
                
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.accountsPayableList(
                        dataService: dataService
                    ), label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .accountsPayable
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading){
                        HStack{
                            if let items = VM.APOutstandingCount {
                                Text("Total Outstanding Invoices :  \(String(items))")
                            }
                            Spacer()
                            if let amount = VM.APTotal {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            
                        }
                        HStack{
                            if let items = VM.APOutstandingLateCount {
                                Text("Total Outstanding Late :  \(String(items))")
                            }
                            Spacer()
                            if let amount = VM.APTotalOutstandingLate {
                                Text("\(Double(amount)/100, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {

            if VM.APInvoiceList.count == 0 {
                HStack{
                    SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Invoice")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.APInvoiceList){ datum in
                            let title =  datum.senderName + " $" + String(datum.total/100)
                            if UIDevice.isIPhone {
                                NavigationLink(value:Route.accountsPayableDetail(invoice:datum, dataService:dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolRed,textColor: Color.white,text:title, iconName: "creditcard.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedAccountsPayableInvoice = datum
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolRed,textColor: Color.white,text:title, iconName: "creditcard.fill")
                                })
                            }
                        }
                    }
                }
                }
            }
        }
    }
    
    var accountsReceivable: some View {
        VStack{
            HStack{
                Text("Accounts Receivable")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                    .background(Color.pink)
                
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.accountsReceivableList(dataService: dataService), label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .accountsReceivable
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading){
                        HStack{
                            
                            if let items = VM.AROutstandingCount {
                                Text("Total Receivable Invoices :  \(String(items))")
                            }
                            Spacer()
                            if let amount = VM.ARTotal {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{

            if VM.ARInvoiceList.count == 0 {
                HStack{
                    SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Invoice")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.ARInvoiceList){ datum in
                            let title =  datum.senderName + " $" + String(datum.total/100)
                            if UIDevice.isIPhone {
                                NavigationLink(value:Route.accountsReceivableDetail(invoice:datum,dataService:dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: title, iconName: "creditcard.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedAccountsReceivableInvoice = datum
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: title, iconName: "creditcard.fill")
                                })
                            }
                        }
                    }
                }
            }
            }
        }
    }
    

    var contracts: some View {
        VStack{
            HStack{
                Text("Contracts")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                    .background(Color.pink)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.contracts(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                    
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .contracts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("Open Contracts:")
                            if let items = VM.contractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Pending Contracts:")
                            if let items = VM.pendingContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Total: $ 10,350.69")
                            if let amount = VM.contractTotal {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.contractList.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.teal, footer: Color.clear,textColor: Color.black,text: "No Contracts")
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.contractList){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.contract(contract: datum, dataService: dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.internalCustomerName, iconName: "car.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .contracts
                                        masterDataManager.selectedContract = datum
                                    }, label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.internalCustomerName, iconName: "car.fill")
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
 
    var recurringContracts: some View {
        VStack{
            HStack{
                Text("Recurring Contracts")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)

                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.recurringContracts(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                    
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .contracts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("Open Contracts:")
                            if let items = VM.contractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Pending Contracts:")
                            if let items = VM.pendingContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Total: $ 10,350.69")
                            if let amount = VM.contractTotal {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.contractList.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.teal, footer: Color.clear,textColor: Color.black,text: "No Contracts")
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.contractList){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.contract(contract: datum, dataService: dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.internalCustomerName, iconName: "car.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .contracts
                                        masterDataManager.selectedContract = datum
                                    }, label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.internalCustomerName, iconName: "car.fill")
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var sentLaborContract: some View {
        VStack{
            HStack{
                Text("Sent Labor Contract")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.sentLaborContracts(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                    
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .sentLaborContracts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("Total Contracts:")
                            if let items = VM.sentAcceptedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Open Contracts:")
                            if let items = VM.sentAcceptedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Pending Contracts:")
                            if let items = VM.sentPendingLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Past Contracts:")
                            if let items = VM.sentPastLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sum Total: $ 10,350.69")
                            if let amount = VM.sentLaborContractTotal {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.laborContractList.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.teal, footer: Color.clear,textColor: Color.black,text: "Labor Contracts")
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.laborContractList){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.recurringLaborContractDetailView(contract: datum, dataService: dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .receivedLaborContracts
                                        masterDataManager.selectedRecurringLaborContract = datum
                                    }, label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var receivedLaborContract: some View {
        VStack{
            HStack{
                Text("Received Labor Contract")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)

                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.receivedLaborContracts(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                    
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .receivedLaborContracts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("Total Contracts:")
                            if let items = VM.receivedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Open Contracts:")
                            if let items = VM.receivedAcceptedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Pending Contracts:")
                            if let items = VM.receivedPendingLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Past Contracts:")
                            if let items = VM.receivedPastLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{

            if VM.laborContractList.count == 0 {
                HStack{
                    
                    SquareEmpty(color: Color.teal, footer: Color.clear,textColor: Color.black,text: "Labor Contracts")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.laborContractList){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.recurringLaborContractDetailView(contract: datum, dataService: dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .receivedLaborContracts
                                    masterDataManager.selectedRecurringLaborContract = datum
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                })
                            }
                        }
                    }
                }
            }
            }
        }
    }

    var sentRecurringLaborContract: some View {
        VStack{
            HStack{
                Text("Sent Recurring Labor Contract")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.sentRecurringLaborContracts(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                    
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .sentLaborContracts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("Total Contracts:")
                            if let items = VM.sentAcceptedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Open Contracts:")
                            if let items = VM.sentAcceptedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Pending Contracts:")
                            if let items = VM.sentPendingLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Past Contracts:")
                            if let items = VM.sentPastLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sum Total: $ 10,350.69")
                            if let amount = VM.sentLaborContractTotal {
                                Text("\(amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.laborContractList.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.teal, footer: Color.clear,textColor: Color.black,text: "Labor Contracts")
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.laborContractList){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.recurringLaborContractDetailView(contract: datum, dataService: dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .receivedLaborContracts
                                        masterDataManager.selectedRecurringLaborContract = datum
                                    }, label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var receivedRecurringLaborContract: some View {
        VStack{
            HStack{
                Text("Received Recurring Labor Contract")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)

                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.receivedRecurringLaborContracts(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                    
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .receivedLaborContracts
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .font(.footnote)
                        .padding(3)
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview  || masterDataManager.mainScreenDisplayType == .preview {
                
                HStack{
                    VStack{
                        Divider()
                            .frame(width: 200)
                    }
                    Spacer()
                }
                HStack{
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("Total Contracts:")
                            if let items = VM.receivedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Open Contracts:")
                            if let items = VM.receivedAcceptedLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Pending Contracts:")
                            if let items = VM.receivedPendingLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                        HStack{
                            Text("Sent Past Contracts:")
                            if let items = VM.receivedPastLaborContractCount {
                                Text("\(String(format:  "%.0f", items))")
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{

            if VM.laborContractList.count == 0 {
                HStack{
                    
                    SquareEmpty(color: Color.teal, footer: Color.clear,textColor: Color.black,text: "Labor Contracts")
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.laborContractList){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.recurringLaborContractDetailView(contract: datum, dataService: dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .receivedLaborContracts
                                    masterDataManager.selectedRecurringLaborContract = datum
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.senderName, iconName: "car.fill")
                                })
                            }
                        }
                    }
                }
            }
            }
        }
    }

}
