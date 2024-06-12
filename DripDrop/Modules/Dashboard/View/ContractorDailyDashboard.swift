//
//  ContractorDailyDashboard.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContractorDailyDashboard: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    
    @StateObject var VM : MobileDailyRouteDisplayViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService))
    }
    
    @State var selectedDate:Date = Date()
    
    @State var showRepairSheet:Bool = false
    @State var showNewServiceStop:Bool = false
    @State var showMilage:Bool = false
    
    @State var enableReorder:Bool = false
    @State var enableMove:Bool = false
    @State var confirmMove:Bool = false
    @State var draggedItem:ServiceStop? = nil
    @State var recievdJobId:String? = nil
    @State var isLoading : Bool = false
    
    @State var startMilage : String = "0"
    @State var endMilage : String = "0"
    
    @State var startTime : Date = Date()
    @State var stopList:[ServiceStop] = []
    @State var selectedStopList:[ServiceStop] = []
    
    @State var activeDuration:Int = 0
    @State var listOfShoppingListItems:Int = 0
    @State private var draggedColor: ServiceStopOrder?
    @State private var orderList: [ServiceStopOrder] = []

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                VStack{
                    VStack(spacing: 0){
                        toolbarView
                        
                        if enableReorder {
                            Button(action: {
                                enableReorder = false
                            }, label: {
                                HStack{
                                    Text("Finish Reorder")
                                    
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Color.white)
                                .padding(8)
                                .background(Color.poolGreen)
                                .cornerRadius(16)
                            })
                            .padding(.horizontal,8)
                        } else {
                            routeInfo
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.listColor)
                }
                ScrollView(showsIndicators:false) {
                    if VM.serviceStopCompanyList.count != 0 {
                        ZStack{
                            VStack(spacing: 0){
                                if VM.reload {
                                    ProgressView()
                                } else {
                                    organizedListOfStops
                                    //                                    listOfStops
                                }
                            }
                        }
                    } else {
                        Text("No Route")
                        Spacer()
                    }
                    if isLoading {
                        ProgressView()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar{
            ToolbarItem{
                Button(action:{
                    showRepairSheet.toggle()
                }, label: {
                    Image(systemName: "wrench.adjustable.fill")
                    
                })
                .sheet(isPresented: $showRepairSheet,
                       content: {
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                showRepairSheet = false
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                        AddNewRepairRequest(dataService: dataService)
                    }
                })
            }
            ToolbarItem{
                NavigationLink(destination: {
                    ShoppingListView(dataService:dataService)
                    
                }, label: {
                    shoppingListIcon
                })
            }
            
            ToolbarItem{
                NavigationLink(value: Route.createNewJob(dataService: dataService), label: {
                    Image(systemName: "plus")
                    
                })
            }
            ToolbarItem(placement: .navigationBarLeading, content: {
                Button(action: {
                    masterDataManager.selectedCategory = .dashBoard
                    navigationManager.routes.removeLast()
                }, label: {
                    HStack{
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                })
            })
        }
        .onReceive(timer) { time in
            if var duration1 = VM.duration{
                if duration1 > -1 {
                    duration1 += 1
                    activeDuration = duration1
                }
                
            }
        }
        .task{
            if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                do {
                    try await VM.initalLoad(companyId: company.id, user: user ,date: selectedDate)
                    startTime = VM.activeRoute?.startTime ?? Date()
                    startMilage = String(VM.activeRoute?.startMilage ?? 0)
                    masterDataManager.selectedActiveRoute = VM.activeRoute
                } catch {
                    print(error)
                }
            }
        }
        
        .onChange(of: selectedDate, perform: { date in
            Task{
                if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                    do {
                        try await VM.initalLoad(companyId: company.id, user: user ,date: date)
                        startTime = VM.startTime ?? Date()
                    } catch {
                        print("\(error)")
                    }
                }
            }
        })
        .onChange(of: VM.serviceStopOrderList, perform: { datum in
            orderList = datum
        })
        .onChange(of: orderList, perform: { list in
            if VM.serviceStopOrderList != list {
                print(" - Order List")
                Task{
                    if let company = masterDataManager.selectedCompany, let activeRoute = VM.activeRoute {
                        do {
                            try await VM.updateOrderList(companyId: company.id, activeRouteId: activeRoute.id, newOrderList: list)
                        } catch {
                            print("")
                            print(error)
                            print("")

                        }
                    }
                }
                
            }
        })
    }
    func getColor(status:ActiveRouteStatus?)->Color{
        if let status = status {
            switch status {
            case .inProgress:
                return Color.yellow
            case .didNotStart:
                return Color.black.opacity(0.5)
            case .traveling:
                return Color.poolBlue
            case .onBreak:
                return Color.purple
            case .finished:
                return Color.poolGreen
            default:
                return Color.gray
            }
        } else {
            return Color.gray
        }
    }
    private var overlayView:some View {
        GeometryReader{ geo in
            ZStack(alignment: .leading){
                Rectangle()
                    .foregroundColor(Color.poolGreen)
                    .frame(width: CGFloat(Double(VM.finishedStops ?? 0)) / (Double(VM.totalStops ?? 1)) * geo.size.width)
                    .cornerRadius(10)
            }
        }
    }
}

