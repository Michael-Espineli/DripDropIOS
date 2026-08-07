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
    @State var showSales:Bool = false
    @State var showFinace:Bool = false //DEVELOPER LATER MAKE THIS TRUE
    @State var showManagement:Bool = false //DEVELOPER LATER MAKE THIS TRUE
    @State var showCompanySettings:Bool = false
    @State var showMoreCompanySettings:Bool = false

    @State var isLoading: Bool = true
    
    var body: some View {
        ZStack{
            
            Text("")
                .sheet(isPresented: $showMoreCompanySettings, content: {
                    CompanySettings(dataService: dataService)
                })
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
                showSales = true
                showFinace = true
                showManagement = true
                showCompanySettings = true
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
            //Update 2.1
//            HStack{
//                Text("To Do List:")
//                    .fontWeight(.bold)
//                    .fontDesign(.monospaced)
//                    .foregroundColor(Color.basicFontText)
//                Spacer()
//            }
//            Text("Company To Do List")
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
                    if role.permissionIdList.contains("0") {
                        operations
                    }
                    if masterDataManager.isFeatureEnabled(.sales) &&
                        (role.permissionIdList.contains("610") || role.permissionIdList.contains("612") || role.permissionIdList.contains("614") || role.permissionIdList.contains("616")) {
                        sales
                    }
                    if role.permissionIdList.contains("200") {
                        
                        management
                    }
                    companySettingsView
        //                Update 2.1
//                    if role.permissionIdList.contains("400") {
//                        
//                        finace
//                    }
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
    var sales: some View {
        VStack{
            Button(action: {
                showSales.toggle()
            }, label: {
                HStack{
                    Text("Sales")
                    Spacer()
                    Image(systemName: showSales ? "chevron.down" : "chevron.right")
                }
                .modifier(HeaderModifier())
            })
            
            if showSales {
                leads
            }
        }
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
//                Update 2.1
//                managementTables
//                Divider()
                customers
                Divider()
                jobs
                
    //                Update 2.1
//                Divider()
//                shoppingListItems
                Divider()
                repairRequests
                Divider()
                equipment
                
    //                Update 2.1
//                Divider()
//                businesses
                Divider()
                serviceStops
            }
        }
    }
    
    var leads: some View {
        VStack{
            HStack{
                Text("Leads")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value: Route.leads(
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
                        Text("Incoming homeowner service requests")
                        Text("Track, filter, and follow up")
                    }
                    Spacer()
                }
                .fontDesign(.monospaced)
                .font(.footnote)
                .padding(.horizontal,16)
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
                    //Techs
                    users
                    Divider()
                    
                    //Route Management
                    if let role = masterDataManager.role {
                        
                        if role.permissionIdList.contains("12") {
                            routeBuilder
                            Divider()
                        }
                    }
                    //
                    //Internal and external Routes
                    routeOverView
                    Divider()
                    externalRoutes
                    
                    //Update 2.1
                    //Route Sandbox
//                    Divider()
//                    routeSandBox
                    
                    Divider()
                    
                    fleet
                    Divider()
                    
                }
            }
        }
    }
    
    var companySettingsView: some View {
        ZStack{
            
            VStack(alignment: .leading,spacing: 20){
                Button(action: {
                    showCompanySettings.toggle()
                }, label: {
                    HStack{
                        Text("Company Settings")
                        Spacer()
                        Image(systemName: showCompanySettings ? "chevron.down" : "chevron.right")
                    }
                    .modifier(HeaderModifier())
                    
                })
//                Button(action: {
//                    showMoreCompanySettings.toggle()
//                }, label: {
//                        Text("See More Settings")
//                    .modifier(BlueButtonModifier())
//                })
                
                if showCompanySettings {
                    VStack{
                        taskGroupView
                        Divider()
                        emailConfigurationView
                        Divider()
                        ReadingsAndDosagesView
                        Divider()
                        DataBaseView
                        Divider()
                        JobTemplatesView
                        Divider()
                        ReportsView
                        Divider()
                        UserRolesView
                    }
                    VStack{
                        
                        Divider()
                        
                        HStack{
                            Text("Company Info")
                                .font(.headline)
                                .fontDesign(.monospaced)
                                .foregroundColor(Color.basicFontText)
                            Spacer()
                            Button(action: {
                                masterDataManager.selectedCategory = .companyInfo
                            }, label: {
                                HStack{
                                    Text("See More")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.footnote)
                                .padding(3)
                                .foregroundColor(Color.black)
                                .background(Color.pink)
                            })
                        }
                        
                        Divider()
                        HStack{
                            Text("Manage Subscriptions")
                                .font(.headline)
                                .fontDesign(.monospaced)
                                .foregroundColor(Color.basicFontText)
                            Spacer()
                            Button(action: {
                                masterDataManager.selectedCategory = .manageSubscriptions
                            }, label: {
                                HStack{
                                    Text("See More")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.footnote)
                                .padding(3)
                                .foregroundColor(Color.black)
                                .background(Color.pink)
                            })
                        }
                        
                        Divider()
                        HStack{
                            Text("Stripe Configuration")
                                .font(.headline)
                                .fontDesign(.monospaced)
                                .foregroundColor(Color.basicFontText)
                            Spacer()
                            Button(action: {
                                masterDataManager.selectedCategory = .stripeConfiguration
                            }, label: {
                                HStack{
                                    Text("See More")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.footnote)
                                .padding(3)
                                .foregroundColor(Color.black)
                                .background(Color.pink)
                            })
                        }
                    }
                }
            }
            .foregroundColor(Color.basicFontText)
            .fontDesign(.monospaced)
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
                Text("Directory")
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
                Text("Route Management")
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
                Text("Routes")
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
    
    var taskGroupView: some View {
        VStack{
            HStack{
                Text("Task Groups")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .taskGroups

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.black)
                    .background(Color.pink)
                })
            }
        }
    }
    var emailConfigurationView: some View {
        VStack{
            HStack{
                Text("Email Configuration")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .emailConfirguration

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.black)
                    .background(Color.pink)
                })
            }
        }
    }
    var ReadingsAndDosagesView: some View {
        VStack{
            HStack{
                Text("Readings and Dosages")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .readingsAndDosages

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.red)
                })
            }
        }
    }
    var DataBaseView: some View {
        VStack{
            HStack{
                Text("Data Base")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .readingsAndDosages

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.red)
                })
            }
        }
    }
    var JobTemplatesView: some View {
        VStack{
            HStack{
                Text("Jobs Templates")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .jobTemplates

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.red)
                })
            }
        }
    }
    var ReportsView: some View {
        VStack{
            HStack{
                Text("Reports")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .reports

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.red)
                })
            }
        }
    }
    var UserRolesView: some View {
        VStack{
            HStack{
                Text("User Roles")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                Button(action: {
                    masterDataManager.selectedCategory = .userRoles

                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .padding(3)
                    .foregroundColor(Color.red)
                })
            }
        }
    }
    
    
}

