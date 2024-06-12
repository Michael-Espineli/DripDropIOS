//
//  ServiceStopInfoView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//



import SwiftUI

struct ServiceStopUtilityView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    let serviceStop: ServiceStop
    @Binding var stopData : StopData

//    init(dataService: any ProductionDataServiceProtocol,stopData:Binding<StopData?>) {
//        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
//        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
//        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
//        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
//        self.stopData = stopData
//    }
//    @StateObject var stopDataVM : StopDataViewModel
//    @StateObject var serviceStopVM : ServiceStopsViewModel
//    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
//    @StateObject var customerVM : CustomerViewModel
//    
//    @StateObject var weatherVM = WeatherViewModel()
//    @StateObject var settingsVM = SettingsViewModel()

    @State var finished:Bool = false
    @State var skipped:Bool = false
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var invoiced:Bool = false
//    @State var stopData:StopData = StopData(id: UUID().uuidString,
//                                            date: Date(),
//                                            serviceStopId: "",
//                                            readings: [],
//                                            dosages: [],
//                                            bodyOfWaterId: "",
//                                            customerId: "",
//                                            serviceLocationId: "",
//                                            userId: "")
    @State var stopDataList:[StopData] = []
    @State var initialLoadFinished:Bool = false
    @State var previousStopDataView:String = "Table"
    @State var previousStopDataViewoptions:[String] = ["Table","Chart"]
    @State var selectedObservations:[String] = []
    @State var selectedTask:[String] = []
    
    @State var selectedInputId:String = ""
    @State var selectedInputIdList:[String] = []

    @State var showObservations:Bool = true
    @State var showTasks:Bool = true
    
    @State var showReadings:Bool = true
    @State var showDosages:Bool = true
    
    @State var bodyOfWater:BodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "")
    var body: some View {
        ZStack{
            VStack(spacing:0){
                //DEVELOPER BUILD IN EXPANDING AND CONTRACTING SECTIONS THAT AUTO CLOSE WHEN YOU FINISH THE AREA.
                        //info
                        bodyOfWaterPicker
                        ZStack{
                            
                            ScrollView{
                                if let bodyOfWater = VM.selectedBOW {
                                    if bodyOfWater.id ==  "" {
                                        Text("No Body Of Water")
                                    } else {
                                        //Replace with the version of stopData in the customer service history Page
                                        previousStopData

                                        observations
                                        tasks
                                        
                                        if serviceStop.includeReadings {
                                            readingInput
                                        }
                                        if serviceStop.includeDosages {
                                            dosageInput
                                        }
                                    }
                                }
                            }
                        }
            }
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 5))
            //            .background(Color.gray.opacity(0.5))
        }
        .onChange(of: VM.selectedBOW, perform: { BOW in
            Task{
                if let bodyOfWater = BOW, let user = masterDataManager.user {
                    print("Body Of Water Change \(bodyOfWater.id)")
                    await VM.onChangeOfBodyOfWater(bodyOfWater: bodyOfWater)
                    stopData = VM.stopData ?? StopData(
                        id: UUID().uuidString,
                        date: serviceStop.serviceDate ?? Date(),
                        serviceStopId: serviceStop.id,
                        readings: [],
                        dosages: [],
                        bodyOfWaterId: bodyOfWater.id,
                        customerId: serviceStop.customerId,
                        serviceLocationId: serviceStop.serviceLocationId,
                        userId: user.id
                    )
                }
            }
        })

    }

}