extension ContractorDailyDashboard {
    var toolbarView: some View {
        VStack{
            
            HStack{
                Button(action: {
                    let calendar = Calendar.current
                    self.selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
                }, label: {
                    Image(systemName: "chevron.left.square.fill")
                        .font(.headline)
                })
                .sheet(isPresented: $showMilage, content: {
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                showMilage = false
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                        .padding()
                        startMilageView
                    }
                    .presentationDetents([.medium])
                    
                })
                Spacer()
                
                DatePicker(selection: $selectedDate, displayedComponents: .date) {
                    Text("\(weekDay(date: selectedDate))")
                        .foregroundColor(Color.basicFontText)
                        .lineLimit(1, reservesSpace: true)
                }
                Button(action: {
                    selectedDate = Date()
                }, label: {
                    Text("Today")
                })
                Spacer()
                Button(action: {
                    let calendar = Calendar.current
                    self.selectedDate = calendar.date(byAdding: .day, value: +1, to: selectedDate)!
                }, label: {
                    Image(systemName: "chevron.right.square.fill")
                        .font(.headline)
                })
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                
            }
        }
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 5))
    }
    var notRouteForToday: some View {
        VStack{
            Text("Unable to Update Route Today")
        }
    }
    var startMilageView: some View {
        VStack{
            VStack{
                HStack{
                    Text("Start Milage: ")
                    if VM.activeRoute?.startMilage == nil {
                        TextField(text: $startMilage, prompt: Text("Milage"), label: {
                            Text("Milage: ")
                        })
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .keyboardType(.decimalPad)
                    } else {
                        Text("\(startMilage)")
                    }
                    Spacer()
                }
                .padding(.leading,16)
                HStack{
                    Text("End Milage: ")
                    if VM.activeRoute?.endMilage == nil || VM.activeRoute?.endMilage == 0 {
                        TextField(text: $endMilage, prompt: Text("Milage"), label: {
                            Text("Milage: ")
                        })
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .keyboardType(.decimalPad)
                    } else {
                        Text("\(endMilage)")
                    }
                    Spacer()
                }
                .padding(.leading,16)
                Text("Add Edit Milage iwthout Changing Start Time / End Time")
                HStack{
                    Button(action: {
                        if startMilage != "0" {
                            if let company = masterDataManager.selectedCompany, let activeRoute = VM.activeRoute {
                                startTime = Date()
                                VM.updateActiveRoute(companyId: company.id,
                                                     activeRoute: activeRoute,
                                                     name: activeRoute.name,
                                                     date: activeRoute.date,
                                                     serviceStopsIds: activeRoute.serviceStopsIds,
                                                     startTime: Date(),
                                                     endTime: nil,
                                                     startMilage:startMilage,
                                                     endMilage:nil,
                                                     techId: activeRoute.techId,
                                                     techName: activeRoute.techName,
                                                     traineeId: activeRoute.traineeId,
                                                     traineeName: activeRoute.traineeName,
                                                     durationSeconds: activeRoute.durationSeconds,
                                                     distanceMiles: activeRoute.distanceMiles,
                                                     status: .inProgress)
                                showMilage = false
                            } else {
                                print("Error in Updating Route")
                            }
                        } else {
                            print("Milage is 0")
                        }
                    }, label: {
                        Text("Start Route")
                    })
                    .padding(5)
                    .background(Color.poolBlue)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
                    Spacer()
                    Button(action: {
                        if endMilage != "0" {
                            if let company = masterDataManager.selectedCompany, let activeRoute = VM.activeRoute {
                                VM.updateActiveRoute(companyId: company.id,
                                                     activeRoute: activeRoute,
                                                     name: activeRoute.name,
                                                     date: activeRoute.date,
                                                     serviceStopsIds: activeRoute.serviceStopsIds,
                                                     startTime: activeRoute.startTime ?? Date(),
                                                     endTime: Date(),
                                                     startMilage: String(activeRoute.startMilage ?? 0),
                                                     endMilage:endMilage,
                                                     techId: activeRoute.techId,
                                                     techName: activeRoute.techName,
                                                     traineeId: activeRoute.traineeId,
                                                     traineeName: activeRoute.traineeName,
                                                     durationSeconds: activeRoute.durationSeconds,
                                                     distanceMiles: activeRoute.distanceMiles,
                                                     status: .inProgress)
                                showMilage = false
                                print("Succesffully got end Milage")
                            } else {
                                print("Error in Updating Route")
                            }
                        } else {
                            print("Milage is 0")
                        }
                    }, label: {
                        Text("End Route")
                    })
                    .padding(5)
                    .background(Color.poolBlue)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
                }
                
            }
            Spacer()
        }
    }
    var routeInfo: some View {
        VStack{
            routeProgress
            routeTime
            routeMilage
            routeStatus
            moveStops
            
        }
        
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.gray)
        .cornerRadius(8)
        .padding(.top,8)
        .padding(.horizontal,8)
    }
    var routeProgress: some View {
        VStack{
            if let activeRoute = VM.activeRoute {
                
                ProgressView("\(String(activeRoute.finishedStops)) / \(String(activeRoute.totalStops))", value: Double(activeRoute.finishedStops), total: Double(activeRoute.totalStops))
                    .foregroundColor(Color.black)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
        }
    }
    var routeTime: some View {
        HStack{
            if let activeRoute = VM.activeRoute {
                Text("\(time(date:activeRoute.startTime))")
                    .foregroundColor(Color.reverseFontText)
                //                Text("Start: \(ThePoolApp.time(date: activeRouteVM.activeRoute?.startTime))")
                if let ending = activeRoute.endTime {
                    Text(" - \(ThePoolApp.time(date:ending))")
                        .foregroundColor(Color.reverseFontText)
                    Spacer()
                    Text("Duration: \(displayNumberAsMinAndHour(seconds: activeRoute.durationSeconds))")
                } else {
                    Spacer()
                    Text("\(displayNumberAsMinAndHour(seconds: activeDuration))")
                    
                }
            }
        }
    }
    var routeMilage: some View {
        VStack{
            if let activeRoute = VM.activeRoute {
                
                if let milage = activeRoute.startMilage {
                    HStack{
                        Text("Milage: \(Measurement(value: Double(milage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                            .foregroundColor(Color.reverseFontText)
                        
                        Spacer()
                        if let ending = VM.activeRoute?.endMilage {
                            Text("End: \(Measurement(value: Double(ending), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                                .foregroundColor(Color.reverseFontText)
                            
                            Button(action: {
                                showMilage.toggle()
                            }, label: {
                                Image(systemName: "square.and.pencil")
                            })
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                            
                        } else {
                            Button(action: {
                                showMilage.toggle()
                            }, label: {
                                Text("Add Distance")
                            })
                        }
                    }
                }
            }
        }
    }
    var routeStatus: some View {
        HStack{
            if let activeRoute = VM.activeRoute {
                
                Text("Status: ")
                    .foregroundColor(Color.reverseFontText)
                if activeRoute.status == .didNotStart {
                    Button(action: {
                        showMilage.toggle()
                    }, label: {
                        Text("Start")
                            .padding(5)
                            .background(getColor(status: VM.activeRoute?.status))
                            .cornerRadius(5)
                            .foregroundColor(Color.reverseFontText)
                    })
                    .background(Color.white // any non-transparent background
                        .cornerRadius(5)
                        .shadow(color: Color.black, radius: 2, x: 2, y: 2)
                    )
                } else {
                    Button(action: {
                        showMilage.toggle()
                    }, label: {
                        Text("\(VM.activeRoute?.status.rawValue ?? "Loading")")
                            .padding(5)
                            .background(getColor(status: VM.activeRoute?.status))
                            .cornerRadius(5)
                            .foregroundColor(Color.reverseFontText)
                    })
                    
                }
                Spacer()
                if let activeRoute = masterDataManager.selectedActiveRoute {
                    NavigationLink(value: Route.routeOverview(route: activeRoute,dataService: dataService), label: {
                        
                        Image(systemName: "map")
                            .foregroundColor(Color.poolWhite)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                    })
                } else {
                    NavigationLink(destination: {
                        ContentView()
                    }, label: {
                        Image(systemName: "map")
                            .foregroundColor(Color.poolWhite)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                        
                    })
                }
            }
        }
    }
    var moveStops: some View {
        HStack{
            if !enableMove && !enableReorder {
                Button(action: {
                    enableReorder.toggle()
                }, label: {
                    Text("Reorder")
                        .foregroundColor(Color.poolWhite)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                })
                
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                    .shadow(color: Color.black, radius: 2, x: 2, y: 2)
                )
            }
            if enableReorder {
                Button(action: {
                    enableReorder = false
                }, label: {
                    Text("Cancel Reorder")
                })
                .foregroundColor(Color.white)
                .padding(5)
                .background(Color.poolRed)
                .cornerRadius(5)
                .padding(5)
                Spacer()
                Button(action: {
                    print("Save Re Order")
                }, label: {
                    Text("Save")
                        .foregroundColor(Color.white)
                        .padding(5)
                        .background(Color.poolGreen)
                        .cornerRadius(5)
                })
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                    .shadow(color: Color.black, radius: 2, x: 2, y: 2)
                )
            }
            Spacer()
            if enableMove {
                Button(action: {
                    enableMove = false
                    selectedStopList = []
                }, label: {
                    Text("Cancel Move")
                })
                .foregroundColor(Color.white)
                .padding(5)
                .background(Color.poolRed)
                .cornerRadius(5)
                .padding(5)
                Spacer()
                Button(action: {
                    if selectedStopList.count > 0 {
                        confirmMove.toggle()
                    } else {
                        print("Selected Stop List Is Empty")
                    }
                }, label: {
                    Text("Confirm")
                })
                .disabled(selectedStopList.isEmpty)
                .foregroundColor(Color.white)
                .padding(5)
                .background(Color.poolGreen)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $confirmMove,
                       onDismiss: {
                    enableMove = false
                    selectedStopList = []
                },
                       content: {
                    MoveServiceStopsConfirmation(
                        dataService:dataService,
                        selectedServiceStopList: selectedStopList
                    )
                })
                
            }
            if !enableMove && !enableReorder{
                Button(action: {
                    enableMove.toggle()
                }, label: {
                    Text("Move")
                        .foregroundColor(Color.poolWhite)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                })
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                    .shadow(color: Color.black, radius: 2, x: 2, y: 2)
                )
            }
        }
        
    }
    var shoppingListIcon: some View {
        ZStack{
            ZStack{
                Image(systemName: "circle.fill")
                    .font(.title)
                    .foregroundColor(Color.poolBlue)
                Image(systemName: "list.clipboard.fill")
                    .font(.headline)
                    .foregroundColor(Color.poolWhite)
            }
            if let count = VM.shoppingListCount {
                
                VStack{
                    HStack{
                        if count >= 1 && count <= 50 {
                            Image(systemName: "circle.fill")
                                .foregroundColor(Color.white)
                                .font(.title)
                            
                            Image(systemName: "\(String(count)).circle.fill")
                                .foregroundColor(Color.red)
                                .font(.title)
                            
                        } else if count > 50 {
                            Image(systemName: "circle.fill")
                                .foregroundColor(Color.white)
                                .font(.title)
                            
                            Image(systemName: "circle.fill")
                                .foregroundColor(Color.red)
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
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    var organizedListOfStops: some View {
        ScrollView{
            VStack(spacing: 0){
                ForEach(orderList) { order in
                    HStack{
                        let serviceStop = VM.serviceStopList.first(where: {$0.id == order.serviceStopId })
                        if let serviceStop {
                            if enableMove {
                                if !serviceStop.finished {
                                    Button(action: {
                                        if selectedStopList.contains(serviceStop) {
                                            selectedStopList.removeAll(where: {$0.id == serviceStop.id})
                                        } else {
                                            selectedStopList.append(serviceStop)
                                        }
                                    }, label: {
                                        if selectedStopList.contains(serviceStop) {
                                            Image(systemName: "checkmark.square")
                                            
                                        } else {
                                            Image(systemName: "square")
                                        }
                                        RouteStopLabel(stop: serviceStop, index: order.order, selected:selectedStopList.contains(serviceStop))
                                    })
                                    .foregroundColor(Color.basicFontText)
                                }
                            } else if enableReorder {
                                HStack{
                                    Button(action: {
                                        
                                    }, label: {
                                        Image(systemName: "line.3.horizontal")
                                    })
                                    Spacer()
                                    RouteStopLabel(stop: serviceStop, index: order.order,selected:selectedStopList.contains(serviceStop))
                                }
                                .onDrag {
                                       self.draggedColor = order
                                       return NSItemProvider()
                                   }
                                .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: order, listData: $orderList, current: $draggedColor))

                                .padding(.horizontal,8)
                            }else {
                                RouteStopCardView(dataService: dataService, stop: serviceStop, index: order.order)
                            }
                        } else {
                            Text("Error")
                        }
                    }
                }
            }
        }
    }
    var listOfStops: some View {
        ScrollView{
            VStack(spacing: 0){
                ForEach(Array(VM.serviceStopCompanyList.enumerated()), id: \.offset) { index, value in
                    VStack(spacing:0){
                        HStack{
                            if enableMove{
                                
                                if !value.key.finished {
                                    VStack{
                                        Button(action: {
                                            if selectedStopList.contains(value.key) {
                                                selectedStopList.removeAll(where: {$0.id == value.key.id})
                                            } else {
                                                selectedStopList.append(value.key)
                                            }
                                        }, label: {
                                            if selectedStopList.contains(value.key) {
                                                Image(systemName: "checkmark.square")
                                                
                                            } else {
                                                Image(systemName: "square")
                                            }
                                            RouteStopLabel(stop: value.key, index: index,selected:selectedStopList.contains(value.key))
                                        })
                                        .foregroundColor(Color.basicFontText)
                                        HStack{
                                            Rectangle()
                                                .fill(selectedStopList.contains(value.key) ? Color.poolGreen.opacity(0.5) : Color.darkGray.opacity(0.5))
                                                .frame(width: 4)
                                            Spacer()
                                            if let name = value.value.name {
                                                Text("\(name)")
                                                    .font(.footnote)
                                                    .foregroundColor(Color.reverseFontText)
                                                    .padding(8)
                                                    .background(Color.teal)
                                                    .cornerRadius(3)
                                            }
                                        }
                                        .padding(EdgeInsets(top: 0, leading: 22.5, bottom: 0, trailing: 10))
                                        
                                    }
                                }
                            } else if enableReorder {
                                VStack{
                                    Button(action: {
                                        
                                    }, label: {
                                        Image(systemName: "line.3.horizontal")
                                    })
                                    
                                    RouteStopLabel(stop: value.key, index: index,selected:selectedStopList.contains(value.key))
                                    HStack{
                                        Rectangle()
                                            .fill(selectedStopList.contains(value.key) ? Color.poolGreen.opacity(0.5) : Color.darkGray.opacity(0.5))
                                            .frame(width: 4)
                                        Spacer()
                                        if let name = value.value.name {
                                            Text("\(name)")
                                                .font(.footnote)
                                                .foregroundColor(Color.reverseFontText)
                                                .padding(8)
                                                .background(Color.teal)
                                                .cornerRadius(3)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 22.5, bottom: 0, trailing: 10))
                                    
                                }
                                
                            } else {
                                VStack{
                                    RouteStopCardView(dataService: dataService, stop: value.key, index: VM.serviceStopList.firstIndex(of: value.key) ?? 0)
                                    HStack{
                                        Rectangle()
                                            .fill(selectedStopList.contains(value.key) ? Color.poolGreen.opacity(0.5) : Color.darkGray.opacity(0.5))
                                            .frame(width: 4)
                                        Spacer()
                                        if let name = value.value.name {
                                            Text("\(name)")
                                                .font(.footnote)
                                                .foregroundColor(Color.reverseFontText)
                                                .padding(8)
                                                .background(Color.teal)
                                                .cornerRadius(3)
                                        }
                                    }
                                    .padding(EdgeInsets(top: 0, leading: 22.5, bottom: 0, trailing: 10))
                                    
                                }
                            }
                        }
                        
                    }
                    //                        .onDrag({
                    //                        self.draggedItem = stop
                    //                            return NSItemProvider(item: nil, typeIdentifier: stop.id)
                    //                    }) .onDrop(of: [UTType.text], delegate: MyDropDelegate(item: stop, items: $stopList, draggedItem: $draggedItem))
                    
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
    }
    
    var toolbar: some View {
        HStack{
            Spacer()
            NavigationLink(destination: {
                AddNewRepairRequest(dataService: dataService)
                
            },
                           label: {
                Image(systemName: "wrench.adjustable.fill")
                
            })
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            
            NavigationLink(destination: {
                ShoppingListView(dataService: dataService)
                
            }, label: {
                shoppingListIcon
            })
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            Button(action: {
                showNewServiceStop.toggle()
            }, label: {
                Image(systemName: "plus")
                
            })
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .sheet(isPresented: $showNewServiceStop,
                   content: {
                VStack{
                    HStack{
                        Spacer()
                        Button(action: {
                            showNewServiceStop = false
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    AddNewJobView(dataService: dataService)
                }
                
            })
        }
        
    }
}
struct DragRelocateDelegate: DropDelegate {
    
    let item: ServiceStopOrder
    
    @Binding var listData: [ServiceStopOrder]
    @Binding var current: ServiceStopOrder?

    
    func dropEntered(info: DropInfo) {
        if item != current {
            if let current {
                print("Change of Order")
                let from = listData.firstIndex(of: current)!
                let to = listData.firstIndex(of: item)!
                if listData[to].id != current.id {
                    listData.move(fromOffsets: IndexSet(integer: from),
                                  toOffset: to > from ? to + 1 : to)
                }
            } else {
                print("Change of Order NIL")

            }
        }
    }

    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    
    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}
