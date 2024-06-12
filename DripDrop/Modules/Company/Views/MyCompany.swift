//
//  MyCompany.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI
import MapKit
struct MyCompany: View {
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
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
   
                ScrollView(showsIndicators: false){
                    VStack(spacing: 20){
                        if isLoading {
                            overViewLoading
                        } else {
                            overView
                        }
                            quickAccess
                    }
                    .padding(.horizontal,8)
                }
            
        }
        .task{
            if let company = masterDataManager.selectedCompany,let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: company.id, userId: user.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of:  masterDataManager.selectedCompany, perform: { selectedCompany in
            Task{
                if let company = masterDataManager.selectedCompany,let user = masterDataManager.user {
                    do {
                        try await VM.onLoad(companyId: company.id, userId: user.id)
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

struct MyCompany_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    
    static var previews: some View {
        MyCompany(dataService:dataService )
    }
}
extension MyCompany{
    var overView: some View {
        VStack(spacing: 3){
            HStack{
                Text("Over View")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.white)
                Spacer()
                    NavigationLink(value: Route.chats(
                        dataService: dataService
                    ),label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            VStack(alignment: .leading){
                
                Text("Open Jobs: 8")
                chartStuff
            }
        }
        .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
        .background(Color.darkGray)
        .cornerRadius(10)
        .foregroundColor(Color.white)
        .fontDesign(.monospaced)
    }
    var overViewLoading: some View {
        VStack(spacing: 3){
            HStack{
                Text("Over View")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.clear)
                    .background(Color.poolWhite.opacity(0.5))
                    .cornerRadius(8)
                Spacer()
                
                HStack{
                    Text("More")
                    Image(systemName: "arrow.right")
                    
                }
                .foregroundColor(Color.clear)
                .background(Color.poolWhite.opacity(0.5))
                .cornerRadius(8)
            }
            VStack(alignment: .leading){
                
                Text("Open Jobs: 8")
                    .foregroundColor(Color.clear)
                    .background(Color.poolWhite.opacity(0.5))
                    .cornerRadius(8)
                chartStuff
            }
        }
        .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
        .background(Color.darkGray)
        .cornerRadius(10)
        .foregroundColor(Color.white)
        .fontDesign(.monospaced)
    }
    var chartStuff: some View {
        mockChart(numbers: [1,5,6,8,21,4,7,0,5,2,4,7,5,8,0,7,5,3,5,2,7,3,8,5,1])
    }
    var maps: some View {
        VStack{
            BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611))
        }
    }
    
    var quickAccess: some View {
        ZStack{
            if let role = masterDataManager.role {
                VStack(alignment: .leading,spacing: 20){
                    if role.permissionIdList.contains("11") {
                        operations
                    }
                    if role.permissionIdList.contains("7") {
                        
                        management
                    }
                    if role.permissionIdList.contains("13") {
                        
                        finace
                    }
                    settings
                }
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    var quickAccessLoading: some View {
        ZStack{
            VStack(alignment: .leading,spacing: 20){
                VStack{
                    
                    HStack{
                        Text("Operations")
                            .background(Color.poolWhite.opacity(0.5))
                            .foregroundColor(Color.clear)
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
                    .background(Color.darkGray.opacity(0.5))
                    .cornerRadius(8)
                    .foregroundColor(Color.white)
                    .fontDesign(.monospaced)
                    ForEach(1...2,id:\.self){ datum in
                        
                        VStack{
                            HStack{
                                Text("Jobs")
                                    .font(.headline)
                                    .fontDesign(.monospaced)
                                    .foregroundColor(Color.clear)
                                    .background(Color.basicFontText.opacity(0.5))
                                    .cornerRadius(8)
                                Spacer()
                                HStack{
                                    Text("More")
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(Color.clear)
                                .background(Color.basicFontText.opacity(0.5))
                                .cornerRadius(8)

                            }
                            Divider()
                            HStack{
                                VStack(alignment: .leading,spacing: 3){
                                    Text("Open: 8")
                                        .foregroundColor(Color.clear)
                                        .background(Color.basicFontText.opacity(0.5))
                                        .cornerRadius(8)
                                    Text("In Progress/Scheduled: 3")
                                        .foregroundColor(Color.clear)
                                        .background(Color.basicFontText.opacity(0.5))
                                        .cornerRadius(8)
                                    Text("Recently Finished: 3")
                                        .foregroundColor(Color.clear)
                                        .background(Color.basicFontText.opacity(0.5))
                                        .cornerRadius(8)
                                }
                                Spacer()
                            }
                            .fontDesign(.monospaced)
                            .font(.footnote)
                            .padding(.horizontal,20)

                            ScrollView(.horizontal) {
                                HStack{
                                    ForEach(1...5,id:\.self){ datum in
                                        Rectangle()
                                            .fill(Color.darkGray.opacity(0.5))
                                            .frame(width: 100, height: 100)
                                    }
                                }
                            }
                            
                        }
                        Divider()
                    }
                }
            }
            
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    var operations: some View {
        VStack{
            
        
                Button(action: {
                    showOperations.toggle()
                }, label: {
                    HStack{
                        Text("Operations")
                        Spacer()
                        Image(systemName: showOperations ? "chevron.down" : "chevron.right")
                    }
                })
            
            .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
            .background(Color.darkGray)
            .cornerRadius(10)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
            if showOperations {
                customers
                Divider()
                routeOverView
                Divider()
                jobs
                Divider()
                repairRequests
                Divider()
                equipment
                Divider()
                buisnesses
                Divider()
                serviceStops
            }
        }
    }
    
    var finace: some View {
        VStack{
            
   
                Button(action: {
                    showFinace.toggle()
                }, label: {
                    HStack{
                        Text("Finance")
                        Spacer()
                        Image(systemName: showFinace ? "chevron.down" : "chevron.right")
                    }
                })
            
            .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
            .background(Color.darkGray)
            .cornerRadius(10)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
            if showFinace {
                purchases
                Divider()
                accountsPayable
                Divider()

                accountsReceivable
                Divider()

                venders
            }
        }
        
    }
    
    var management: some View {
        VStack{
            if let role = masterDataManager.role {
                Button(action: {
                    showManagement.toggle()
                }, label: {
                    HStack{
                        Text("Management")
                        Spacer()
                        Image(systemName: showManagement ? "chevron.down" : "chevron.right")
                    }
                })
                
                .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6))
                .background(Color.darkGray)
                .cornerRadius(10)
                .foregroundColor(Color.white)
                .fontDesign(.monospaced)
                if showManagement {
                    if role.permissionIdList.contains("12") {
                        routeBuilder
                    }
                    Divider()
                        users
                    fleet
                    Divider()
                    
                }
            }
        }
    }
    
    var customers: some View {
        VStack{
            HStack{
                Text("Customers")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
  
                    NavigationLink(value: Route.customers(
                        dataService: dataService
                    ),label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            HStack{
                VStack(alignment: .leading){
                    if let num = VM.totalCustomers {
                        
                        HStack{
                            Text("Total: \(num.description)")
                            Spacer()
                            
                        }
                    }
                    if let num = VM.totalResidentalAccounts {
                        
                        HStack{
                            Text("Residential: \(num.description)")
                            Spacer()
                            
                            
                        }
                    }
                    if let num = VM.totalComericalAccounts {
                        
                        HStack{
                            Text("Comercial: \(num.description)")
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.customers.count == 0 {
                HStack{
                    SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                        .overlay(
                            ProgressView()
                        )
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.customers){ datum in
                            let customerName = datum.firstName + " " + datum.lastName
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.customer(
                                    customer:datum,
                                    dataService: dataService
                                ),label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: customerName, iconName: "person.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCustomer = datum
                                    navigationManager.routes.append(Route.customer(customer: datum,dataService:dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: customerName, iconName: "person.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    var buisnesses: some View {
        VStack{
            HStack{
                Text("Buisnesses")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                    NavigationLink(value: Route.businesses(
                        dataService: dataService
                    ),label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            HStack{
                VStack(alignment: .leading,spacing: 3){
                    Text("Open Contracts: 1")
                    Text("Buissness: 3")
                    Text("Unbilled Work: $ 10,350.69")
                }
                Spacer()
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.businesses.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.businesses){ datum in
                            let name:String = datum.name ?? ""
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.business(business: datum, dataService: dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: name, iconName: "person.fill")
                                })
                            } else {
                                Button(action: {
                                    navigationManager.routes.append(Route.business(business: datum, dataService: dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: name, iconName: "person.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    var jobs: some View {
        VStack{
            HStack{
                Text("Jobs")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                    NavigationLink(value: Route.jobs(
                        dataService: dataService
                    ),label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
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
            .padding(.horizontal,20)
            if VM.jobs.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
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
                                    masterDataManager.selectedWorkOrder = datum
                                    navigationManager.routes.append(Route.job(job: datum, dataService: dataService))
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
    
    var repairRequests: some View {
        VStack{
            HStack{
                Text("Repair Requests")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                    NavigationLink(value: Route.repairRequestList(
                        dataService: dataService
                    ), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            HStack{
                VStack(alignment: .leading){
                    Text("Open: 8")
                    Text("In Progress/Scheduled: 3")
                    Text("Recently Finished: 3")
                }
                Spacer()
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.listOfRepairRequests.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.listOfRepairRequests){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.repairRequest(
                                    repairRequest:datum,
                                    dataService: dataService
                                ), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.realYellow,textColor: Color.black,text: datum.customerName, iconName: "wrench.adjustable.fill")
                                    
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedRepairRequest = datum
                                    navigationManager.routes.append(Route.repairRequest(repairRequest: datum, dataService: dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.realYellow,textColor: Color.black,text: datum.customerName, iconName: "wrench.adjustable.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    var serviceStops: some View {
        VStack{
            HStack{
                Text("Service Stops Preview")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                    NavigationLink(value: Route.serviceStops(
                        dataService: dataService
                    ), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            if VM.serviceStops.count != 0 {
                HStack{
                    VStack(alignment: .leading){
                        ForEach(Array(VM.typesAndAmount.keys), id: \.self) { key in
                            if let amount = VM.typesAndAmount[key] {
                                Text("\(key):  \(amount.description)")
                            }
                        }
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,20)
                
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.serviceStops){ datum in
                            SquareSnapShot(color: Color.gray, footer: Color.pink,textColor: Color.black,text: datum.customerName, iconName: datum.typeImage)
                        }
                    }
                }
            } else {
                HStack{
                    SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                        .overlay(
                            ProgressView()
                        )
                    Spacer()
                }
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    
    var purchases: some View {
        VStack{
            HStack{
                Text("Purchases")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                    NavigationLink(value: Route.purchases(
                        dataService: dataService
                    ), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
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
            .padding(.horizontal,20)
            if VM.purchasedItems.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
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
    var accountsPayable: some View {
        VStack{
            HStack{
                Text("Accounts Payable")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()

                    NavigationLink(value: Route.accountsPayableList(
                        dataService: dataService
                    ), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
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
            .padding(.horizontal,20)
            if VM.APInvoiceList.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
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
                                    masterDataManager.accountsPayableInvoice = datum
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
    
    
    var accountsReceivable: some View {
        VStack{
            HStack{
                Text("Accounts Receivable")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value: Route.accountsReceivableList(dataService: dataService), label: {

                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
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
            .padding(.horizontal,20)
            if VM.ARInvoiceList.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
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
                                    masterDataManager.accountsReceivableInvoice = datum
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
    var venders: some View {
        VStack{
            HStack{
                Text("Vender")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value:Route.venders(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            HStack{
                VStack(alignment: .leading){
                    if let count = VM.venderCount {
                        HStack{
                            Text("Venders: \(count)")
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.listOfVenders.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.listOfVenders){ datum in
                            let text:String = datum.name ?? ""
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.vender(vender: datum, dataService: dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.yellow,textColor: Color.white,text: text, iconName: "building.2")
                                })
                            } else {
                                Button(action: {
                                    navigationManager.routes.append(Route.vender(vender: datum, dataService: dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.yellow,textColor: Color.white,text: text, iconName: "building.2")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    var equipment: some View {
        VStack{
            HStack{
                Text("Equipment")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value:Route.equipmentList(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
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
                        Text("Needs Service: 15")
                        Spacer()
                    }
                    HStack{
                        Text("Needs Repair: 2")
                        Spacer()
                    }
                }
                Spacer()
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.listOfEquipment.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.listOfEquipment){ datum in
                            let text = datum.make + " " + datum.model
                            if UIDevice.isIPhone {
                                NavigationLink(value:Route.equipmentDetailView(dataService:dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.yellow,textColor: Color.white,text: datum.name, iconName: "spigot.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedEquipment = datum
                                    navigationManager.routes.append(Route.equipmentDetailView(dataService:dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.yellow,textColor: Color.white,text: datum.name, iconName: "spigot.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    var users: some View {
        VStack{
            HStack{
                Text("Techs")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value:Route.users(dataService:dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            VStack{
                HStack{
                    Text("Total Techs: 15")
                    Spacer()
                }
                HStack{
                    Text("Employees: 10")
                    Spacer()
                }
                HStack{
                    Text("Sub-contractors: 5")
                    Spacer()
                }
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.companyUsers.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.companyUsers){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value:Route.users(dataService:dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.userName, iconName: "person.3.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.companyUser = datum
                                    navigationManager.routes.append(Route.users(dataService:dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.userName, iconName: "person.3.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    var fleet: some View {
        VStack{
            HStack{
                Text("Fleet")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value:Route.fleet(dataService:dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            VStack{
                if let count = VM.vehicalCount {
                    HStack{
                        Text("Vehicals: \(count)")
                        Spacer()
                    }
                }
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            if VM.listOfVehicals.count == 0 {
                SquareSnapShot(color: Color.gray, footer: Color.clear,textColor: Color.white,text: "", iconName: "person.fill")
                    .overlay(
                    ProgressView()
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(VM.listOfVehicals){ datum in
                            if UIDevice.isIPhone {
                                NavigationLink(value:Route.vehicalDetailView(dataService:dataService), label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.nickName, iconName: "car.fill")
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.vehical = datum
                                    navigationManager.routes.append(Route.vehicalDetailView(dataService:dataService))
                                }, label: {
                                    SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.nickName, iconName: "car.fill")
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    var routeOverView: some View {
        VStack{
            HStack{
                Text("Routes Today")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value:Route.companyRouteOverView(dataService:dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            VStack{
                ForEach(VM.companyUsers){ tech in
                    HStack{
                        Text("\(tech.userName)")
                        Spacer()
                    }
                }
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
        }
    }
    var routeBuilder: some View {
        VStack{
            HStack{
                Text("Route Managment")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value:Route.routeBuilder(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            VStack{
                ForEach( Array(VM.daysAndRoutes.enumerated()), id: \.offset) { index, value in
                    HStack{
                        Text("\(value.key): \(value.value)")
                        Spacer()
                    }
                }
            }
            .fontDesign(.monospaced)
            .font(.footnote)
            .padding(.horizontal,20)
            
        }
    }
    var settings: some View {
        VStack{
            HStack{
                Text("Settings")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()

                    NavigationLink(value: Route.settings(
                        dataService: dataService
                    ),label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                    .foregroundColor(Color.basicFontText)
                })
            }
            ScrollView(showsIndicators: false){

                    NavigationLink(value: Route.readingsAndDosages(
                        dataService: dataService
                    ),label: {
                    Rectangle()
                        .fill(Color.darkGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Text("Readings And Dosages")
                        )
                })
                    NavigationLink(value: Route.databaseItems(
                        dataService: dataService
                    ),label: {
                    Rectangle()
                        .fill(Color.darkGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Text("Data Base")
                        )
                })
                    NavigationLink(value: Route.jobTemplates(
                        dataService: dataService
                    ),label: {
                    Rectangle()
                        .fill(Color.darkGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Text("Jobs Templates")
                        )
                })
                    NavigationLink(value: Route.contracts(
                        dataService: dataService
                    ),label: {
                    Rectangle()
                        .fill(Color.darkGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Text("Contracts")
                        )
                })
                    NavigationLink(value: Route.reports(
                        dataService: dataService
                    ),label: {
                    Rectangle()
                        .fill(Color.darkGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Text("Reports")
                        )
                })
                    NavigationLink(value: Route.userRoles(
                        dataService: dataService
                    ),label: {
                    Rectangle()
                        .fill(Color.darkGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Text("User Roles")
                        )
                })
            }
        }
        .foregroundColor(Color.white)
    }
    
}

