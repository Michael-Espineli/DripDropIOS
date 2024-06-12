//
//  EmployeeDailyDashboard.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct EmployeeDailyDashboard: View {
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

    @State var duration:Int = 0
    @State var listOfShoppingListItems:Int = 3
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0){
                toolbarView
                    if VM.serviceStopList.count != 0 {
                        ZStack{
                            VStack(spacing: 0){
                                routeInfo
                                listOfStops
                            }
                        }
                    } else {
                        Text("No Route")
                        Spacer()
                    }
                if isLoading {
                    Spacer()
                      
                    ProgressView()
                    Spacer()
                }
            }
        }
        .toolbar{
            ToolbarItem{
                Button(action:{
                    showRepairSheet.toggle()
                }, label: {
                    Image(systemName: "wrench.adjustable.fill")
                    
                })
                .fullScreenCover(isPresented: $showRepairSheet,
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
        .navigationBarBackButtonHidden(true)
//        .navigationTitle("\(user.firstName ?? "") \(user.lastName ?? "")")
        .onReceive(timer) { time in
            if var duration1 = VM.duration{
                if duration1 > -1 {
                    duration1 += 1
                    duration = duration1
                }
            }
        }
        .task{
            if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                do {
                    
                    try await VM.initalLoad(companyId: company.id, user: user, date:selectedDate)
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
                        try await VM.initalLoad(companyId: company.id, user: user,date:date)
                        startTime = VM.startTime ?? Date()
                    } catch {
                        print("\(error)")
                    }
                 }
            }
        })
         
    }
    func getColor(status:String)->Color{
        switch status {
        case "In Progress":
            return Color.yellow
        case "Did Not Start":
            return Color.black.opacity(0.5)
        case "Traveling":
            return Color.poolBlue
        case "Break":
            return Color.purple
        case "Finished":
            return Color.poolGreen
        default:
            return Color.gray
        }
    }
    private var overlayView:some View {
        GeometryReader{ geo in
            ZStack(alignment: .leading){
                Rectangle()
                    .foregroundColor(Color.poolGreen)
                    .frame(width: CGFloat(Double(VM.finishedStops ?? 0)) / Double((VM.totalStops ?? 1)) * geo.size.width)
                    .cornerRadius(10)
            }
        }
    }
}

