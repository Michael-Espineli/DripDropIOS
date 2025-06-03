//
//  All.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct All: View {
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var VM : AllViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AllViewModel(dataService: dataService))
    }
    
    let recentActivity: [Route] = []
    @State private var isLoading: Bool = true
    @State private var showNewChat: Bool = false
    @State private var showSF: Bool = false
    @State private var symbolName: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            //Main Content
            ScrollView(showsIndicators: false){
                VStack(spacing: 10){
                    //DEVELOPER TAKE AWAY AFTER FIXING RECENT LINKS
                    //----------------------------------------
                    //Add Back in During Roll out of Phase 3
                    //----------------------------------------

                    /*
                    if VM.recentActivityList.count == 0 {
                        recentlyOpenedLoading
                    } else {
                        recentlyOpened
                    }
                     */
//                  mainContentLoading
                    mainContent
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            }
            if isLoading {
                VStack{
                    ProgressView()
                }
            }
        }
  
        .task{
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: company.id, user: user)
                } catch {
                    print("onLoad - [All]")
                    print(error)
                }
            }
        }
        .onChange(of: VM.isLoading, perform: { loading in
            if loading {
                isLoading = loading
                
            } else {
                withAnimation(Animation.linear(duration: 0.1)) {
                    isLoading = loading
                }
            }
        })
        .onDisappear(perform: {
            VM.onLeavePage()
        })
//        .onReceive(timer) { time in
//            VM.shiftDuration += 1
//        }
    }
}

struct All_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        All(dataService: dataService)
    }
}
extension All {
    
