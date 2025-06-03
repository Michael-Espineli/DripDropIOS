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
    
    @State var idItem:IdInfo? = nil

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0){
                toolBarView
                dateSelectionView
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
        .navigationBarBackButtonHidden(true)

        .onReceive(timer) { time in
            if var duration1 = VM.duration{
                if duration1 > -1 {
                    duration1 += 1
                    duration = duration1
                }
            }
        }
        .task{
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
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
                if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
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
    var toolBarView: some View {
        HStack{
            if UIDevice.isIPhone {
                Button(action: {
                    masterDataManager.selectedCategory = .dashBoard
                    navigationManager.routes.removeLast()
                }, label: {
                    HStack{
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                })
            }
            Spacer()
            Button(action:{
                showRepairSheet.toggle()
            }, label: {
                Image(systemName: "wrench.adjustable.fill")
                    .font(.title)
                    .foregroundColor(Color.poolBlue)
            })
            NavigationLink(value: Route.shoppingList(dataService: dataService), label: {
                shoppingListIcon
            })
            NavigationLink(value: Route.createNewJob(dataService: dataService), label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.poolBlue)
                
            })
        }
        .padding(EdgeInsets(top: 4, leading: 10, bottom: 0, trailing: 10))
        .padding(.horizontal,8)
    }
    var shoppingListIcon: some View {
        ZStack{
            Image(systemName: "list.clipboard.fill")
                .font(.title)
                .foregroundColor(Color.poolBlue)
            
            .overlay(
                VStack{
                    HStack{
                        ZStack{
                             Image(systemName: "circle.fill")
                                 .foregroundColor(Color.white)
                            Image(systemName: "\(String(listOfShoppingListItems)).circle.fill")
                                .foregroundColor(Color.red)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            )
        }
    }

    var dateSelectionView: some View {
        VStack{
            HStack{
                Button(action: {
                    let calendar = Calendar.current
                    self.selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
                }, label: {
                    Image(systemName: "chevron.left")
                        .modifier(BlueButtonModifier())
                })
//                Text("E")
                Text("\(weekDay(date: selectedDate))")
                    .foregroundColor(Color.basicFontText)
                    .padding(.leading,8)

                Spacer()
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                
                Spacer()
//                DatePicker(selection: $selectedDate, displayedComponents: .date) {
//                    Text("\(weekDay(date: selectedDate))")
//                        .foregroundColor(Color.basicFontText)
//                }
                Button(action: {
                    selectedDate = Date()
                }, label: {
                    Text("Today")
                        .modifier(BlueButtonModifier())
                })
                .padding(.trailing,8)
                Button(action: {
                    let calendar = Calendar.current
                    self.selectedDate = calendar.date(byAdding: .day, value: +1, to: selectedDate)!
                }, label: {
                    Image(systemName: "chevron.right")
                        .modifier(BlueButtonModifier())
                })
                .padding(.horizontal,8)
              
            }
        }
        .padding(EdgeInsets(top: 4, leading: 10, bottom: 0, trailing: 10))
        .padding(.horizontal,8)
    }
    var notRouteForToday: some View {
        VStack{
            Text("Unable to Update Route Today")
        }
    }
    var routeInfo: some View {
        VStack{
            VStack{
                
                ProgressView("\(String(VM.finishedStops ?? 0)) / \(String(VM.totalStops ?? 0))", value: Double(VM.finishedStops ?? 1), total: Double(VM.totalStops ?? 1))
                    .foregroundColor(Color.black)
                    .padding(.horizontal,8)
            }
            HStack{
                Text("Time")
                    .foregroundColor(Color.reverseFontText)
                Spacer()
                if let ending = VM.activeRoute?.endTime {
                    Text("Time")
                        .foregroundColor(Color.reverseFontText)
                } else {
                    Text("Duration: \(displayNumberAsMinAndHourAndSecond(seconds:duration))")
                        .foregroundColor(Color.reverseFontText)
                }
            }
            if let milage = VM.activeRoute?.startMilage {
                HStack{
                    Text("Milage:")
                        .bold()
                    Text(Measurement(value: Double(milage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))
                        .foregroundColor(Color.reverseFontText)
                    Spacer()
                    if let ending = VM.activeRoute?.endMilage {
                        Text("End: ")
                            .bold()
                        Text(Measurement(value: Double(ending), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))
                            .foregroundColor(Color.reverseFontText)

                        Button(action: {
                            showMilage.toggle()
                        }, label: {
                            Image(systemName: "square.and.pencil")
                                .modifier(BlueButtonModifier())
                        })
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
                    .bold()
                Button(action: {
                    showMilage.toggle()
//                    idItem = IdInfo(id: "Hello", internalId: "")
                }, label: {
                    if VM.activeRoute?.status == .didNotStart {
                        Text("Start !")
                            .modifier(ListButtonModifier())
                            .modifier(OutLineButtonModifier())
                    } else {
                        Text("\(VM.activeRoute?.status.rawValue ?? "Loading")")
                            .modifier(YellowButtonModifier())
                    }
                })                    
                .sheet(isPresented: $showMilage, onDismiss: {
                    
                }, content: {
                    startMilageView
                        .presentationDetents([.fraction(0.5),.fraction(0.6)])
                })

                
                Spacer()
                //Map
                if let activeRoute = masterDataManager.selectedActiveRoute {
                        NavigationLink(value: Route.routeOverview(route: activeRoute,dataService: dataService), label: {
                        Image(systemName: "map")
                                .modifier(BlueButtonModifier())
                    })
                } else {
                    NavigationLink(destination: {
                        ContentView()
                    }, label: {
                            Image(systemName: "map")
                            .modifier(BlueButtonModifier())
                    })
                }
            }
            //Reorder and Move
            HStack{
                if !enableMove && !enableReorder {
                    Button(action: {
                        enableReorder.toggle()
                    }, label: {
                        Text("Reorder")
                            .modifier(BlueButtonModifier())
                    })
                    Spacer()

                }
                if enableReorder {
                    Button(action: {
                        enableReorder = false
                    }, label: {
                        Text("Cancel")
                            .modifier(DismissButtonModifier())
                    })
                    Spacer()
                    Button(action: {
                        print("Save Re Order")
                    }, label: {
                        Text("Save")
                            .modifier(SubmitButtonModifier())
                    })
                }
                if enableMove {
                    Button(action: {
                        enableMove = false
                        selectedStopList = []
                    }, label: {
                        Text("Cancel")
                            .modifier(DismissButtonModifier())
                    })
                    Spacer()
                    Button(action: {
                        if selectedStopList.count > 0 {
                            confirmMove.toggle()
                        } else {
                            print("Selected Stop List Is Empty")
                        }
                    }, label: {
                        Text("Confirm")
                            .modifier(SubmitButtonModifier())
                    })
                    .disabled(selectedStopList.isEmpty)
                    .sheet(isPresented: $confirmMove,
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
                            .modifier(BlueButtonModifier())

                    })
               
                }
            }
            //            HStack{
            //                Spacer()
            //                WeatherSnapShotView(weather: waeatherVM.currentWeather ?? Weather(temperature: 72, weatherCode: .clear))
            //            }
        }
        .padding(8)
        .background(Color.gray)
        .cornerRadius(8)
        .background(Color.white // any non-transparent background
            .cornerRadius(8)
          .shadow(color: Color.black, radius: 5, x: 5, y: 5)
        )
        .padding(EdgeInsets(top: 4, leading: 10, bottom: 0, trailing: 10))
        .padding(.horizontal,8)
    }
    var startMilageView: some View {
        VStack{
            Spacer()
            VStack{
                Button(action: {
                    VM.showVehicalPicker.toggle()
                }, label: {
                    if VM.selectedVehical.id == "" {
                        Text("Pick Vehical")
                            .modifier(BlueButtonModifier())
                    } else {
                        Text("\(VM.selectedVehical.nickName) \(VM.selectedVehical.plate) \(VM.selectedVehical.make) \(VM.selectedVehical.model)")
                            .modifier(BlueButtonModifier())
                    }
                })
                .sheet(isPresented: $VM.showVehicalPicker, onDismiss: {
                    
                }, content: {
                    VehicalPickerView(dataService: dataService, vehical: $VM.selectedVehical)
                })
                
                if VM.selectedVehical.id != "" {
                    Rectangle()
                        .frame(height: 1)
                    HStack{
                        Text("Recent Milage:")
                        Spacer()
                        Text(Measurement(value: VM.selectedVehical.miles, unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))
                    }
                    
                    Divider()
                    HStack{
                        Text("Start Milage: ")
                            .bold()
                        if VM.activeRoute?.startMilage == nil {
                            TextField(text: $startMilage, prompt: Text("Milage"), label: {
                                Text("Milage: ")
                            })
                            .keyboardType(.decimalPad)
                            .foregroundColor(Color.poolBlack)
                            .modifier(TextFieldModifier())
                            Button(action: {
                                startMilage = String(VM.selectedVehical.miles)
                            }, label: {
                                Text("Use Milage")
                                    .modifier(AddButtonModifier())
                            })
                        } else {
                            Text("\(startMilage)")
                        }
                        Spacer()
                    }
                    HStack{
                        Text("End Milage: ")
                            .bold()
                        if VM.activeRoute?.endMilage == nil || VM.activeRoute?.endMilage == 0 {
                            TextField(text: $endMilage, prompt: Text("Milage"), label: {
                                Text("Milage: ")
                            })
                            .keyboardType(.decimalPad)
                            .foregroundColor(Color.poolBlack)
                            .modifier(TextFieldModifier())
                        } else {
                            Text("\(endMilage)")
                        }
                        Spacer()
                    }
                    HStack{
                        Button(action: {
                            Task{
                                if startMilage != "0" {
                                    
                                    if let company = masterDataManager.currentCompany,
                                       let activeRoute = VM.activeRoute,
                                       let miles = Double(startMilage) {
                                        if VM.selectedVehical.id != ""{
                                            if miles >= VM.selectedVehical.miles {
                                                startTime = Date()
                                                VM.updateActiveRoute(
                                                    companyId: company.id,
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
                                                    durationSeconds: activeRoute.durationMin,
                                                    distanceMiles: activeRoute.distanceMiles,
                                                    status: .inProgress,
                                                    vehical: VM.selectedVehical
                                                )
                                                try await VM.updateVehicalMilage(companyId: company.id, vehicalId: VM.selectedVehical.id, miles: miles)
                                                showMilage = false
                                            } else {
                                                print("miles can not Be lower than Previous Miles")
                                            }
                                        } else {
                                            print("No Selected Vehicals")
                                        }
                                    } else {
                                        print("Error in Updating Route")
                                    }
                                } else {
                                    print("Milage is 0")
                                }
                            }
                        },
                               label: {
                            Text("Start Route")
                        })
                        .modifier(BlueButtonModifier())
                        
                        Spacer()
                        Button(action: {
                            Task{
                                if endMilage != "0" {
                                    if let company = masterDataManager.currentCompany,
                                       let activeRoute = VM.activeRoute,
                                       let miles = Double(endMilage)  {
                                        if VM.selectedVehical.id != ""{
                                            if miles >= VM.selectedVehical.miles {
                                                VM.updateActiveRoute(
                                                    companyId: company.id,
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
                                                    durationSeconds: activeRoute.durationMin,
                                                    distanceMiles: activeRoute.distanceMiles,
                                                    status: .inProgress,
                                                    vehical: VM.selectedVehical
                                                )
                                                
                                                try await VM.updateVehicalMilage(companyId: company.id, vehicalId: VM.selectedVehical.id, miles: miles)
                                                showMilage = false
                                                print("Succesffully got end Milage")
                                            } else {
                                                print("miles can not Be lower than Previous Miles")
                                            }
                                        } else {
                                            print("No Selected Vehicals")
                                        }
                                    } else {
                                        print("Error in Updating Route")
                                    }
                                } else {
                                    print("Milage is 0")
                                }
                            }
                        },
                               label: {
                            Text("End Route")
                        })
                        .modifier(DismissButtonModifier())
                    }
                }
            }
            Spacer()
        }
        .padding(8)
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
    
}