extension EmployeeDailyDashboard {
    var toolbarView: some View {
        VStack{
//            HStack{
//                Button(action: {
//                    navigationManager.selectedCategory = .dashBoard
//                }, label: {
//                    HStack{
//                        Image(systemName: "chevron.left")
//                        Text("Back")
//                    }
//                })
//                Spacer()
//            }
            HStack{
                Button(action: {
                    let calendar = Calendar.current
                    self.selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
                }, label: {
                    Image(systemName: "chevron.left.square.fill")
                        .font(.title)
                })
                .fullScreenCover(isPresented: $showMilage, content: {
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
                })
                Spacer()
                
                DatePicker(selection: $selectedDate, displayedComponents: .date) {
                    Text("\(weekDay(date: selectedDate))")
                        .foregroundColor(Color.basicFontText)
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
                        .font(.title)
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
            Spacer()
            VStack{
                HStack{
                    Text("Start Milage: ")
                    if VM.activeRoute?.startMilage == nil {
                        TextField(text: $startMilage, prompt: Text("Milage"), label: {
                            Text("Milage: ")
                        })
                        .keyboardType(.decimalPad)
                    } else {
                        Text("\(startMilage)")
                    }
                    Spacer()
                }
                HStack{
                    Text("End Milage: ")
                    if VM.activeRoute?.endMilage == nil || VM.activeRoute?.endMilage == 0 {
                        TextField(text: $endMilage, prompt: Text("Milage"), label: {
                            Text("Milage: ")
                        })
                        .keyboardType(.decimalPad)
                    } else {
                        Text("\(endMilage)")
                    }
                    Spacer()
                }
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
                    .background(Color.accentColor)
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
                    .background(Color.accentColor.opacity(0.5))
                }
                .cornerRadius(5)
                .padding(5)
                .foregroundColor(Color.basicFontText)
            }
            Spacer()
        }
        .padding(20)
    }
    var routeInfo: some View {
        VStack{
            VStack{
                ProgressView("\(String(VM.finishedStops ?? 0)) / \(String(VM.totalStops ?? 0))", value: Double(VM.finishedStops ?? 1), total: Double(VM.totalStops ?? 1))
                    .foregroundColor(Color.black)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            HStack{
                Text("Time: \(time(date:startTime))")
                    .foregroundColor(Color.reverseFontText)
//                Text("Start: \(ThePoolApp.time(date: activeRouteVM.activeRoute?.startTime))")
                Spacer()
                if let ending = VM.activeRoute?.endTime {
                    Text("End: \(ThePoolApp.time(date:ending))")
                        .foregroundColor(Color.reverseFontText)
                } else {
                    Text("Duration: \(displayNumberAsMinAndHourAndSecond(seconds:duration))")
                        .foregroundColor(Color.reverseFontText)
                }
            }
            if let milage = VM.activeRoute?.startMilage {
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
            HStack{
                Text("Status: ")
                    .foregroundColor(Color.reverseFontText)
                if VM.activeRoute?.status == .didNotStart {
                    Button(action: {
                        showMilage.toggle()
                    }, label: {
                        Text("Start !")
                            .padding(5)
                            .background(getColor(status: VM.activeRoute?.status.rawValue ?? ""))
                            .cornerRadius(5)
                            .foregroundColor(Color.reverseFontText)
                    })
                    .background(Color.white // any non-transparent background
                        .cornerRadius(5)
                      .shadow(color: Color.black, radius: 2, x: 2, y: 2)
                    )
                } else {
                    Text("\(VM.activeRoute?.status.rawValue ?? "Loading")")
                        .padding(5)
                        .background(getColor(status: VM.activeRoute?.status.rawValue ?? ""))
                        .cornerRadius(5)
                        .foregroundColor(Color.reverseFontText)
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
                    .fullScreenCover(isPresented: $confirmMove,
                           onDismiss: {
                        enableMove = false
                        selectedStopList = []
                    },
                           content: {
                        VStack{
                            HStack{
                                Spacer()
                                Button(action: {
                                    confirmMove = false
                                }, label: {
                                    Image(systemName:"xmark")
                                })
                            }
                            MoveServiceStopsConfirmation(
                                dataService:dataService,
                                selectedServiceStopList: selectedStopList
                            )
                        }
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
            //            HStack{
            //                Spacer()
            //                WeatherSnapShotView(weather: waeatherVM.currentWeather ?? Weather(temperature: 72, weatherCode: .clear))
            //            }
        }
        .padding(10)
        .background(Color.gray)
        .cornerRadius(10)
        .background(Color.white // any non-transparent background
            .cornerRadius(10)
          .shadow(color: Color.black, radius: 5, x: 5, y: 5)
        )
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
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
            VStack{
                HStack{
                    ZStack{
                         Image(systemName: "circle.fill")
                             .foregroundColor(Color.white)
                             .font(.footnote)
                        Image(systemName: "\(String(listOfShoppingListItems)).circle.fill")
                            .foregroundColor(Color.red)
                            .font(.footnote)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
    var listOfStops: some View {
        ScrollView{
            VStack(spacing: 0){
                ForEach(VM.serviceStopList){ stop in
                    HStack{
                        if enableMove{
                            Button(action: {
                                if selectedStopList.contains(stop) {
                                    selectedStopList.removeAll(where: {$0.id == stop.id})
                                } else {
                                    selectedStopList.append(stop)
                                }
                            }, label: {
                                if selectedStopList.contains(stop) {
                                    Image(systemName: "checkmark.square")
                          
                                } else {
                                    Image(systemName: "square")
                                }
                                RouteStopLabel(stop: stop, index: VM.serviceStopList.firstIndex(of: stop) ?? 0,selected:selectedStopList.contains(stop))
                            })
                            .foregroundColor(Color.basicFontText)
                        } else if enableReorder {
                            Button(action: {
                                
                            }, label: {
                                Image(systemName: "line.3.horizontal")
                            })
                            RouteStopLabel(stop: stop, index: VM.serviceStopList.firstIndex(of: stop) ?? 0,selected:selectedStopList.contains(stop))
                        } else {
                            RouteStopCardView(dataService: dataService, stop: stop, index: VM.serviceStopList.firstIndex(of: stop) ?? 0)
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
            .fullScreenCover(isPresented: $showNewServiceStop,
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
struct MyDropDelegate : DropDelegate {

    let item : ServiceStop
    @Binding var items : [ServiceStop]
    @Binding var draggedItem : ServiceStop?

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else {
            return
        }

        if draggedItem != item {
            let from = items.firstIndex(of: draggedItem)!
            let to = items.firstIndex(of: item)!
            withAnimation(.default) {
                self.items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}
