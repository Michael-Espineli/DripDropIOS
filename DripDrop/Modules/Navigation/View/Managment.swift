//
//  Managment.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//


import SwiftUI
import MapKit
import Firebase
import Charts

struct Managment: View {
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
                    if let role = masterDataManager.role {
                        VStack(alignment: .leading,spacing: 20){
                    
                            if role.permissionIdList.contains("7") {
                                
                                //----------------------------------------
                                //Add Back in During Roll out of Phase 2
                                //----------------------------------------
        //                        snapshot
                                management
                            }
                       
                        }
                    }
                }
                .padding(.horizontal,8)
                .foregroundColor(Color.basicFontText)
                .fontDesign(.monospaced)
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
                    try await VM.onLoad(companyId: company.id, userId: user.id,category: "Management")
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of:  masterDataManager.currentCompany, perform: { selectedCompany in
            Task{
                if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                    do {
                        try await VM.onLoad(companyId: company.id, userId: user.id, category: "Management")
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


extension Managment{

    var snapshot: some View {
        VStack{
            Chart(VM.buildActivities) { buildActivity in
                BarMark(
                    x: .value("Date", buildActivity.date, unit: .month),
                    y: .value("Total Count", buildActivity.numberOfUnits)
                )
                .foregroundStyle(
                    by: .value("Name", buildActivity.name)
                )
            }
            /// Customize the colors for each scheme
            .chartForegroundStyleScale([
                "Customers" : .blue,
                "Technicians": .orange
            ])
        }
    }
    var management: some View {
        VStack{
            if let role = masterDataManager.role {
                    HStack{
                        Text("Management")
                        Spacer()
                    }
                    .modifier(HeaderModifier())
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
                    internalRoutes
                    Divider()
                    externalRoutes
                    Divider()
                    businesses
                    Divider()
                    fleet
                    Divider()
                    payRoll
                    Divider()
                    venders
                    Divider()
                //----------------------------------------
                //Add Back in During Roll out of Phase 2
                //----------------------------------------
//                    routeSandBox
//                    Divider()
                
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

    
    var routeBuilder: some View {
        VStack{
            HStack{
                Text("Live Route Managment")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                    .background(Color.pink)

                Spacer()
                
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.routeBuilder(dataService: dataService), label: {
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

    var routeOverView: some View {
        VStack{
            HStack{
                Text("Internal And External Routes")
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
                        masterDataManager.selectedCategory = .companyRouteOverView
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
    var internalRoutes: some View {
        VStack{
            HStack{
                Text("Internal Routes")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                if UIDevice.isIPhone {
                    NavigationLink(value:Route.internalRouteOverView(dataService:dataService), label: {
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
                        masterDataManager.selectedCategory = .companyRouteOverView
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
    
    var routeSandBox: some View {
        VStack{
            HStack{
                Text("Route Sandbox")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                    .background(Color.pink)

                Spacer()
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
    

}

