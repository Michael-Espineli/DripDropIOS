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

    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var VM: MobileDailyRouteDisplayViewModel

//    @StateObject var VM: MobileDailyRouteDisplayViewModel
//    init(dataService: any ProductionDataServiceProtocol) {
//        _VM = StateObject(wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService))
//    }

    @State var showRepairSheet: Bool = false
    @State var showNewServiceStop: Bool = false
    @State var showMilage: Bool = false

    @State var enableReorder: Bool = false
    @State var confirmMove: Bool = false
    @State var recievdJobId: String? = nil
    @State var isLoading: Bool = false

    @State var startMilage: String = "0"
    @State var endMilage: String = "0"

    @State var startTime: Date = Date()
    @State var stopList: [ServiceStop] = []



    
    @State var duration: Int = 0
    @State var listOfShoppingListItems: Int = 3

    @State var idItem: IdInfo? = nil

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 16) {
                toolBarView
                ScrollView {
                    dateSelectionView
                    if VM.serviceStopList.isEmpty {
                        Text("No Route")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        routeInfo
                        if VM.ArOrderIsDifferentThanRrORder {
                            HStack{
                                Button(action: {
                                    VM.resetOrderToMatchRecurringRoute(companyId: masterDataManager.currentCompany?.id)
                                }, label: {
                                    Text("Reset Order")
                                        .modifier(OrangeButtonModifier())
                                })
                                Spacer()
                                Button(action: {
                                    VM.reorderServiceStopsPermanently(companyId: masterDataManager.currentCompany?.id)
                                }, label: {
                                    Text("Update Default")
                                        .modifier(SubmitButtonModifier())
                                })
                            }
                        }
                        if enableReorder {
                            reOrderListOfStops
                        } else {
                            listOfStops
                        }
                    }
                }
            }
            .padding(.bottom, 24)
            if isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            if var duration1 = VM.duration, duration1 > -1 {
                duration1 += 1
                duration = duration1
            }
        }
//        .onAppear(perform: {
//            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
//                print("[WorkPreviewBasedOnCompany][onAppear] Calling start")
//                VM.start(companyId: company.id, user: user, date: Date())
//             }
//        })
        .onChange(of: VM.selectedDate) { date in
            Task {
                if let company = masterDataManager.currentCompany,
                   let user = masterDataManager.user {
                    //Updated Version with listeners
                    VM.start(companyId: company.id, user: user, date: VM.selectedDate)
                }
            }
        }
        .onDisappear(perform: {
            if let company = masterDataManager.currentCompany,
               let user = masterDataManager.user {
                VM.selectedDate = Date()
//                VM.start(companyId: company.id,  user: user, date: VM.selectedDate)
            }
        })

        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
        
    // MARK: - Helpers
    func getColor(status: String) -> Color {
        switch status {
        case "In Progress": return .orange
        case "Did Not Start": return .black.opacity(0.5)
        case "Traveling": return .poolBlue
        case "Break": return .purple
        case "Finished": return .poolGreen
        default: return .gray
        }
    }
}

// MARK: - Toolbar
extension EmployeeDailyDashboard {
    var toolBarView: some View {
        HStack(spacing: 12) {

            if UIDevice.isIPhone {
                Button {
                    masterDataManager.selectedCategory = .dashBoard
                    navigationManager.routes.removeLast()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        
                    Text("Back")
                        .font(.headline)
                }
            }
            Spacer()
            NavigationLink(value: Route.createRepairRequest(dataService: dataService)) {
                Image(systemName: "wrench.adjustable.fill")
            }
            /*
             //Update 2.1
            NavigationLink(value: Route.shoppingList(dataService: dataService)) {
                shoppingListIcon
            }
*/
            NavigationLink(value: Route.createNewJob(dataService: dataService)) {
                Image(systemName: "plus")
            }
        }
        .foregroundColor(.poolBlue)
        .padding()
        .background(.ultraThinMaterial)
    }