struct CompanyLeadSummary: Identifiable {
    let id: String
    let serviceName: String
    let serviceDescription: String
    let homeownerName: String
    let homeownerEmail: String
    let homeownerPhone: String
    let customerId: String
    let customerName: String
    let customerUserId: String
    let homeownerId: String
    let companyServiceLocationId: String
    let homeownerServiceLocationId: String
    let relationshipId: String
    let customerCompanyRelationshipId: String
    let streetAddress: String
    let city: String
    let state: String
    let zip: String
    let latitude: Double?
    let longitude: Double?
    let status: String
    let source: String
    let sourceType: String
    let publicLead: Bool
    let createdAt: Date?
    let dateCompleted: Date?
    
    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        let address = data["serviceLocationAddress"] as? [String: Any]
        
        id = document.documentID
        serviceName = data["serviceName"] as? String ?? "Lead Request"
        serviceDescription = data["serviceDescription"] as? String ?? ""
        homeownerName = data["homeownerName"] as? String ?? data["customerName"] as? String ?? "Unknown Homeowner"
        homeownerEmail = data["homeownerEmail"] as? String ?? ""
        homeownerPhone = data["homeownerPhone"] as? String ?? ""
        customerId = data["customerId"] as? String ?? data["companyCustomerId"] as? String ?? ""
        customerName = data["customerName"] as? String ?? ""
        customerUserId = data["customerUserId"] as? String ?? ""
        homeownerId = data["homeownerId"] as? String ?? data["homeownerUserId"] as? String ?? customerUserId
        companyServiceLocationId = data["companyServiceLocationId"] as? String ?? data["serviceLocationId"] as? String ?? ""
        homeownerServiceLocationId = data["homeownerServiceLocationId"] as? String ?? data["homeownerserviceLocationId"] as? String ?? ""
        relationshipId = data["relationshipId"] as? String ?? ""
        customerCompanyRelationshipId = data["customerCompanyRelationshipId"] as? String ?? relationshipId
        streetAddress = address?["streetAddress"] as? String ?? "No street address"
        city = address?["city"] as? String ?? ""
        state = address?["state"] as? String ?? ""
        zip = address?["zip"] as? String ?? address?["zipCode"] as? String ?? ""
        latitude = CompanyLeadSummary.double(from: address?["latitude"])
        longitude = CompanyLeadSummary.double(from: address?["longitude"])
        status = data["status"] as? String ?? "Pending"
        source = data["source"] as? String ?? ""
        sourceType = data["sourceType"] as? String ?? ""
        publicLead = data["publicLead"] as? Bool ?? false
        createdAt = CompanyLeadSummary.date(from: data["createdAt"])
        dateCompleted = CompanyLeadSummary.date(from: data["dateCompleted"])
    }
    
    static func date(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let date = value as? Date {
            return date
        }
        if let string = value as? String {
            return ISO8601DateFormatter().date(from: string)
        }
        return nil
    }

    static func double(from value: Any?) -> Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        if let string = value as? String {
            return Double(string)
        }
        return nil
    }
    
    var normalizedSource: String {
        let normalized = source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalized == "manual" {
            return "Manual"
        }
        if normalized == "public" || publicLead || sourceType == "publicNoAccount" {
            return "Public"
        }
        return "Customer"
    }
    
    var connectionLabel: String {
        if !customerId.isEmpty {
            return "Customer linked"
        }
        if !homeownerId.isEmpty {
            return "Client request"
        }
        return "Unlinked"
    }
    
    var connectionDetail: String {
        if !customerId.isEmpty {
            return customerName.isEmpty ? customerId : customerName
        }
        if !homeownerId.isEmpty {
            return homeownerId
        }
        return "Needs customer/client link"
    }

    var fullAddress: String {
        [streetAddress == "No street address" ? "" : streetAddress, city, state, zip]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")
    }

    var hasLinkedCustomer: Bool {
        !customerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct CompanyLeadsView: View {
    let dataService: any ProductionDataServiceProtocol
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    
    @State private var leads: [CompanyLeadSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchTerm = ""
    @State private var statusFilter = "Pending"
    @State private var sourceFilter = "All"
    @State private var listener: ListenerRegistration?
    
    private let statusOptions = ["All", "Pending", "In Progress", "Completed", "Cancelled"]
    private let sourceOptions = ["All", "Customer", "Public", "Manual"]
    
    var filteredLeads: [CompanyLeadSummary] {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return leads.filter { lead in
            let matchesSearch = term.isEmpty || [
                lead.homeownerName,
                lead.homeownerEmail,
                lead.homeownerPhone,
                lead.customerName,
                lead.customerId,
                lead.customerUserId,
                lead.homeownerId,
                lead.companyServiceLocationId,
                lead.homeownerServiceLocationId,
                lead.relationshipId,
                lead.customerCompanyRelationshipId,
                lead.streetAddress,
                lead.city,
                lead.serviceName,
                lead.serviceDescription,
                lead.status,
                lead.normalizedSource,
                lead.id
            ].contains(where: { $0.lowercased().contains(term) })
            let matchesStatus = statusFilter == "All" || lead.status == statusFilter
            let matchesSource = sourceFilter == "All" || lead.normalizedSource == sourceFilter
            
            return matchesSearch && matchesStatus && matchesSource
        }
    }
    
    var pendingCount: Int {
        leads.filter { $0.status == "Pending" }.count
    }
    
    var inProgressCount: Int {
        leads.filter { $0.status == "In Progress" }.count
    }

    var completedRecentCount: Int {
        leads.filter { $0.status == "Completed" && isRecentCompletion($0.dateCompleted) }.count
    }

    var cancelledRecentCount: Int {
        leads.filter { $0.status == "Cancelled" && isRecentCompletion($0.dateCompleted) }.count
    }
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    statsGrid
                    filtersCard
                    leadContent
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Leads")
        .searchable(text: $searchTerm, prompt: "Search leads")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CompanyLeadEditorView(dataService: dataService)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Lead")
            }
        }
        .onAppear {
            startListening()
        }
        .onDisappear {
            listener?.remove()
            listener = nil
        }
        .onChange(of: masterDataManager.currentCompany?.id, perform: { _ in
            startListening()
        })
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Leads")
                        .font(.title2.weight(.bold))

                    Text("Manage and track incoming homeowner service requests.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                NavigationLink {
                    CompanyLeadEditorView(dataService: dataService)
                } label: {
                    Label("Add Lead", systemImage: "person.crop.circle.badge.plus")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .leadCardStyle()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: statColumns, spacing: 10) {
            leadStat(title: "Pending", value: pendingCount, status: "Pending", systemImage: "clock", tint: .poolBlue)
            leadStat(title: "In Progress", value: inProgressCount, status: "In Progress", systemImage: "arrow.triangle.2.circlepath", tint: .orange)
            leadStat(title: "Completed (30d)", value: completedRecentCount, status: "Completed", systemImage: "checkmark.circle", tint: .poolGreen)
            leadStat(title: "Cancelled (30d)", value: cancelledRecentCount, status: "Cancelled", systemImage: "xmark.octagon", tint: .poolRed)
        }
    }

    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LeadFilterMenu(
                    title: "Status",
                    systemImage: "line.3.horizontal.decrease.circle",
                    selection: $statusFilter,
                    options: statusOptions,
                    tintForOption: { $0 == "All" ? .poolBlue : leadStatusColor($0) }
                )

                LeadFilterMenu(
                    title: "Source",
                    systemImage: "square.and.arrow.down.on.square",
                    selection: $sourceFilter,
                    options: sourceOptions,
                    tintForOption: { $0 == "All" ? .poolBlue : leadSourceColor($0) }
                )
            }

            Text("\(filteredLeads.count) visible lead\(filteredLeads.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
        .leadCardStyle()
    }

    @ViewBuilder
    private var leadContent: some View {
        if isLoading {
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading leads...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .leadCardStyle()
        } else if let errorMessage {
            emptyState(
                title: "Could not load leads",
                message: errorMessage,
                systemImage: "exclamationmark.triangle"
            )
        } else if filteredLeads.isEmpty {
            emptyState(
                title: "No leads found",
                message: "When a homeowner request or filter match appears, it will show here.",
                systemImage: "tray"
            )
        } else {
            LazyVStack(spacing: 10) {
                ForEach(filteredLeads) { lead in
                    NavigationLink {
                        CompanyLeadDetailView(dataService: dataService, lead: lead)
                    } label: {
                        CompanyLeadRowCard(lead: lead)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private func leadStat(title: String, value: Int, status: String, systemImage: String, tint: Color) -> some View {
        let isSelected = statusFilter == status

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                statusFilter = status
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundColor(isSelected ? tint : .secondary)
                        .lineLimit(2)

                    Spacer(minLength: 6)

                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isSelected ? .white : tint)
                        .frame(width: 28, height: 28)
                        .background(isSelected ? tint : tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(value)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if isSelected {
                        Text("Active")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12), in: Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? tint.opacity(0.08) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.4 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) leads")
        .accessibilityValue(isSelected ? "Selected" : "\(value)")
        .accessibilityHint("Filters the lead list by \(status)")
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())

            Text(title)
                .font(.headline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .leadCardStyle()
    }

    private func isRecentCompletion(_ date: Date?) -> Bool {
        guard let date else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return date >= thirtyDaysAgo
    }

    private func startListening() {
        listener?.remove()
        errorMessage = nil

        guard let companyId = masterDataManager.currentCompany?.id else {
            leads = []
            isLoading = false
            return
        }

        isLoading = true
        listener = Firestore.firestore()
            .collection("homeownerServiceRequests")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    errorMessage = "Could not load leads: \(error.localizedDescription)"
                    leads = []
                    isLoading = false
                    return
                }

                leads = snapshot?.documents
                    .map { CompanyLeadSummary(document: $0) }
                    .sorted(by: { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }) ?? []
                isLoading = false
            }
    }
}

struct LeadFilterMenu: View {
    let title: String
    let systemImage: String
    @Binding var selection: String
    let options: [String]
    let tintForOption: (String) -> Color

    private var tint: Color {
        tintForOption(selection)
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = option
                    }
                } label: {
                    HStack {
                        Text(option)

                        if option == selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundColor(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    Text(selection)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter")
        .accessibilityValue(selection)
    }
}

struct CompanyLeadRowCard: View {
    let lead: CompanyLeadSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerName)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(lead.serviceName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                LeadChip(text: lead.status, color: leadStatusColor(lead.status))
            }

            if !lead.fullAddress.isEmpty {
                Text(lead.fullAddress)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.72))
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                LeadChip(text: lead.normalizedSource, color: leadSourceColor(lead.normalizedSource))

                if let createdAt = lead.createdAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: lead.hasLinkedCustomer ? "checkmark.seal.fill" : "link.badge.plus")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(lead.hasLinkedCustomer ? .poolGreen : .secondary)
                    .frame(width: 24, height: 24)
                    .background((lead.hasLinkedCustomer ? Color.poolGreen : Color.secondary).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(lead.connectionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(lead.connectionDetail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .leadCardStyle()
    }
}

struct CompanyLeadDetailView: View {
    let dataService: any ProductionDataServiceProtocol
    let lead: CompanyLeadSummary

    @EnvironmentObject private var masterDataManager: MasterDataManager

    @State private var selectedStatus: String
    @State private var savedStatus: String
    @State private var isSavingStatus = false
    @State private var alertMessage: String?

    private let statusOptions = ["Pending", "In Progress", "Completed", "Cancelled"]

    init(dataService: any ProductionDataServiceProtocol, lead: CompanyLeadSummary) {
        self.dataService = dataService
        self.lead = lead
        _selectedStatus = State(initialValue: lead.status)
        _savedStatus = State(initialValue: lead.status)
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    statusCard
                    requestCard
                    homeownerCard
                    addressCard
                    linkCard
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Lead")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    CompanyLeadEditorView(dataService: dataService, lead: lead)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .alert("Lead Update", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
        .onChange(of: selectedStatus) { nextStatus in
            Task {
                await updateStatus(nextStatus)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerName)
                        .font(.title2.weight(.bold))

                    Text(lead.serviceName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                LeadChip(text: selectedStatus, color: leadStatusColor(selectedStatus))
            }

            HStack(spacing: 8) {
                LeadChip(text: lead.normalizedSource, color: leadSourceColor(lead.normalizedSource))

                if let createdAt = lead.createdAt {
                    Text("Submitted \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .leadCardStyle()
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Status", systemImage: "slider.horizontal.3")
                .font(.headline.weight(.semibold))

            Picker("Status", selection: $selectedStatus) {
                ForEach(statusOptions, id: \.self) { status in
                    Text(status).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isSavingStatus)

            if isSavingStatus {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Saving status...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .leadCardStyle()
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Shared Description", systemImage: "text.alignleft")
                .font(.headline.weight(.semibold))

            Text(lead.serviceDescription.isEmpty ? "No description provided." : lead.serviceDescription)
                .font(.body)
                .foregroundColor(lead.serviceDescription.isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .leadCardStyle()
    }

    private var homeownerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Homeowner", systemImage: "person.fill")
                .font(.headline.weight(.semibold))

            detailRow("Name", lead.homeownerName)
            detailRow("Phone", lead.homeownerPhone)
            detailRow("Email", lead.homeownerEmail)
        }
        .leadCardStyle()
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Service Location", systemImage: "mappin.and.ellipse")
                .font(.headline.weight(.semibold))

            Text(lead.fullAddress.isEmpty ? "No service location saved." : lead.fullAddress)
                .font(.subheadline)
                .foregroundColor(lead.fullAddress.isEmpty ? .secondary : .primary)
        }
        .leadCardStyle()
    }

    private var linkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Customer Link", systemImage: "link")
                .font(.headline.weight(.semibold))

            detailRow(lead.connectionLabel, lead.connectionDetail)

            if lead.hasLinkedCustomer {
                LeadChip(text: "Customer linked", color: .poolGreen)
            } else {
                NavigationLink {
                    CompanyLeadConversionView(
                        lead: lead,
                        companyId: masterDataManager.currentCompany?.id ?? ""
                    )
                } label: {
                    Label("Convert Lead", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.poolBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .leadCardStyle()
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue {
                    alertMessage = nil
                }
            }
        )
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .frame(width: 118, alignment: .leading)

            Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
    }

    @MainActor
    private func updateStatus(_ nextStatus: String) async {
        guard nextStatus != savedStatus else { return }

        isSavingStatus = true
        do {
            var payload: [String: Any] = [
                "status": nextStatus,
                "updatedAt": FieldValue.serverTimestamp()
            ]

            if nextStatus == "Completed" || nextStatus == "Cancelled" {
                payload["dateCompleted"] = Date()
            } else {
                payload["dateCompleted"] = NSNull()
            }

            try await Firestore.firestore()
                .collection("homeownerServiceRequests")
                .document(lead.id)
                .updateData(payload)
            savedStatus = nextStatus
        } catch {
            selectedStatus = savedStatus
            alertMessage = "Could not update status: \(error.localizedDescription)"
        }
        isSavingStatus = false
    }
}

struct CompanyLeadEditorView: View {
    let dataService: any ProductionDataServiceProtocol
    let lead: CompanyLeadSummary?

    @EnvironmentObject private var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @State private var serviceName: String
    @State private var serviceDescription: String
    @State private var homeownerName: String
    @State private var homeownerEmail: String
    @State private var homeownerPhone: String
    @State private var streetAddress: String
    @State private var city: String
    @State private var state: String
    @State private var zip: String
    @State private var latitude: String
    @State private var longitude: String
    @State private var isSubmitting = false
    @State private var alertMessage: String?

    init(dataService: any ProductionDataServiceProtocol, lead: CompanyLeadSummary? = nil) {
        self.dataService = dataService
        self.lead = lead

        _serviceName = State(initialValue: lead?.serviceName == "Lead Request" ? "" : lead?.serviceName ?? "")
        _serviceDescription = State(initialValue: lead?.serviceDescription ?? "")
        _homeownerName = State(initialValue: lead?.homeownerName == "Unknown Homeowner" ? "" : lead?.homeownerName ?? "")
        _homeownerEmail = State(initialValue: lead?.homeownerEmail ?? "")
        _homeownerPhone = State(initialValue: lead?.homeownerPhone ?? "")
        _streetAddress = State(initialValue: lead?.streetAddress == "No street address" ? "" : lead?.streetAddress ?? "")
        _city = State(initialValue: lead?.city ?? "")
        _state = State(initialValue: lead?.state ?? "")
        _zip = State(initialValue: lead?.zip ?? "")
        _latitude = State(initialValue: lead?.latitude.map { String($0) } ?? "")
        _longitude = State(initialValue: lead?.longitude.map { String($0) } ?? "")
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    formHeader
                    requestSection
                    homeownerSection
                    serviceLocationSection
                    actionSection
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(lead == nil ? "Add Lead" : "Edit Lead")
        .alert("Lead", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lead == nil ? "Add New Lead" : "Edit Lead")
                .font(.title2.weight(.bold))

            Text(lead == nil ? "Add a manual lead to your marketing list." : "Update this lead before the next sales step.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .leadCardStyle()
    }

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Lead Info", systemImage: "doc.text")

            LeadTextField(title: "Service Name", text: $serviceName, required: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Shared Description")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                TextEditor(text: $serviceDescription)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    )
            }
        }
        .leadCardStyle()
    }

    private var homeownerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Homeowner", systemImage: "person")
            LeadTextField(title: "Name", text: $homeownerName, required: true)
            LeadTextField(title: "Phone", text: $homeownerPhone, keyboardType: .phonePad)
            LeadTextField(title: "Email", text: $homeownerEmail, keyboardType: .emailAddress, textInputAutocapitalization: .never)
        }
        .leadCardStyle()
    }

    private var serviceLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Service Location", systemImage: "mappin.and.ellipse")
            LeadTextField(title: "Street Address", text: $streetAddress)
            LeadTextField(title: "City", text: $city)

            HStack(spacing: 10) {
                LeadTextField(title: "State", text: $state)
                LeadTextField(title: "Zip", text: $zip, keyboardType: .numbersAndPunctuation)
            }

            HStack(spacing: 10) {
                LeadTextField(title: "Latitude", text: $latitude, keyboardType: .decimalPad)
                LeadTextField(title: "Longitude", text: $longitude, keyboardType: .decimalPad)
            }
        }
        .leadCardStyle()
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await saveLead()
                }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(isSubmitting ? "Saving Lead..." : lead == nil ? "Add Lead" : "Save Lead")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            Button("Cancel") {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue {
                    alertMessage = nil
                }
            }
        )
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
    }

    @MainActor
    private func saveLead() async {
        guard !isSubmitting else { return }

        let cleanServiceName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = serviceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanHomeowner = homeownerName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanServiceName.isEmpty, !cleanDescription.isEmpty, !cleanHomeowner.isEmpty else {
            alertMessage = "Service name, homeowner name, and shared description are required."
            return
        }

        guard let company = masterDataManager.currentCompany else {
            alertMessage = "Select a company before saving a lead."
            return
        }

        isSubmitting = true

        do {
            let leadPayload: [String: Any] = [
                "serviceDescription": cleanDescription,
                "serviceName": cleanServiceName,
                "serviceLocationAddress": [
                    "streetAddress": streetAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                    "city": city.trimmingCharacters(in: .whitespacesAndNewlines),
                    "state": state.trimmingCharacters(in: .whitespacesAndNewlines),
                    "zip": zip.trimmingCharacters(in: .whitespacesAndNewlines),
                    "latitude": firestoreNumber(latitude),
                    "longitude": firestoreNumber(longitude)
                ],
                "homeownerName": cleanHomeowner,
                "homeownerEmail": homeownerEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                "homeownerPhone": homeownerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            ]

            let db = Firestore.firestore()

            if let lead {
                var updatePayload = leadPayload
                updatePayload["updatedAt"] = FieldValue.serverTimestamp()

                try await db
                    .collection("homeownerServiceRequests")
                    .document(lead.id)
                    .updateData(updatePayload)
            } else {
                let newLeadId = "hosr_\(UUID().uuidString)"
                let user = masterDataManager.user
                let creatorName = [
                    user?.firstName.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    user?.lastName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                ]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")

                var createPayload: [String: Any] = [
                    "id": newLeadId,
                    "source": "Manual",
                    "status": "Pending",
                    "createdAt": Date(),
                    "companyId": company.id,
                    "companyName": company.name,
                    "creatorId": user?.id ?? "",
                    "creatorName": creatorName,
                    "customerId": "",
                    "customerName": "",
                    "serviceLocationId": "",
                    "bodyOfWaterId": "",
                    "equipmentIds": [],
                    "homeownerId": "",
                    "homeownerserviceLocationId": "",
                    "homeownerbodyOfWaterId": "",
                    "homeownerequipmentId": "",
                    "dateCompleted": NSNull()
                ]

                leadPayload.forEach { key, value in
                    createPayload[key] = value
                }

                try await db
                    .collection("homeownerServiceRequests")
                    .document(newLeadId)
                    .setData(createPayload)
            }

            dismiss()
        } catch {
            alertMessage = "Could not save lead: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    private func firestoreNumber(_ text: String) -> Any {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let value = Double(clean) else {
            return NSNull()
        }
        return value
    }
}