extension ServiceStopUtilityView {
    var sideBar:some View {
        ZStack{
            HStack{
                if skipped {
                    ZStack{
                        Rectangle()
                            .fill(Color.realYellow)
                            .frame(width: 5,height: 25)
                        
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                } else {
                    ZStack{
                        Rectangle()
                            .fill(finished ? Color.poolGreen : Color.gray)
                            .frame(width: 5,height: 25)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
            
            if skipped {
                ZStack{
                    Rectangle()
                        .fill(Color.realYellow)
                        .frame(width: 5,height: 25)
                    
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            } else {
                ZStack{
                    Rectangle()
                        .fill(finished ? Color.poolGreen : Color.gray)
                        .frame(height: 5)
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
        }
    }
    var bodyOfWaterPicker: some View {
        ZStack{
            //            sideBar
            HStack(spacing: 0){
                icon
                ScrollView(.horizontal,showsIndicators: false){
                    HStack{
                        if VM.bodiesOfWater.isEmpty {
                            Text("no bodies of water")
                        } else {
                            ForEach(VM.bodiesOfWater) { BOW in
                                Button(action: {
                                    VM.selectedBOW = BOW
                                }, label: {
                                    if VM.selectedBOW == BOW {
                                        Text("\(BOW.name)")
                                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                                            .background(Color.blue)
                                            .foregroundColor(Color.white)
                                            .cornerRadius(5)
                                    } else {
                                        Text("\(BOW.name)")
                                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                                            .background(Color.gray.opacity(0.5))
                                            .foregroundColor(Color.blue)
                                            .cornerRadius(5)
                                    }
                                })
                                .padding(10)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                }
            }
        }
    }
    var info: some View {
        ZStack{
            //            sideBar
            HStack{
                icon
                //
                
                //                WeatherSnapShotView(weather: weatherVM.currentWeather ?? Weather(temperature: Int(72), weatherCode: .icePellets))
                Spacer()
                homeNav
                Spacer()
                
            }
        }
    }
    var previousStopData: some View {
        ZStack{
            //            sideBar
            VStack(spacing:0){
                if !VM.currentHistory.isEmpty {
                                    ScrollView(.horizontal,showsIndicators: false){
                    
                    StopDataTableView(stopData: VM.currentHistory, readingTemplates: VM.readingTemplates, dosageTemplates: VM.dosageTemplates)
                }
                } else {
                    Text("No Data Yet")
                }
//                Picker("", selection: $previousStopDataView) {
//                    ForEach(previousStopDataViewoptions,id:\.self) {
//                        Text($0).tag($0)
//                    }
//                }
//                .pickerStyle(.segmented)
//                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
//                ScrollView(.horizontal,showsIndicators: false){
//                    VStack(spacing:0){
//                        switch previousStopDataView {
//                        case "Table":
//                            if !VM.currentHistory.isEmpty {
//                                
//                                StopDataTableView(stopData: VM.currentHistory, readingTemplates: VM.readingTemplates, dosageTemplates: VM.dosageTemplates)
//                            } else {
//                                Text("No Data Yet")
//                            }
//                        case "Chart":
//                            table
////                            chart
//                        default:
//                            table
//                        }
//                    }
//                }
            }
            .padding(.horizontal,8)
            
        }
        
    }
    var table: some View {
        VStack(spacing:0){
            if VM.currentHistory.isEmpty {
                ZStack{
                    Text("No Data Yet")
                }
            } else {
                
                StopDataRowTitle(readingTemplates: VM.readingTemplates, dosageTemplates: VM.dosageTemplates)
                ForEach(VM.currentHistory) { data in
                    Divider()
                    StopDataRow(dataService:dataService,stopData: data, readingTemplates: VM.readingTemplates, dosageTemplate: VM.dosageTemplates)
                }
            }
        }
    }
    var chart: some View {
        VStack{
            TabView{
                ForEach(VM.readingTemplates) { templates in
                    StopDataReadingChartView(stopData: VM.currentHistory,readingTemplate: templates)
                }
                ForEach(VM.dosageTemplates) { templates in
                    StopDataDosageChartView(stopData: VM.currentHistory,dosageTemplate: templates)
                }
            }
            .tabViewStyle(.page)
            .frame(minWidth: 300, minHeight: 150)
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 10))
        }

    }
    var tasks: some View {
        ZStack{
            //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                Rectangle()
                                    .fill(Color.realYellow)
                                    .frame(height: 5)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 30)
                                    Spacer()
                                }
                            }
                            Text("Tasks")
                                .foregroundColor(Color.basicFontText)
                                .padding(5)
                                .background(Color.realYellow)
                                .cornerRadius(5)
                        }
                    } else {
                        ZStack{
                            ZStack{
                                Rectangle()
                                    .fill(finished ? Color.poolGreen.opacity(0.25) : Color.gray.opacity(0.25))
                                    .frame(height: 5)
                                HStack{
                                    Circle()
                                        .fill(finished ? Color.poolGreen : Color.gray)
                                        .frame(width: 30)
                                    Spacer()
                                    Button(action: {
                                        showObservations.toggle()
                                    }, label: {
                                        ZStack{
                                            Circle()
                                                .fill(finished ? Color.poolGreen : Color.gray)
                                                .frame(width: 30)
                                            if showObservations {
                                                Image(systemName: "arrow.up.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            } else {
                                                Image(systemName: "arrow.down.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            }
                                        }
                                    })
                                    
                                }
                            }
                            Text("Tasks")
                                .foregroundColor(Color.white)
                                .padding(5)
                                .background(finished ? Color.poolGreen : Color.gray)
                                .cornerRadius(5)
                        }
                    }
                    
                }
                if showTasks {
                    if let stop = masterDataManager.selectedServiceStops {
                        StopDataTaskView(stop: stop, selectedTasks: $selectedTask)
                    }
                }
            }
            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            
        }
    }
    
    var observations: some View {
        ZStack{
            //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                Rectangle()
                                    .fill(Color.realYellow)
                                    .frame(height: 5)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 30)
                                    Spacer()
                                }
                            }
                            Text("Observations")
                                .foregroundColor(Color.basicFontText)
                                .padding(5)
                                .background(Color.realYellow)
                                .cornerRadius(5)
                        }
                    } else {
                        ZStack{
                            ZStack{
                                Rectangle()
                                    .fill(finished ? Color.poolGreen.opacity(0.25) : Color.gray.opacity(0.25))
                                    .frame(height: 5)
                                HStack{
                                    Circle()
                                        .fill(finished ? Color.poolGreen : Color.gray)
                                        .frame(width: 30)
                                    Spacer()
                                    Button(action: {
                                        showObservations.toggle()
                                    }, label: {
                                        ZStack{
                                            Circle()
                                                .fill(finished ? Color.poolGreen : Color.gray)
                                                .frame(width: 30)
                                            if showObservations {
                                                Image(systemName: "arrow.up.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            } else {
                                                Image(systemName: "arrow.down.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            }
                                        }
                                    })
                                    
                                }
                            }
                            Text("Observations")
                                .foregroundColor(Color.white)
                                .padding(5)
                                .background(finished ? Color.poolGreen : Color.gray)
                                .cornerRadius(5)
                        }
                    }
                    
                }
                if showObservations {
                    if let stop = masterDataManager.selectedServiceStops {
                        
                        StopDataObservationsView(stop: stop, selectedObservations: $selectedObservations)
                    }
                }
            }
            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            
        }
    }
    var readingInput: some View {
        ZStack{
            //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                Rectangle()
                                    .fill(Color.realYellow)
                                    .frame(height: 5)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 30)
                                    Spacer()
                                    Button(action: {
                                        showReadings.toggle()
                                    }, label: {
                                        ZStack{
                                            Circle()
                                                .fill(Color.realYellow)
                                                .frame(width: 30)
                                            if showReadings {
                                                Image(systemName: "arrow.up.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            } else {
                                                Image(systemName: "arrow.down.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            }
                                        }
                                    })
                                    Spacer()
                                    Button(action: {
                                            selectedInputId = ""
                                            stopData.readings = []
                                            showReadings = true
                                        
                                    }, label: {
                                        Text("Reset")
                                            .foregroundColor(Color.white)
                                            .padding(5)
                                            .background(Color.gray)
                                            .cornerRadius(5)
                                    })
                                    
                                }
                            }
                            Button(action: {
                                showReadings.toggle()
                            }, label: {
                                Text("Readings")
                                    .foregroundColor(Color.basicFontText)
                                    .padding(5)
                                    .background(Color.realYellow)
                                    .cornerRadius(5)
                            })
                            
                        }
                    } else {
                        if showReadings{
                            
                            ZStack{
                                ZStack{
                                    Rectangle()
                                        .fill(Color.poolGreen.opacity(0.5))
                                        .frame(height: 5)
                                    HStack{
                                        Circle()
                                            .fill(Color.poolGreen)
                                            .frame(width: 30)
                                        Spacer()
                                        Button(action: {
                                            showReadings.toggle()
                                        }, label: {
                                            ZStack{
                                                Circle()
                                                    .fill(Color.poolGreen)
                                                    .frame(width: 30)
                                                if showReadings {
                                                    Image(systemName: "arrow.up.circle")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 30)
                                                } else {
                                                    Image(systemName: "arrow.down.circle")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 30)
                                                }
                                            }
                                        })
                                        Spacer()
                                        Button(action: {
                                                stopData.readings = []
                                                stopData.dosages = []

                                                selectedObservations = []
                                                selectedInputId = ""
                                                showObservations = true
                                                showReadings = true
                                                showDosages = true
                                            
                                        }, label: {
                                            Text("Reset")
                                                .foregroundColor(Color.white)
                                                .padding(5)
                                                .background(Color.gray)
                                                .cornerRadius(5)
                                        })
                                        
                                    }
                                }
                                Button(action: {
                                    showReadings.toggle()
                                }, label: {
                                    Text("Readings")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.poolGreen)
                                        .cornerRadius(5)
                                })
                            }
                        } else {
                            
                            ZStack{
                                ZStack{
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(height: 5)
                                    HStack{
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 30)
                                        Spacer()
                                        Button(action: {
                                            showReadings.toggle()
                                        }, label: {
                                            ZStack{
                                                Circle()
                                                    .fill(Color.poolGreen)
                                                    .frame(width: 30)
                                                if showReadings {
                                                    Image(systemName: "arrow.up.circle")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 30)
                                                } else {
                                                    Image(systemName: "arrow.down.circle")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 30)
                                                }
                                            }
                                        })
                                        Spacer()
                                        Button(action: {
                                            //DEVELOPER I Wonder if this will actually update
                                                stopData.readings = []
                                                stopData.dosages = []
                                                selectedObservations = []
                                                selectedInputId = ""
                                                showObservations = true
                                                showReadings = true
                                                showDosages = true
                                            
                                        }, label: {
                                            Text("Reset")
                                                .foregroundColor(Color.white)
                                                .padding(5)
                                                .background(Color.gray)
                                                .cornerRadius(5)
                                        })
                                        
                                    }
                                }
                                Button(action: {
                                    showReadings.toggle()
                                }, label: {
                                    Text("Readings")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.gray)
                                        .cornerRadius(5)
                                })
                            }
                        }
                    }
                }
                if showReadings {
                        ForEach(VM.readingTemplates) { template in
                            StopDataReadingInputView(
                                stopDataList: $stopDataList,
                                template: template,
                                bodyOfWaterId: bodyOfWater.id,
                                selectedId: $selectedInputId,
                                selectedIdList: VM.selectedInputIdList,
                                stopData: $stopData,
                                serviceStopId: serviceStop.id,
                                serviceDate: serviceStop.serviceDate ?? Date(),
                                customerId: serviceStop.customerId,
                                serviceLocationId: serviceStop.serviceLocationId
                            )
                        }
                }
            }
            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            
        }
        
    }
    
    var dosageInput: some View {
        ZStack{
            //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                Rectangle()
                                    .fill(Color.realYellow)
                                    .frame(height: 5)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 30)
                                    Spacer()
                                    Button(action: {
                                        showDosages.toggle()
                                    }, label: {
                                        ZStack{
                                            Circle()
                                                .fill(Color.realYellow)
                                                .frame(width: 30)
                                            if showDosages {
                                                Image(systemName: "arrow.up.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            } else {
                                                Image(systemName: "arrow.down.circle")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 30)
                                            }
                                        }
                                    })
                                    Spacer()
                                    Button(action: {
                                            stopData.dosages = []
                                            selectedInputId = ""
                                            showDosages = true
                                        
                                    }, label: {
                                        Text("Reset")
                                            .foregroundColor(Color.white)
                                            .padding(5)
                                            .background(Color.gray)
                                            .cornerRadius(5)
                                    })
                                    
                                }
                            }
                            Button(action: {
                                showDosages.toggle()
                            }, label: {
                                Text("Dosages")
                                    .foregroundColor(Color.basicFontText)
                                    .padding(5)
                                    .background(Color.realYellow)
                                    .cornerRadius(5)
                            })
                            
                        }
                    } else {
                       
                            
                            ZStack{
                                ZStack{
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(height: 5)
                                    HStack{
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 30)
                                        Spacer()
                                        Button(action: {
                                            showDosages.toggle()
                                        }, label: {
                                            ZStack{
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 30)
                                                if showDosages {
                                                    Image(systemName: "arrow.up.circle")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 30)
                                                } else {
                                                    Image(systemName: "arrow.down.circle")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 30)
                                                }
                                            }
                                        })
                                        Spacer()
                                        Button(action: {
                                                stopData.dosages = []
                                                selectedInputId = ""
                                                showDosages = true
                                            
                                        }, label: {
                                            Text("Reset")
                                                .foregroundColor(Color.white)
                                                .padding(5)
                                                .background(Color.gray)
                                                .cornerRadius(5)
                                        })
                                    }
                                }
                                Button(action: {
                                    showDosages.toggle()
                                }, label: {
                                    Text("Dosages")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.gray)
                                        .cornerRadius(5)
                                })
                            }
                        
                        
                    }
                    
                }
                if showDosages {
                        ForEach(VM.dosageTemplates) { template in
                            StopDataDosageInputView(stopDataList: $stopDataList,
                                                    template: template,
                                                    bodyOfWaterId: bodyOfWater.id,
                                                    selectedId: $selectedInputId,
                                                    selectedIdList: selectedInputIdList,
                                                    stopData: $stopData,
                                                    serviceStopId:serviceStop.id,
                                                    serviceDate:serviceStop.serviceDate ?? Date(),
                                                    observations:selectedObservations,
                                                    gallons: Int(bodyOfWater.gallons) ?? 16_000)
                        }
                    
                }
            }
            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            
        }
    }
    var homeNav: some View {
        
        ZStack{
            if let stop = masterDataManager.selectedServiceStops {
                
                if skipped {
                    Button(action: {
#if os(iOS)
                        
                        let address = "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                        
                        let urlText = address.replacingOccurrences(of: " ", with: "?")
                        
                        let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                        
                        if UIApplication.shared.canOpenURL(url!) {
                            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                        }
#endif
                    }, label: {
                        HStack{
                            Image(systemName: "house.fill")
                            Text("\(stop.address.streetAddress)")
                        }
                        .frame(width: 200)
                        .padding(5)
                        .background(Color.realYellow)
                        .foregroundColor(Color.basicFontText)
                        .cornerRadius(10)
                        .font(.footnote)
                    })
                    
                    
                } else {
                    Button(action: {
#if os(iOS)
                        
                        let address = "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                        
                        let urlText = address.replacingOccurrences(of: " ", with: "?")
                        
                        let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                        
                        if UIApplication.shared.canOpenURL(url!) {
                            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                        }
#endif
                    }, label: {
                        HStack{
                            Image(systemName: "house.fill")
                            Text("\(stop.address.streetAddress)")
                        }
                        .frame(width: 200)
                        .padding(5)
                        .background(finished ? Color.poolGreen: Color.gray)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                    })
                    
                }
                
            }
        }
    }
    var icon: some View {
        ZStack{
            if let stop = masterDataManager.selectedServiceStops {
                
                if skipped {
                    ZStack{
                        ZStack{
                            Circle()
                                .fill(Color.realYellow)
                                .frame(width: 30)
                            Image(systemName: stop.typeImage)
                                .frame(width: 20)
                                .foregroundColor(Color.basicFontText)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                } else {
                    ZStack{
                        
                        ZStack{
                            Circle()
                                .fill(finished ? Color.poolGreen : Color.gray)
                                .frame(width: 30)
                            Image(systemName: getJobIcon(jobTypeId: stop.typeId))
                                .frame(width: 20)
                                .foregroundColor(Color.white)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                }
            }
        }
    }
}