    var shoppingListIcon: some View {
        ZStack {
            Image(systemName: "list.clipboard.fill")

            if listOfShoppingListItems > 0 {
                Text("\(listOfShoppingListItems)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 10, y: -10)
            }
        }
    }
}

// MARK: - Date Selector
extension EmployeeDailyDashboard {
    var dateSelectionView: some View {
        HStack(spacing: 0) {
            Button {
                VM.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: VM.selectedDate)!
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(weekDay(date: VM.selectedDate))
                .font(.headline)
            DatePicker("", selection: $VM.selectedDate, displayedComponents: .date)
                .labelsHidden()
            Spacer()
            Button("Today") {
                VM.selectedDate = Date()
            }
            Spacer()
            Button {
                VM.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: VM.selectedDate)!
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.vertical,4)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Route Info
extension EmployeeDailyDashboard {
    var routeInfo: some View {
        VStack(spacing: 12) {
            if let activeRoute = VM.activeRoute {
                
                
                ProgressView(
                    "\(activeRoute.finishedStops) / \(activeRoute.totalStops)",
                    value: Double(activeRoute.finishedStops),
                    total: Double(activeRoute.totalStops)
                )
                
                HStack {
                    Text("Duration")
                    Spacer()
                    if let startTime = activeRoute.startTime {
                        DurationTimerView(start: startTime,end:activeRoute.endTime)
                    }
                }
                
                if let milage = activeRoute.startMilage {
                    HStack {
                        Text("Mileage")
                        Spacer()
                        Text(
                            Measurement(value: Double(milage), unit: UnitLength.miles)
                                .formatted(.measurement(width: .abbreviated))
                        )
                    }
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Button {
                        showMilage.toggle()
                    } label: {
                        Text(activeRoute.status.rawValue ?? "Loading")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(getColor(status: activeRoute.status.rawValue ?? ""))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                
                routeActionButtons
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private var routeActionButtons: some View {
        HStack {

            if !VM.enableMove && !enableReorder {
                
                Button("Reorder") { enableReorder = true }
                Spacer()
                Button("Move") { VM.enableMove = true }
            }

            if enableReorder {
                Button(action: { enableReorder = false}, label: {
                    Text("Cancel")
                        .modifier(DeleteButtonModifier())
                    
                })
                Spacer()
                
                Button(action: {
                    VM.reorderServiceStops(companyId: masterDataManager.currentCompany?.id)
                    enableReorder = false
                }, label: {
                    Text("Save")
                        .modifier(SubmitButtonModifier())
                    
                })
            }

            if VM.enableMove {
                
                Button(action: {
                    VM.cancelMove()
                    VM.enableMove = false
                }, label: {
                    Text("Cancel")
                        .modifier(DeleteButtonModifier())
                    
                })
                Spacer()
                    
                Button(action: {
                    confirmMove.toggle()
                }, label: {
                    Text("Confirm")
                        .modifier(SubmitButtonModifier())
                })
                .disabled(VM.selectedServiceStops.isEmpty)
                .sheet(isPresented: $confirmMove, onDismiss: {
                    
                }, content: {
                    VStack{
                        
                        Picker("Employee", selection: $VM.moveType) {
                            Text("One Time").tag("One Time")
                            Text("Permanent").tag("Permanent")
                        }
                        .pickerStyle(.segmented)
                        if VM.moveType == "One Time" {
                            HStack{
                                Spacer()
                                Button(action: {
                                    VM.moveServiceStops(companyId: masterDataManager.currentCompany?.id)
                                    print("Confirm submit Logic")
                                    
                                }, label: {
                                    Text("Submit")
                                        .modifier(SubmitButtonModifier())
                                })
                            }
                            DatePicker("Date Selected", selection: $VM.moveDate, in: Date()...,displayedComponents: .date)
                        } else {
                            HStack{
                                Spacer()
                                Button(action: {
                                    VM.moveServiceStopsPermanently(companyId: masterDataManager.currentCompany?.id)
                                    print("Confirm submit Logic")
                                    
                                }, label: {
                                    Text("Submit")
                                        .modifier(SubmitButtonModifier())
                                })
                            }
                            HStack {
                                Text("Day Of Week").bold(true)
                                Picker("Day Of Week", selection: $VM.newDay) {
                                    ForEach(DaysOfWeek.allCases) { day in
                                        Text(day.rawValue).tag(day)
                                        
                                    }
                                }
                            }
                            Text("If Day has already passed this week. Changes will apply next week")
                                .font(.footnote)
                        }
                            HStack {
                                Text("Employee").bold(true)
                                Picker("Employee", selection: $VM.selectedTech) {
                                    Text("Select User").tag(CompanyUser(
                                        id: "",
                                        userId: "",
                                        userName: "",
                                        roleId: "",
                                        roleName: "",
                                        dateCreated: Date(),
                                        status: .active,
                                        workerType: .notAssigned
                                    ))
                                    ForEach(VM.companyUsers) { user in
                                        Text(user.userName).tag(user)
                                    }
                                }
                            }
                            Text("Stops")
                            Divider()
                            ForEach(VM.selectedServiceStops){ stop in
                                Text("\(VM.serviceStopList.firstIndex(of: stop) ?? 0)) \(stop.customerName)")
                            }
                    }
                    .padding()
                    .presentationDetents([.medium,.large])
                })
            }
        }
    }
}

// MARK: - Stops List
extension EmployeeDailyDashboard {
    var listOfStops: some View {
        LazyVStack(spacing: 8) {
            ForEach(VM.serviceStopList) { stop in
                Group {
                    if VM.enableMove {
                            // For moving stops
                        Button(action: {
                            if VM.selectedServiceStops.contains(stop) {
                                VM.selectedServiceStops.remove(stop)
                            } else {
                                VM.selectedServiceStops.append(stop)
                            }
                        }, label: {
                            ZStack{
                                Rectangle()
                                    .padding(.horizontal,6)
                                    .padding(.vertical,4)
                                    .background(VM.selectedServiceStops.contains(stop) ? Color.poolBlue : Color.poolGray)
                                    .cornerRadius(16)
                                    .foregroundColor(Color.clear)
                                    .fontDesign(.monospaced)
                                    .opacity(0.5)
                                RouteStopCardView(
                                    dataService: dataService,
                                    stop: stop,
                                    index: VM.serviceStopList.firstIndex(of: stop) ?? 0
                                )
                                .disabled(true)
                            }
                            .opacity(VM.selectedServiceStops.contains(stop) ? 0.7 : 1)
                        })
                    } else {
                            //Default View
                        ZStack{
                            switch stop.operationStatus {
                            case .finished:
                                Rectangle()
                                    .padding(.horizontal,6)
                                    .padding(.vertical,4)
                                    .background(Color.poolGreen)
                                    .cornerRadius(16)
                                    .foregroundColor(Color.clear)
                                    .fontDesign(.monospaced)
                                    .opacity(0.5)
                                    .onTapGesture {
                                        navigationManager.push(to: Route.dailyDisplayStop(
                                            dataService: dataService,
                                            serviceStop: stop
                                        ))
                                    }
                            case .notFinished:
                                Rectangle()
                                    .padding(.horizontal,6)
                                    .padding(.vertical,4)
                                    .background(Color.poolGray)
                                    .cornerRadius(16)
                                    .foregroundColor(Color.clear)
                                    .fontDesign(.monospaced)
                                    .opacity(0.5)
                                    .onTapGesture {
                                        navigationManager.push(to: Route.dailyDisplayStop(
                                            dataService: dataService,
                                            serviceStop: stop
                                        ))
                                    }
                            case .skipped:
                                Rectangle()
                                    .padding(.horizontal,6)
                                    .padding(.vertical,4)
                                    .background(Color.realYellow)
                                    .cornerRadius(16)
                                    .foregroundColor(Color.clear)
                                    .fontDesign(.monospaced)
                                    .opacity(0.5)
                                    .onTapGesture {
                                        navigationManager.push(to: Route.dailyDisplayStop(
                                            dataService: dataService,
                                            serviceStop: stop
                                        ))
                                    }
                            }
                            
                            RouteStopCardView(
                                dataService: dataService,
                                stop: stop,
                                index: VM.serviceStopList.firstIndex(of: stop) ?? 0
                            )
                        }
                    }
                }
                .padding(8)
            }
        }
        .padding(.horizontal)
    }
    var reOrderListOfStops: some View {
        
        LazyVStack(spacing: 8) {
            ForEach(VM.serviceStopList) { stop in
                    //For Re ordering stops
                Group{
                    ZStack{
                        Rectangle()
                            .padding(.horizontal,6)
                            .padding(.vertical,4)
                            .background(VM.selectedServiceStops.contains(stop) ? Color.poolBlue : Color.poolGray)
                            .cornerRadius(16)
                            .foregroundColor(Color.clear)
                            .fontDesign(.monospaced)
                            .opacity(0.5)
                        RouteStopCardView(
                            dataService: dataService,
                            stop: stop,
                            index: VM.serviceStopList.firstIndex(of: stop) ?? 0
                        )
                        .disabled(true)
                    }
                    .onDrag({
                        VM.draggedStop = stop
                        return NSItemProvider(item: nil, typeIdentifier: stop.id)
                    })
                    .onDrop(of: [UTType.text], delegate: MyDropDelegate(targetStop: stop, stopList: $VM.serviceStopList, draggedStop: $VM.draggedStop))
                }
                .padding(8)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Mileage Sheet
extension EmployeeDailyDashboard {
    var startMilageView: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Button {
                    VM.showVehicalPicker.toggle()
                } label: {
                    Text(
                        VM.selectedVehical.id.isEmpty
                        ? "Pick Vehicle"
                        : "\(VM.selectedVehical.nickName) \(VM.selectedVehical.plate)"
                    )
                }
                .sheet(isPresented: $VM.showVehicalPicker) {
                    VehicalPickerView(
                        dataService: dataService,
                        vehical: $VM.selectedVehical
                    )
                }

                if !VM.selectedVehical.id.isEmpty {
                    Divider()

                    HStack {
                        Text("Recent Mileage")
                        Spacer()
                        Text(
                            Measurement(value: VM.selectedVehical.miles, unit: UnitLength.miles)
                                .formatted(.measurement(width: .abbreviated))
                        )
                    }
                    Divider()
                    TextField("Start Mileage", text: $startMilage)
                        .keyboardType(.decimalPad)
                        .modifier(TextFieldModifier())
                    TextField("End Mileage", text: $endMilage)
                        .keyboardType(.decimalPad)
                        .modifier(TextFieldModifier())
                }
            }
            .padding()
            Spacer()
        }
    }
}
struct MyDropDelegate : DropDelegate {

    let targetStop: ServiceStop
    @Binding var stopList: [ServiceStop]
    @Binding var draggedStop: ServiceStop?

    func dropEntered(info: DropInfo) {
        guard
            let dragged = draggedStop,
            dragged != targetStop,
            let fromIndex = stopList.firstIndex(of: dragged),
            let toIndex = stopList.firstIndex(of: targetStop)
        else { return }

        withAnimation {
            stopList.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedStop = nil
        return true
    }
}