struct LeadTextField: View {
    let title: String
    @Binding var text: String
    var required: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization? = .words

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Text(title)
                if required {
                    Text("*")
                        .foregroundColor(.poolRed)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.secondary)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .autocorrectionDisabled(keyboardType == .emailAddress)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )
        }
    }
}

struct LeadChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.isEmpty ? "Unknown" : text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
    }
}

private func leadStatusColor(_ status: String) -> Color {
    switch status {
    case "Pending":
        return .poolBlue
    case "In Progress":
        return .orange
    case "Completed":
        return .poolGreen
    case "Cancelled":
        return .poolRed
    default:
        return .gray
    }
}

private func leadSourceColor(_ source: String) -> Color {
    switch source {
    case "Manual":
        return .purple
    case "Public":
        return .orange
    default:
        return .teal
    }
}

private extension View {
    func leadCardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

struct CompanyLeadConversionView: View {
    let lead: CompanyLeadSummary
    let companyId: String

    @State private var displayAsCompany: Bool
    @State private var firstName: String
    @State private var lastName: String
    @State private var companyName: String
    @State private var email: String
    @State private var phone: String
    @State private var billingNotes = ""

    @State private var addServiceLocation = true
    @State private var serviceLocationNickName = "Main"
    @State private var gateCode = ""
    @State private var dogName = ""
    @State private var serviceLocationNotes = ""
    @State private var preText = false