    var recentlyOpened: some View {
        RecentlyOpenedList(dataService: dataService, recentActivityList: VM.recentActivityList)

    }
    var recentlyOpenedLoading: some View {
        HStack(spacing:6){
            VStack(spacing:3){
                ForEach(1...4,id:\.self){ route in
                    HStack(spacing:3){
                        ZStack{
                            Color.poolBlue.opacity(0.5)
                            Image(systemName: "doc.fill")
                                .foregroundColor(Color.poolWhite.opacity(0.5))
                        }
                        .frame(width: 40,height: 40)
                        Divider()
                        Text("")
                            .font(.callout)
                            .lineLimit(2)
                        ProgressView()
                        Spacer()
                    }
                    .foregroundColor(Color.white)
                    .background(Color.darkGray.opacity(0.5))
                    .cornerRadius(6)
                    .fontDesign(.monospaced)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            VStack(spacing:3){
                ForEach(1...4,id:\.self){ route in
                    HStack(spacing:3){
                        ZStack{
                            Color.poolBlue.opacity(0.5)
                            Image(systemName: "doc.fill")
                                .foregroundColor(Color.poolWhite.opacity(0.5))
                        }
                        .frame(width: 40,height: 40)
                        Divider()
                        Text("")
                            .font(.callout)
                            .lineLimit(2)
                        ProgressView()
                        Spacer()
                    }
                    .foregroundColor(Color.white)
                    .background(Color.darkGray.opacity(0.5))
                    .cornerRadius(6)
                    .fontDesign(.monospaced)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    
    //Memory Leak
    
    var allCompanies: some View {
        VStack{
            Divider()
            if masterDataManager.allCompanies.count == 0 {
                Text("No Companies")
                    .modifier(MockButtonModifier())
            } else {
                HStack{
                    Text("Preview For Work")
                        .font(.headline)
                    Spacer()
                }
                ForEach(masterDataManager.allCompanies) { company in
                    WorkPreviewBasedOnCompany(dataService: dataService, company: company)
                    Divider()
                }
            }
        }
    }
    var routePreview: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Preview For Work")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.companyRouteOverView(dataService: dataService), label: {
                        HStack{
                            Text("Details")
                            Image(systemName: "arrow.right")
                            
                        }
                    })
                    NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(.gray.opacity(0.5))
                                    .frame(width: 90, height: 90)
                                
                                Circle()
                                    .trim(from: 0, to: Double(VM.finishedStops ?? 0) / Double(VM.totalStops ?? 1))
                                    .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                Text("\(String( VM.finishedStops ?? 0)) / \(String( VM.totalStops ?? 0))")
                                    .foregroundColor(Color.basicFontText)
                                    .font(.headline)
                                    .bold(true)
                            }
                            .foregroundColor(Color.basicFontText)
                            Spacer()
                            
                            if let activeRoute = VM.activeRoute {
                                VStack(alignment: .leading){
                                    VStack{
                                        Text("Miles:")
                                        HStack{
                                            if let startMilage = activeRoute.startMilage {
                                                Text("\(startMilage)")
                                                    .foregroundColor(Color.white)
                                            }
                                            if let endMilage = activeRoute.endMilage {
                                                Text(" - \(endMilage)")
                                                    .foregroundColor(Color.white)
                                            }
                                        }
                                    }
                                    VStack{
                                        Text("Time:")
                                        HStack{
                                            if let startTime = activeRoute.startTime {
                                                Text("\(time(date:startTime))")
                                                    .foregroundColor(Color.white)
                                            }
                                            if let endTime = activeRoute.endTime {
                                                Text(" - \(time(date:endTime))")
                                                    .foregroundColor(Color.white)
                                            }
                                        }
                                    }
                                }
                                .font(.footnote)
                            }
                        }
                        .padding(8)
                        .background(Color.darkGray)
                        .cornerRadius(8)
                    })

                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .companyRouteOverView
                    }, label: {
                        HStack{
                            Text("Details")
                            Image(systemName: "arrow.right")
                            
                        }
                    })
                    Button(action: {
                        
                    }, label: {
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(.gray.opacity(0.5))
                                    .frame(width: 90, height: 90)
                                
                                Circle()
                                    .trim(from: 0, to: Double(VM.finishedStops ?? 0) / Double(VM.totalStops ?? 1))
                                    .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                Text("\(String( VM.finishedStops ?? 0)) / \(String( VM.totalStops ?? 0))")
                                    .foregroundColor(Color.basicFontText)
                                    .font(.headline)
                                    .bold(true)
                            }
                            .foregroundColor(Color.basicFontText)
                            Spacer()
                            
                            if let activeRoute = VM.activeRoute {
                                VStack(alignment: .leading){
                                    VStack{
                                        Text("Miles:")
                                        HStack{
                                            if let startMilage = activeRoute.startMilage {
                                                Text("\(startMilage)")
                                                    .foregroundColor(Color.white)
                                            }
                                            if let endMilage = activeRoute.endMilage {
                                                Text(" - \(endMilage)")
                                                    .foregroundColor(Color.white)
                                            }
                                        }
                                    }
                                    VStack{
                                        Text("Time:")
                                        HStack{
                                            if let startTime = activeRoute.startTime {
                                                Text("\(time(date:startTime))")
                                                    .foregroundColor(Color.white)
                                            }
                                            if let endTime = activeRoute.endTime {
                                                Text(" - \(time(date:endTime))")
                                                    .foregroundColor(Color.white)
                                            }
                                        }
                                    }
                                }
                                .font(.footnote)
                            }
                        }
                        .padding(8)
                        .background(Color.darkGray)
                        .cornerRadius(8)
                    })
                }
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    
    var routePreviewLoading: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Preview For Work")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.clear)
                    .background(Color.darkGray.opacity(0.5))
                    .cornerRadius(8)
                Spacer()
                
                HStack{
                    Text("Details")
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(Color.clear)
                .background(Color.darkGray.opacity(0.5))
                .cornerRadius(8)
            }
            HStack{
                ZStack{
                    Circle()
                        .fill(.gray.opacity(0.5))
                        .frame(width: 90, height: 90)
                    Circle()
                        .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .frame(width: 80, height: 80)
                }
                Spacer()
                VStack(alignment: .leading){
                    Text("Miles: ")
                        .foregroundColor(Color.clear)
                    Text("Time: ")
                        .foregroundColor(Color.clear)
                    Text("Lorem lipsum")
                        .foregroundColor(Color.clear)
                }
            }
            .padding(8)
            .background(Color.darkGray.opacity(0.5))
            .cornerRadius(8)
        }
        .fontDesign(.monospaced)
    }
    
    var mainContentLoading: some View {
        ZStack{
            VStack(alignment: .leading){
                VStack{
                    HStack{
                        Text("Alerts")
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
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(1...5,id:\.self){ route in
                                Rectangle()
                                    .fill(Color.poolBlue.opacity(0.5))
                                    .frame(width: 100, height: 100)
                            }
                        }
                    }
                }
                .foregroundColor(Color.basicFontText)
                .fontDesign(.monospaced)
                .font(.headline)
                VStack{
                    HStack{
                        Text("Messages")
                            .font(.headline)
                        if let unreadChats = VM.unreadChatCount{
                            if unreadChats != 0 {
                                Text("Unread: \(String(format:  "%.2f", unreadChats))")
                            }
                        }
                        Spacer()
                        NavigationLink(value: Route.chats(dataService: dataService), label: {
                            HStack{
                                Text("More")
                                Image(systemName: "arrow.right")
                                
                            }
                        })
                    }
                    .foregroundColor(Color.basicFontText)
                    .fontDesign(.monospaced)
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(1...5,id:\.self){ datum in
                                ZStack{
                                    Circle()
                                        .fill(Color.darkGray.opacity(0.5))
                                    Circle()
                                        .stroke(Color.poolBlue.opacity(0.5), lineWidth:4)
                                    
                                }
                                .frame(width: 75,height: 75)
                                .padding(2)
                                .padding(.horizontal,4)

                            }
                        }
                        .font(.largeTitle)
                    }
                    .frame(height: 120)
                }
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
    var mainContent: some View {
        ZStack{
            if let user = masterDataManager.user {
                
                VStack(alignment: .leading){
                        //----------------------------------------
                        //Add Back in During Roll out of Phase 2
                        //----------------------------------------

//                    chatView
                    
//                    if  VM.repairRequestCount != 0 || VM.listOfUnreadChats.count != 0 || VM.toDoListCount != 0 || VM.purchaseCount != 0  || VM.shoppingListItemCount != 0 {
//                        alerts
//                    }
                    
                    shifts
                    workLoad
                    invoices
                }
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }

    
    var alerts: some View {
        VStack{
            HStack{
                Text("Alerts")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value: Route.alerts(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            if VM.isAlertLoading {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(1...5,id:\.self){ datum in
                            Rectangle()
                                .fill(Color.poolBlue)
                                .frame(width: 75, height: 75)
                                .cornerRadius(5)
                        }
                    }
                    .font(.largeTitle)
                }
                .frame(height: 100)

            } else {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        if let count = VM.repairRequestCount {
                            if count != 0 {
                                NavigationLink(value: Route.repairRequestList(dataService: dataService), label: {
                                    Rectangle()
                                        .fill(Color.poolBlue)
                                        .frame(width: 75, height: 75)
                                        .cornerRadius(5)
                                        .overlay(
                                            ZStack{
                                                Image(systemName: "wrench.adjustable.fill")
                                                    .foregroundColor(Color.white)
                                                    .font(.largeTitle)
                                                HStack{
                                                    VStack{
                                                        ZStack(alignment: .topLeading){
                                                            if count >= 1 && count <= 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "\(String(count)).circle.fill")
                                                                    .foregroundColor(Color.poolGreen)
                                                                    .font(.title)
                                                                
                                                            } else if count > 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.poolGreen)
                                                                    .font(.title)
                                                                
                                                                    .overlay{
                                                                        HStack{
                                                                            Text("50")
                                                                                .font(.title)
                                                                            
                                                                            Image(systemName: "plus")
                                                                                .font(.title)
                                                                            
                                                                            
                                                                        }
                                                                    }
                                                            }
                                                            
                                                            
                                                        }
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                }
                                                .padding(8)
                                            }
                                        )
                                })
                            }
                        }
                        
                        if let count = VM.toDoListCount {
                            if count != 0 {
                                NavigationLink(value: Route.toDoList(dataService: dataService), label: {
                                    
                                    Rectangle()
                                        .fill(Color.poolBlue)
                                        .frame(width: 75, height: 75)
                                        .cornerRadius(5)
                                        .overlay(
                                            ZStack{
                                                Image(systemName: "doc.plaintext.fill")
                                                    .foregroundColor(Color.white)
                                                    .font(.largeTitle)
                                                HStack{
                                                    VStack{
                                                        ZStack(alignment: .topLeading){
                                                            
                                                            if count >= 1 && count <= 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "\(String(count)).circle.fill")
                                                                    .foregroundColor(Color.poolGreen)
                                                                    .font(.title)
                                                                
                                                            } else if count > 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.poolGreen)
                                                                    .font(.title)
                                                                
                                                                    .overlay{
                                                                        HStack{
                                                                            Text("50")
                                                                                .font(.title)
                                                                            
                                                                            Image(systemName: "plus")
                                                                                .font(.title)
                                                                            
                                                                        }
                                                                    }
                                                            }
                                                        }
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                }
                                                .padding(8)
                                            }
                                        )
                                })
                            }
                        }
                        if let count = VM.purchaseCount {
                            if count != 0 {
                                NavigationLink(value: Route.purchasedItemsList(dataService: dataService), label: {
                                    Rectangle()
                                        .fill(Color.poolBlue)
                                        .frame(width: 75, height: 75)
                                        .cornerRadius(5)
                                        .overlay(
                                            ZStack{
                                                Image(systemName: "testtube.2")
                                                    .foregroundColor(Color.white)
                                                    .font(.largeTitle)
                                                
                                                HStack{
                                                    VStack{
                                                        ZStack(alignment: .topLeading){
                                                            if count >= 1 && count <= 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "\(String(count)).circle.fill")
                                                                    .foregroundColor(Color.poolGreen)
                                                                    .font(.title)
                                                                
                                                            } else if count > 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.poolGreen)
                                                                    .font(.title)
                                                                
                                                                    .overlay{
                                                                        HStack{
                                                                            Text("50")
                                                                                .font(.title)
                                                                            
                                                                            Image(systemName: "plus")
                                                                                .font(.title)
                                                                            
                                                                            
                                                                        }
                                                                        
                                                                    }
                                                                
                                                            }
                                                        }
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                }
                                                .padding(8)
                                                
                                            }
                                        )
                                })
                            }
                        }
                        if let count = VM.shoppingListItemCount {
                            if count != 0 {
                                NavigationLink(value: Route.shoppingList(dataService: dataService), label: {
                                    
                                    Rectangle()
                                        .fill(Color.poolBlue)
                                        .frame(width: 75, height: 75)
                                        .cornerRadius(5)
                                        .overlay(
                                            ZStack{
                                                Image(systemName: "cart.fill")
                                                    .foregroundColor(Color.white)
                                                    .font(.largeTitle)
                                                
                                                HStack{
                                                    VStack{
                                                        ZStack(alignment: .topLeading){
                                                            if count >= 1 && count <= 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "\(String(count)).circle.fill")
                                                                    .foregroundColor(Color.poolRed)
                                                                    .font(.title)
                                                                
                                                            } else if count > 50 {
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.white)
                                                                    .font(.title)
                                                                
                                                                Image(systemName: "circle.fill")
                                                                    .foregroundColor(Color.poolRed)
                                                                    .font(.title)
                                                                    .overlay{
                                                                        HStack{
                                                                            Text("50")
                                                                                .font(.title)
                                                                            Image(systemName: "plus")
                                                                                .font(.title)
                                                                        }
                                                                    }
                                                            }
                                                        }
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                }
                                                .padding(8)
                                            }
                                        )
                                })
                            }
                            if let count = VM.unreadChatCount {
                                if count != 0 {
                                    NavigationLink(value: Route.chats(dataService: dataService), label: {
                                        
                                        Rectangle()
                                            .fill(Color.poolBlue)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(16)
                                            .overlay(
                                                ZStack{
                                                    Image(systemName: "message.fill")
                                                        .font(.largeTitle)
                                                        .foregroundColor(Color.white)
                                                    
                                                    HStack{
                                                        VStack{
                                                            ZStack(alignment: .topLeading){
                                                                if count >= 1 && count <= 50 {
                                                                    Image(systemName: "circle.fill")
                                                                        .foregroundColor(Color.white)
                                                                        .font(.title)
                                                                    
                                                                    Image(systemName: "\(String(count)).circle.fill")
                                                                        .foregroundColor(Color.poolRed)
                                                                        .font(.title)
                                                                    
                                                                } else if count > 50 {
                                                                    Image(systemName: "circle.fill")
                                                                        .foregroundColor(Color.white)
                                                                        .font(.title)
                                                                    
                                                                    Image(systemName: "circle.fill")
                                                                        .foregroundColor(Color.poolRed)
                                                                        .font(.title)
                                                                    
                                                                        .overlay{
                                                                            HStack{
                                                                                Text("50")
                                                                                    .font(.title)
                                                                                
                                                                                Image(systemName: "plus")
                                                                                    .font(.title)
                                                                                
                                                                                
                                                                            }
                                                                        }
                                                                    
                                                                    
                                                                }
                                                            }
                                                            Spacer()
                                                        }
                                                        Spacer()
                                                    }
                                                    .padding(8)
                                                }
                                            )
                                    })
                                    
                                }
                            }
                        }
                    }
                }
                .frame(height: 100)
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
        .font(.headline)
        
    }
    
    var chatView: some View {
        VStack{
            if let user = masterDataManager.user {
                HStack{
                    Text("Messages")
                        .font(.headline)
                 
                    Spacer()
                    NavigationLink(value: Route.chats(dataService: dataService), label: {
                        
                        HStack{
                            Text("More")
                            Image(systemName: "arrow.right")
                            
                        }
                    })
                }
                .foregroundColor(Color.basicFontText)
                .fontDesign(.monospaced)
                if let unreadChats = VM.unreadChatCount{
                    if unreadChats != 0 {
                        Text("Unread: \(String(unreadChats))")
                    }
                }
                if VM.isChatLoading {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(1...5,id:\.self){ datum in
                                ZStack{
                                    Circle()
                                        .fill(Color.darkGray.opacity(0.5))
                                    Circle()
                                        .stroke(Color.poolBlue.opacity(0.5), lineWidth:4)
                                    
                                }
                                .frame(width: 75,height: 75)
                                .padding(2)
                                .padding(.horizontal,4)

                            }
                        }
                        .font(.largeTitle)
                    }
                    .frame(height: 100)
                } else {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            Button(action: {
                                    //DEVELOPER ADD ROUTE FOR SEND NEW CHAT MESSAGE
                                self.showNewChat.toggle()
                            }, label: {
                                Circle()
                                    .fill(Color.poolBlue)
                                    .frame(width: 75,height: 75)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.largeTitle)
                                            .foregroundColor(Color.listColor)
                                    )
                            })
                            .padding(.vertical,5)
                            .sheet(isPresented: $showNewChat, content: {
                                AddNewChatView(dataService: dataService, receivedCustomer: nil)
                            })
                            HStack{
                                ForEach(VM.listOfUnreadChats){ datum in
                                    
                                    NavigationLink(value: Route.chat(chat:datum,dataService: dataService), label: {
                                        if let person = datum.participants.first(where: {$0.userId != user.id }) {
                                            ChatProfileIcon(image:  URL(string: person.userImage)!, hasNewMessage: datum.userWhoHaveNotRead.contains(where: {$0 == user.id}))
                                                .padding(2)
                                                .padding(.horizontal,4)
                                            
                                        } else {
                                            Circle()
                                                .fill(Color.poolGreen)
                                                .frame(width: 75, height: 75)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .font(.title)
                                                        .foregroundColor(Color.white)
                                                )
                                                .padding(2)
                                                .padding(.horizontal,4)
                                        }
                                        
                                    })
                                }
                                ForEach(VM.listOfChats){ datum in
                                    NavigationLink(value: Route.chat(chat:datum,dataService: dataService), label: {
                                        
                                        if let person = datum.participants.first(where: {$0.userId != user.id }), let url =  URL(string: person.userImage){
                                            ChatProfileIcon(image:  url, hasNewMessage: datum.userWhoHaveNotRead.contains(where: {$0 == user.id}))
                                                .padding(2)
                                                .padding(.horizontal,4)
                                            
                                        } else {
                                            Circle()
                                                .fill(Color.poolGreen)
                                                .frame(width: 75, height: 75)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .font(.title)
                                                        .foregroundColor(Color.white)
                                                )
                                                .padding(2)
                                                .padding(.horizontal,4)
                                        }
                                    })
                                    
                                }
                            }
                            .font(.largeTitle)
                        }
                    }
                    .frame(height: 100)
                }
            }
        }
    }
    
    var outStandingInvoicesPreview: some View {
        VStack{
            HStack{
                Text("Out Standing Invocies")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value: Route.chats(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    ForEach(1...10,id:\.self){ datum in
                        Rectangle()
                            .fill(Color.poolGreen)
                            .frame(width: 100, height: 100)
                    }
                }
            }
        }
    }
    
    var shifts: some View {
        VStack{
            HStack{
                Text("Shifts")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                NavigationLink(value: Route.workLogList(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }
            .padding(.bottom,8)
            WorkLogIn(dataService: dataService)
        }
    }
    var workLoad: some View {
        VStack{
            HStack{
                Text("Contracts")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value: Route.buisnessContracts(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }
            Divider()
            
 //---------------------
//Developer Maybe Add Back in later
//----------------------
//            HStack{
//                Text("Recurring Labor Contracts")
//                    .font(.headline)
//                    .fontDesign(.monospaced)
//                    .foregroundColor(Color.basicFontText)
//                Spacer()
//                NavigationLink(value: Route.recurringLaborContracts(dataService: dataService), label: {
//                    HStack{
//                        Text("More")
//                        Image(systemName: "arrow.right")
//                        
//                    }
//                })
//            }
//            ScrollView(.horizontal, showsIndicators: false){
//                HStack{
//                    ForEach(VM.receivedRecurringLaborContracts){ contract in
//                        NavigationLink(value: Route.recurringLaborContracts(dataService: dataService), label: {
//                            Text(contract.senderName)
//
//                        })
//                    }
//                }
//            }
//            Divider()
//            HStack{
//                Text("Labor Contracts")
//                    .font(.headline)
//                    .fontDesign(.monospaced)
//                    .foregroundColor(Color.basicFontText)
//                Spacer()
//                NavigationLink(value: Route.laborContracts(dataService: dataService), label: {
//                    HStack{
//                        Text("More")
//                        Image(systemName: "arrow.right")
//                        
//                    }
//                })
//            }
//            ScrollView(.horizontal, showsIndicators: false){
//                HStack{
//                    ForEach(VM.receivedLaborContracts){ contract in
//                        NavigationLink(value: Route.laborContracts(dataService: dataService), label: {
//                            Text(contract.senderName)
//
//                        })
//                    }
//                }
//            }
//            Divider()
            HStack{
                Text("Job Boards")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                NavigationLink(value: Route.jobPosting(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    ForEach(VM.receivedLaborContracts){ contract in
                        NavigationLink(value: Route.laborContracts(dataService: dataService), label: {
                            Text(contract.senderName)

                        })
                    }
                }
            }
            Divider()
        }
    }
    var toDos: some View {
        VStack{
            HStack{
                Text("To Do List")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
                
                NavigationLink(value: Route.chats(dataService: dataService), label: {
                    
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                        
                    }
                })
            }
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    ForEach(1...10,id:\.self){ datum in
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 100, height: 100)
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
                
                NavigationLink(value: Route.accountsReceivableList(dataService: dataService), label: {
                    HStack{
                        Text("More")
                        Image(systemName: "arrow.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }
            .padding(.bottom,8)
        }
    }
}
