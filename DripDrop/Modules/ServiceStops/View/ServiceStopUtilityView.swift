    //
    //  ServiceStopInfoView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/3/23.
    //



import SwiftUI

struct ServiceStopUtilityView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var navigationManager: NavigationStateManager
    
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel
    
    @Binding var stopData : StopData
    @State var serviceStopId: String
    
    @State var finished:Bool = false
    @State var skipped:Bool = false
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var invoiced:Bool = false
    @State var stopDataList:[StopData] = []
    @State var initialLoadFinished:Bool = false
    @State var previousStopDataView:String = "Table"
    @State var previousStopDataViewoptions:[String] = ["Table","Chart"]
    @State var selectedObservations:[String] = []
    @State var selectedTask:[String] = []
    
    @State var selectedInputId:String = ""
    @State var selectedInputIdList:[String] = []
    
    @State var showObservations:Bool = false
    @State var showTasks:Bool = true
    
    @State var showReadings:Bool = true
    @State var showDosages:Bool = true
    @FocusState var chemicalInput:Bool

    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )
    
    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            if let serviceStop {
                VStack(spacing:0){
                    bodyOfWaterPicker
                    ScrollView(showsIndicators:false){
                        if let bodyOfWater = VM.selectedBOW {
                            if bodyOfWater.id ==  "" {
                                Text("No Bodies of Water")
                                    .foregroundColor(.secondary)
                            } else {
                                    //Replace with the version of stopData in the customer service history Page
                                previousStopData
                                
                                observations(serviceStop)
                                
                                if serviceStop.includeReadings {
                                    readingInput(serviceStop)
                                }
                                if serviceStop.includeDosages {
                                    dosageInput(serviceStop)
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                }
                .background(Color.black.opacity(0.02))
                .cornerRadius(12)
                .disabled(vm.activeRoute?.status != .inProgress)
                .disabled(serviceStop.startTime == nil)
                .animation(.easeInOut(duration: 0.2), value: VM.selectedBOW?.id)
                .onChange(of: VM.selectedBOW, perform: { BOW in
                    Task{
                        if let bodyOfWater = BOW, let user = masterDataManager.user {
                            print("Body Of Water Change \(bodyOfWater.id)")
                            await VM.onChangeOfBodyOfWater(bodyOfWater: bodyOfWater)
                            stopData = VM.serviceLocationStopData.first(where: { $0.serviceLocationId == serviceStop.serviceLocationId }) ?? StopData(
                                id: UUID().uuidString,
                                date: serviceStop.serviceDate,
                                serviceStopId: serviceStop.id,
                                readings: [],
                                dosages: [],
                                observation: [],
                                bodyOfWaterId: bodyOfWater.id,
                                customerId: serviceStop.customerId,
                                serviceLocationId: serviceStop.serviceLocationId,
                                userId: user.id,
                                equipmentMeasurements: []
                            )
                        }
                    }
                })
                .onChange(of: serviceStop, perform: { stop in
                    print("Service Stop Change From Utility View")
                })
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let serviceStop,
               let continuationGate = continuationGate(for: serviceStop) {
                ServiceStopContinuationBanner(title: continuationGate.title) {
                    handleContinuationGate(continuationGate, serviceStop: serviceStop)
                }
            }
        }
    }
}

extension ServiceStopUtilityView {
    private func continuationGate(for serviceStop: ServiceStop) -> ServiceStopContinuationGate? {
        if vm.activeRoute?.status.requiresStartToContinueServiceStopWork == true {
            return .startRoute
        }

        if serviceStop.startTime == nil {
            return .startServiceStop
        }

        return nil
    }

    private func handleContinuationGate(_ gate: ServiceStopContinuationGate, serviceStop: ServiceStop) {
        switch gate {
        case .startRoute:
            vm.startActiveRoute(
                companyId: masterDataManager.currentCompany?.id,
                companyName: masterDataManager.currentCompany?.name,
                user: masterDataManager.user
            )
        case .startServiceStop:
            vm.startServiceStop(
                companyId: masterDataManager.currentCompany?.id,
                serviceStopId: serviceStop.id,
                startTime: vm.arrivalTimeForServiceStop(serviceStop.id) ?? Date()
            )
        }
    }

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
        HStack(spacing: 0){
            ScrollView(.horizontal,showsIndicators: false){
                HStack{
                    if VM.bodiesOfWater.isEmpty {
                        Text("No Bodies of Water")
                    } else {
                        ForEach(VM.bodiesOfWater) { BOW in
                            Button(action: {
                                VM.selectedBOW = BOW
                            }, label: {
                                HStack(spacing: 6) {
                                    Image(systemName: VM.selectedBOW == BOW ? "drop.fill" : "drop")
                                    Text("\(BOW.name)")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Group {
                                        if VM.selectedBOW == BOW {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.poolGreen)
                                        } else {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.gray.opacity(0.4))
                                        }
                                    }
                                )
                                .foregroundStyle(VM.selectedBOW == BOW ? Color.white : Color.primary)
                            })
                            .padding(.horizontal,4)
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(8)
    }

    var previousStopData: some View {
        ZStack{
            VStack(spacing:0){
                if !VM.currentHistory.isEmpty {
                    if let first = VM.currentHistory.first {
                        HStack{
                            Spacer()
                            NavigationLink(value: Route.customerStopDataDetailView(dataService: dataService, customerId: first.customerId), label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.right.circle.fill")
                                    Text("See Details")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolGreen.opacity(0.15)))
                                .foregroundStyle(Color.poolGreen)
                            })
                            
                        }
                        .padding(.top,8)
                    }
                    ScrollView(.horizontal,showsIndicators: false){
                        StopDataTableView(stopData: VM.currentHistory, readingTemplates: VM.readingTemplates, dosageTemplates: VM.dosageTemplates)
                    }
                } else {
                    Text("No Data Yet")
                }
            }
            .padding(.horizontal,8)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            
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
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.realYellow)
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                }
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Tasks")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.realYellow))
                            .foregroundStyle(Color.basicFontText)
                        }
                    } else {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(finished ? Color.poolGreen.opacity(0.25) : Color.gray.opacity(0.25))
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(finished ? Color.poolGreen : Color.gray)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                    Button(action: {
                                        showObservations.toggle()
                                    }, label: {
                                        ZStack {
                                            Circle().fill(finished ? Color.poolGreen : Color.gray)
                                            Image(systemName: showObservations ? "chevron.up" : "chevron.down")
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    })
                                    
                                }
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Tasks")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill((finished ? Color.poolGreen : Color.gray)))
                            .foregroundStyle(Color.white)
                        }
                    }
                    
                }
                if showTasks {
                    if let stop = masterDataManager.selectedServiceStops {
                        StopDataTaskView(stop: stop, selectedTasks: $selectedTask)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            
        }
    }
    
    private func observations(_ serviceStop: ServiceStop) -> some View {

        ZStack{
                //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.realYellow)
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                }
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Observations")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.realYellow))
                            .foregroundStyle(Color.basicFontText)
                        }
                    } else {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(finished ? Color.poolGreen.opacity(0.25) : Color.gray.opacity(0.25))
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(finished ? Color.poolGreen : Color.gray)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                    Button(action: {
                                        stopData.observation = []
                                        selectedInputId = ""
                                        showDosages = true
                                    }, label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.counterclockwise")
                                            Text("Reset")
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                        .foregroundColor(Color.poolWhite)
                                    })
                                    
                                }
                            }
                            Button(action: {
                                showObservations.toggle()
                            }, label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Observations")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill((finished ? Color.poolGreen : Color.gray)))
                                .foregroundStyle(Color.poolWhite)
                            })
                        }
                    }
                    
                }
                if showObservations {
                    StopDataObservationsView(stop: serviceStop, selectedObservations: $selectedObservations, stopData: $stopData)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            
        }
    }
    private func readingInput(_ serviceStop: ServiceStop) -> some View {
        ZStack{
                //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.realYellow)
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                    Button(action: {
                                        selectedInputId = ""
                                        stopData.readings = []
                                        showReadings = true
                                        
                                    }, label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.counterclockwise")
                                            Text("Reset")
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                        .foregroundColor(Color.poolWhite)
                                    })
                                    
                                }
                            }
                            Button(action: {
                                showReadings.toggle()
                            }, label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Readings")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.realYellow))
                                .foregroundStyle(Color.basicFontText)
                            })
                            
                        }
                    } else {
                        if showReadings{
                            
                            ZStack{
                                ZStack{
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.poolGreen.opacity(0.5))
                                        .frame(height: 6)
                                    HStack{
                                        Circle()
                                            .fill(Color.poolGreen)
                                            .frame(width: 28, height: 28)
                                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset")
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                            .foregroundColor(Color.poolWhite)
                                        })
                                        
                                    }
                                }
                                Button(action: {
                                    showReadings.toggle()
                                }, label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Readings")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolGreen))
                                    .foregroundStyle(Color.white)
                                })
                            }
                        } else {
                            
                            ZStack{
                                ZStack{
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(height: 6)
                                    HStack{
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 28, height: 28)
                                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset")
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                            .foregroundStyle(Color.poolWhite)
                                        })
                                        
                                    }
                                }
                                Button(action: {
                                    showReadings.toggle()
                                }, label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Readings")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray))
                                    .foregroundStyle(Color.white)
                                })
                            }
                        }
                    }
                }
                if showReadings {
                    VStack(spacing: 0){
                        ForEach(VM.readingTemplates) { template in
                            StopDataReadingInputView(
                                stopDataList: $stopDataList,
                                template: template,
                                bodyOfWaterId: bodyOfWater.id,
                                selectedId: $selectedInputId,
                                selectedIdList: VM.selectedInputIdList,
                                stopData: $stopData,
                                serviceStopId: serviceStop.id,
                                serviceDate: serviceStop.serviceDate,
                                customerId: serviceStop.customerId,
                                serviceLocationId: serviceStop.serviceLocationId
                            )
                        }
                    }
                    .padding(.top,15)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
    private func dosageInput(_ serviceStop: ServiceStop) -> some View {
        ZStack{
                //            sideBar
            VStack(spacing:0){
                ZStack{
                    if skipped {
                        ZStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.realYellow)
                                    .frame(height: 6)
                                HStack{
                                    Circle()
                                        .fill(Color.realYellow)
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    Spacer()
                                    Button(action: {
                                        stopData.readings = []
                                        selectedInputId = ""
                                        showDosages = true
                                        
                                    }, label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.counterclockwise")
                                            Text("Reset")
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                        .foregroundStyle(Color.poolWhite)
                                    })
                                    
                                }
                            }
                            Button(action: {
                                showDosages.toggle()
                            }, label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Dosages")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.realYellow))
                                .foregroundStyle(Color.basicFontText)
                            })
                        }
                    } else {
                        if showDosages {
                            ZStack{
                                ZStack{
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.poolGreen.opacity(0.5))
                                        .frame(height: 6)
                                    HStack{
                                        Circle()
                                            .fill(Color.poolGreen)
                                            .frame(width: 28, height: 28)
                                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                        Spacer()
                                        Button(action: {
                                            stopData.dosages = []
                                            selectedInputId = ""
                                            showDosages = true
                                            
                                        }, label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset")
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                            .foregroundStyle(Color.poolWhite)
                                        })
                                    }
                                }
                                Button(action: {
                                    showDosages.toggle()
                                }, label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Dosages")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolGreen))
                                    .foregroundStyle(Color.white)
                                })
                            }
                            
                        } else {
                            ZStack{
                                ZStack{
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(height: 6)
                                    HStack{
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 28, height: 28)
                                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                        Spacer()
                                        Button(action: {
                                            stopData.dosages = []
                                            selectedInputId = ""
                                            showDosages = true
                                            
                                        }, label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.counterclockwise")
                                                Text("Reset")
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolBlue))
                                            .foregroundStyle(Color.poolWhite)
                                        })
                                    }
                                }
                                Button(action: {
                                    showDosages.toggle()
                                }, label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Dosages")
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray))
                                    .foregroundStyle(Color.white)
                                })
                            }
                        }
                    }
                }
                if showDosages {
                    VStack(spacing: 0){
                        ForEach(VM.dosageTemplates) { template in
                            StopDataDosageInputView(
                                stopDataList: $stopDataList,
                                template: template,
                                bodyOfWaterId: bodyOfWater.id,
                                selectedId: $selectedInputId,
                                selectedIdList: selectedInputIdList,
                                stopData: $stopData,
                                serviceStopId:serviceStop.id,
                                serviceDate:serviceStop.serviceDate,
                                observations:selectedObservations,
                                gallons: Int(
                                    bodyOfWater.gallons
                                ) ?? 16_000
                            )
                        }
                    }
                    .padding(.top,15)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            
        }
    }
    var homeNav: some View {
        
        ZStack{
            if let stop = masterDataManager.selectedServiceStops {
                
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
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("\(stop.address.streetAddress)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(skipped ? Color.realYellow : (finished ? Color.poolGreen : Color.gray))
                    )
                    .foregroundStyle(skipped ? Color.basicFontText : Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                })
                
                
            }
        }
    }
}
