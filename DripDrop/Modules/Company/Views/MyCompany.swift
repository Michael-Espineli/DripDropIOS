//
//  MyCompany.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI
import MapKit
import Firebase

struct SendGridTest:Identifiable,Codable{
    let id:String
    let email:String
}
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
                    assignments
                    companyAlerts
                    quickAccess
                }
                .padding(.horizontal,8)
            }
            .padding(.bottom,16)
            
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
                    try await VM.onLoad(companyId: company.id, userId: user.id, category: "NA")
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of:  masterDataManager.currentCompany, perform: { selectedCompany in
            Task{
                if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                    do {
                        try await VM.onLoad(companyId: company.id, userId: user.id, category: "NA")
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
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.poolRed)
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
    var assignments: some View {
        VStack{
            if let currentCompany = masterDataManager.currentCompany {
                WorkPreviewBasedOnCompany(dataService: dataService, company: currentCompany)
            }
            HStack{
                Text("To Do List:")
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
            }
            Text("Company To Do List")
        }
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
    var companyAlerts: some View {
        VStack(spacing: 3){
            if let alertCount = VM.alertCount {
                if alertCount != 0 {
                    HStack{
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.companyAlerts(dataService: dataService), label: {
                                HStack{
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color.poolYellow)
                                    Text("\(alertCount)")
                                    Text("Company Alerts ")
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .modifier(HeaderModifier())
                                
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .companyAlerts
                            }, label: {
                                HStack{
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color.poolYellow)
                                    Text("\(alertCount)")
                                    Text("Company Alerts")
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .modifier(HeaderModifier())
                            })
                        }
                    }
                }
            }
        }
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
                    .modifier(ListButtonModifier())
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
                            .padding(.horizontal,16)
                            
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
                .modifier(HeaderModifier())
                
            })
            
            if showOperations {
                managementTables
                Divider()
                customers
                Divider()
                jobs
                Divider()
                shoppingListItems
                Divider()
                repairRequests
                Divider()
                equipment
                Divider()
                businesses
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
                .modifier(HeaderModifier())
                
            })
            
            if showFinace {
                purchases
                Divider()
                receipts
                Divider()
                contract
                Divider()
                sentLaborContract
                Divider()
                receivedLaborContract
                Divider()
                payRoll
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
                    .modifier(HeaderModifier())
                    
                })
                
                if showManagement {
                    
                    users
                    Divider()
                    if let role = masterDataManager.role {
                        
                        if role.permissionIdList.contains("12") {
                            routeBuilder
                            Divider()
                        }
                    }
                    
                    routeOverView
                    Divider()
                    externalRoutes
                    Divider()
                    routeSandBox
                    
                    Divider()
                    
                    fleet
                    Divider()
                    
                }
            }
        }
    }
    var managementTables: some View {
        VStack{
            HStack{
                Text("Management Tables")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    
                    NavigationLink(value: Route.managementTables(
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
                        print("Click")
                        masterDataManager.selectedCategory = .managementTables
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
                if UIDevice.isIPhone {
                    
                    NavigationLink(value: Route.customers(
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
                        masterDataManager.selectedCategory = .customers
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
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                if VM.customers.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Customers")
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
                                        masterDataManager.selectedCategory = .customers
                                        masterDataManager.selectedCustomer = datum
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
    }
    
    var businesses: some View {
        VStack{
            HStack{
                Text("Businesses")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.businesses(
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
                        masterDataManager.selectedCategory = .businesses
                    }, label:   {
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
                        Text("Open Contracts: 1")
                        Text("Buissness: 3")
                        Text("Unbilled Work: $ 10,350.69")
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{
                
                if VM.businesses.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Businesses")
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.businesses){ datum in
                                let name:String = datum.companyName
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.business(business: datum, dataService: dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.poolGreen,textColor: Color.white,text: name, iconName: "person.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .businesses
                                        masterDataManager.selectedBuisness = datum
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
    }
    
    var jobs: some View {
        VStack{
            HStack{
                Text("Jobs")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.jobs(
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
    
    var shoppingListItems: some View {
        VStack{
            HStack{
                Text("Shopping List")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.shoppingList(
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
                        masterDataManager.selectedCategory = .shoppingList
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
                        Text("Need to Purchase: 4")
                        Text("Purchased: 2")
                        Text("Installed: 0")
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{
                
                if VM.listOfShoppingListItems.count == 0 {
                    HStack{
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Shopping List Items")
                        
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.listOfShoppingListItems){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.shoppingListDetail(item: datum, dataService: dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.realYellow,textColor: Color.black,text: datum.name, iconName: "wrench.adjustable.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedShoppingListItem = datum
                                        masterDataManager.selectedCategory = .shoppingList
                                    }, label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.realYellow,textColor: Color.black,text: datum.name, iconName: "wrench.adjustable.fill")
                                    })
                                }
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
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.repairRequestList(
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
                        masterDataManager.selectedCategory = .repairRequest
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
                        Text("Open: 8")
                        Text("In Progress/Scheduled: 3")
                        Text("Recently Finished: 3")
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{
                
                if VM.listOfRepairRequests.count == 0 {
                    HStack{
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Repairs")
                        
                        Spacer()
                    }
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
                                        masterDataManager.selectedCategory = .repairRequest
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
    }
    
    var serviceStops: some View {
        VStack{
            HStack{
                Text("Service Stops")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.serviceStops(
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
                        masterDataManager.selectedCategory = .serviceStops
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

            HStack{
                VStack{
                    Divider()
                        .frame(width: 200)
                }
                Spacer()
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{
                
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
                    .padding(.horizontal,16)
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.serviceStops){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.serviceStop(serviceStop: datum,
                                                                            dataService: dataService
                                                                           ), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.pink,textColor: Color.black,text: datum.customerName, iconName: datum.typeImage)
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .serviceStops
                                        masterDataManager.selectedServiceStops = datum
                                    }, label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.pink,textColor: Color.black,text: datum.customerName, iconName: datum.typeImage)
                                    })
                                }
                                
                            }
                        }
                    }
                } else {
                    HStack{
                        SquareLoading(color: Color.gray, footer: Color.clear,textColor: Color.white)
                        Spacer()
                    }
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
    
    var payRoll: some View {
        VStack{
            HStack{
                Text("Pay Roll // Developer")
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
    
    var venders: some View {
        VStack{
            HStack{
                Text("Vender")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.venders(dataService: dataService), label: {
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
                        masterDataManager.selectedCategory = .vender
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
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview{
                
                if VM.listOfVenders.count == 0 {
                    HStack{
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Venders")
                        Spacer()
                    }
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
    }
    
    var equipment: some View {
        VStack{
            HStack{
                Text("Equipment")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.equipmentList(dataService: dataService), label: {
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
                        masterDataManager.selectedCategory = .equipment
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
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.listOfEquipment.count == 0 {
                    HStack{
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Equipment")
                        
                        Spacer()
                    }
                    
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.listOfEquipment){ datum in
                                let text = datum.make + " " + datum.model
                                if UIDevice.isIPhone {
                                    NavigationLink(value:Route.equipmentDetailView(equipment: datum, dataService:dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.yellow,textColor: Color.white,text: datum.name,text2: datum.customerName, iconName: "spigot.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCategory = .equipment
                                        masterDataManager.selectedEquipment = datum
                                        //                                    navigationManager.routes.append(Route.equipmentDetailView(dataService:dataService))
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
    }
    
    var users: some View {
        VStack{
            HStack{
                Text("Techs")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.users(dataService:dataService), label: {
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
                        masterDataManager.selectedCategory = .users
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
                VStack{
                    HStack{
                        Text("Total Users:")
                        if let total = VM.totalUSers {
                            Text("\(total)")
                        }
                        Spacer()
                    }
                    ForEach(Array(VM.techsByRoles.keys)){ key in
                        if let count = VM.techsByRoles[key] {
                            if count != 0 {
                                HStack{
                                    Text("\(key.name): \(count)")
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.companyUsers.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Users")
                        Spacer()
                    }
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
    }
    
    var fleet: some View {
        VStack{
            HStack{
                Text("Fleet")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.fleet(dataService:dataService), label: {
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
                        masterDataManager.selectedCategory = .fleet
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
                .padding(.horizontal,16)
            }
            if masterDataManager.mainScreenDisplayType == .fullPreview {
                
                if VM.listOfVehicals.count == 0 {
                    HStack{
                        
                        SquareEmpty(color: Color.poolRed, footer: Color.clear,textColor: Color.white,text: "No Vehicals")
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.listOfVehicals){ datum in
                                if UIDevice.isIPhone {
                                    NavigationLink(value:Route.vehicalDetailView(vehical: datum, dataService:dataService), label: {
                                        SquareSnapShot(color: Color.gray, footer: Color.blue,textColor: Color.white,text: datum.nickName, iconName: "car.fill")
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedVehical = datum
                                        navigationManager.routes.append(Route.vehicalDetailView(vehical:datum,dataService:dataService))
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
    }
    
    var routeSandBox: some View {
        VStack{
            HStack{
                Text("Route Sandbox")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)

                Spacer()
            }
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
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.activeRouteOverView(dataService: dataService), label: {
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
                        masterDataManager.selectedCategory =  .companyRouteOverView
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
                .padding(.horizontal,16)
            }
        }
    }
    var workLogList: some View {
        VStack{
            HStack{
                Text("Work Logs")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.workLogList(dataService:dataService), label: {
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
                        masterDataManager.selectedCategory = .routeBuilder
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
                .padding(.horizontal,16)
            }
        }
    }
    var routeOverView: some View {
        VStack{
            HStack{
                Text("Internal Routes")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.companyRouteOverView(dataService:dataService), label: {
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
                        masterDataManager.selectedCategory = .routeBuilder
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
                .padding(.horizontal,16)
            }
        }
    }
    
    var externalRoutes: some View {
        VStack{
            HStack{
                Text("External Routes")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.externalRouteOverView(dataService:dataService), label: {
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
                        masterDataManager.selectedCategory = .externalRoutesOverview
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
                .padding(.horizontal,16)
            }
        }
    }

    
    var contract: some View {
        VStack{
            HStack{
                Text("Contract")
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
    
    var sentLaborContract: some View {
        VStack{
            HStack{
                Text("Sent Labor Contract")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.laborContracts(
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
                    .background(Color.pink)

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

    
}

struct MyCompany_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    
    static var previews: some View {
        MyCompany(dataService:dataService )
    }
}