    @State private var addBodyOfWater = false
    @State private var bodyOfWaterName = "Main Pool"
    @State private var bodyOfWaterGallons = "15000"
    @State private var bodyOfWaterMaterial = "Plaster"
    @State private var bodyOfWaterWaterType = "Chlorine"
    @State private var bodyOfWaterNotes = ""

    @State private var addEquipment = false
    @State private var pumpName = "Pump"
    @State private var pumpNeedsService = false
    @State private var filterName = "Filter"
    @State private var filterNeedsService = true

    @State private var isSubmitting = false
    @State private var conversionComplete = false
    @State private var alertMessage: String?

    init(lead: CompanyLeadSummary, companyId: String) {
        self.lead = lead
        self.companyId = companyId

        let nameParts = lead.homeownerName
            .split(separator: " ")
            .map(String.init)

        _displayAsCompany = State(initialValue: false)
        _firstName = State(initialValue: nameParts.first ?? "")
        _lastName = State(initialValue: nameParts.dropFirst().joined(separator: " "))
        _companyName = State(initialValue: "")
        _email = State(initialValue: lead.homeownerEmail)
        _phone = State(initialValue: lead.homeownerPhone)
    }

    var body: some View {
        Form {
            Section("Lead") {
                detailRow("Status", lead.status)
                detailRow("Source", lead.normalizedSource)
                detailRow("Address", lead.streetAddress)
                if !lead.city.isEmpty {
                    detailRow("City", lead.city)
                }
                if !lead.customerId.isEmpty {
                    detailRow("Linked Customer", lead.connectionDetail)
                }
            }

            Section("Customer") {
                Toggle("Display as Company", isOn: $displayAsCompany)

                if displayAsCompany {
                    TextField("Company Name", text: $companyName)
                } else {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Billing Notes", text: $billingNotes, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section("Service Location") {
                Toggle("Add Service Location", isOn: $addServiceLocation)

                if addServiceLocation {
                    TextField("Nickname", text: $serviceLocationNickName)
                    TextField("Gate Code", text: $gateCode)
                    TextField("Dog Name", text: $dogName)
                    TextField("Notes", text: $serviceLocationNotes, axis: .vertical)
                        .lineLimit(2...5)
                    Toggle("Pre-text before arrival", isOn: $preText)
                }
            }

            if addServiceLocation {
                Section("Body of Water") {
                    Toggle("Add Body of Water", isOn: $addBodyOfWater)

                    if addBodyOfWater {
                        TextField("Name", text: $bodyOfWaterName)
                        TextField("Gallons", text: $bodyOfWaterGallons)
                            .keyboardType(.numberPad)
                        TextField("Material", text: $bodyOfWaterMaterial)
                        TextField("Water Type", text: $bodyOfWaterWaterType)
                        TextField("Notes", text: $bodyOfWaterNotes, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
            }

            if addBodyOfWater {
                Section("Equipment") {
                    Toggle("Add Equipment", isOn: $addEquipment)

                    if addEquipment {
                        TextField("Pump Name", text: $pumpName)
                        Toggle("Pump needs service", isOn: $pumpNeedsService)
                        TextField("Filter Name", text: $filterName)
                        Toggle("Filter needs service", isOn: $filterNeedsService)
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await submitConversion()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(conversionComplete ? "Converted" : "Convert Lead")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSubmitting || conversionComplete || companyId.isEmpty || !lead.customerId.isEmpty)
            }
        }
        .navigationTitle("Convert Lead")
        .alert("Lead Conversion", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue {
                    alertMessage = nil
                }
            }
        )
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .multilineTextAlignment(.trailing)
        }
    }

    @MainActor
    private func submitConversion() async {
        guard !companyId.isEmpty else {
            alertMessage = "Select a company before converting this lead."
            return
        }

        guard lead.customerId.isEmpty else {
            alertMessage = "This lead is already linked to a company customer."
            return
        }

        guard displayAsCompany ? !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Add a customer name before converting this lead."
            return
        }

        isSubmitting = true

        do {
            let response = try await FunctionsManager.shared.convertHomeownerServiceRequestToCompanyCustomer(
                companyId: companyId,
                leadId: lead.id,
                payload: conversionPayload()
            )
            conversionComplete = true
            alertMessage = "Converted to \(response["customerName"] as? String ?? "customer")."
        } catch {
            alertMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    private func conversionPayload() -> [String: Any] {
        [
            "displayAsCompany": displayAsCompany,
            "useDifferentBillingAddress": false,
            "formData": [
                "firstName": firstName,
                "lastName": lastName,
                "companyName": companyName,
                "email": email,
                "phone": phone,
                "billingNotes": billingNotes,
            ],
            "serviceLocationData": [
                "nickName": serviceLocationNickName,
                "gateCode": gateCode,
                "dogName": dogName,
                "notes": serviceLocationNotes,
                "preText": preText,
            ],
            "bodyOfWaterData": [
                "name": bodyOfWaterName,
                "gallons": bodyOfWaterGallons,
                "material": bodyOfWaterMaterial,
                "waterType": bodyOfWaterWaterType,
                "notes": bodyOfWaterNotes,
            ],
            "equipmentData": equipmentPayload(),
            "addServiceLocation": addServiceLocation,
            "addBodyOfWater": addBodyOfWater,
            "addEquipment": addEquipment,
        ]
    }

    private func equipmentPayload() -> [[String: Any]] {
        guard addEquipment else {
            return []
        }

        return [
            [
                "name": pumpName,
                "type": "Pump",
                "needsService": pumpNeedsService,
            ],
            [
                "name": filterName,
                "type": "Filter",
                "needsService": filterNeedsService,
            ],
        ].filter { item in
            guard let name = item["name"] as? String else {
                return false
            }
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

struct MyCompany_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    
    static var previews: some View {
        MyCompany(dataService:dataService )
    }
}
