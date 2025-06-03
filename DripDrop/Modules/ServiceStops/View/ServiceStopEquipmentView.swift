    //
    //  ServiceStopEquipmentView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 1/11/24.
    //

import SwiftUI

struct ServiceStopEquipmentView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    
    let serviceStop:ServiceStop
    
    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date()
    )
    @State var addNewEquipment:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing:0){
                bodyOfWaterPicker
                ScrollView{
                    equipmentCheckUp
                }
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
            }
        }
        .fontDesign(.monospaced)
        .task {
            if let currentCompany = masterDataManager.currentCompany, let BOW = VM.selectedBOW {
                Task{
                    do {
                        try await VM.getAllEquipmentFromBodyOfWater(companyId: currentCompany.id, bodyOfWater: BOW)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: VM.selectedBOW, perform: { BOW in
            if let currentCompany = masterDataManager.currentCompany, let BOW {
                Task{
                    do {
                        
                        if serviceStop.otherCompany {
                            if serviceStop.contractedCompanyId != "" {
                                try await VM.getAllEquipmentFromBodyOfWater(companyId: serviceStop.contractedCompanyId, bodyOfWater: BOW)
                            }
                        } 
                        
                    } catch {
                        print(error)
                    }
                }
            }
        })
    }
}
extension ServiceStopEquipmentView {
    var bodyOfWaterPicker: some View {
        HStack(spacing: 0){
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
                                        .modifier(SubmitButtonModifier())
                                } else {
                                    Text("\(BOW.name)")
                                        .modifier(ListButtonModifier())
                                }
                            })
                            .padding(.horizontal,4)
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
        }
        .padding(.vertical,8)
        .background(Color.darkGray.opacity(0.5))
    }
    var equipmentCheckUp: some View {
        VStack{
            if let BOW = VM.selectedBOW {
                Button(action: {
                    addNewEquipment.toggle()
                }, label: {
                    HStack{
                        Text("Add New Equipment")
                    }
                    .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $addNewEquipment, onDismiss: {
                    print("On Dismiss of New Equipment")
                }, content: {
                    AddEquipmentView(dataService: dataService, bodyOfWater: BOW)
                })
                Rectangle()
                    .frame(height: 1)
                ForEach(VM.listOfEquipment) { equipment in
                    serviceStopEquipmentCheck( serviceStop: serviceStop,equipment: equipment)
                    Rectangle()
                        .frame(height: 1)
                }
            }
        }
    }
}

struct serviceStopEquipmentCheck: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    
    @State var serviceStop:ServiceStop
    @State var equipment:Equipment
    
    @State var qualityCheck:Bool = false
    @State var pressure:String = ""
    @State var showEquipment:Bool = false
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var equipmentStatus:EquipmentStatus = .operational
    @State var showEquipmentStatus:Bool = false

    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    showEquipment.toggle()
                }, label: {
                    Text("Edit")
                        .modifier(AddButtonModifier())
                })
                .padding(.leading,8)
                .sheet(isPresented: $showEquipment, content: {
                    EditEquipmentView(dataService: dataService, equipment: equipment)
                })
                Spacer()
                Text("\(equipment.name)")
                Spacer()
                NavigationLink(value: Route.equipmentDetailView(equipment: equipment, dataService: dataService), label: {
                    HStack{
                        Text("Details")
                        Image(systemName: "chevron.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }
            Divider()
            HStack{
                Text("\(equipment.category.rawValue)")
                Text("\(equipment.make)")
                Text("\(equipment.model)")
                Spacer()
            }
            HStack{
                Button(action: {
                    showEquipmentStatus.toggle()
                }, label: {
                    switch equipmentStatus {
                    case .operational:
                        Text(equipmentStatus.rawValue)
                            .modifier(BlueButtonModifier())
                    case .nonoperational:
                        Text(equipmentStatus.rawValue)
                            .modifier(DismissButtonModifier())
                    case .needsRepair:
                        Text(equipmentStatus.rawValue)
                            .modifier(OrangeButtonModifier())
                    case .needsMaintenance:
                        Text(equipmentStatus.rawValue)
                            .modifier(YellowButtonModifier())
                    }
                })
                .sheet(isPresented: $showEquipmentStatus, content: {
                    EquipmentStatusPicker(dataService: dataService, status: $equipmentStatus)
                        .presentationDetents([.fraction(0.3),.fraction(0.5)])
                })
                Spacer()
            }
            if equipment.category == .filter {
                HStack{
                    Text("Pressure: ")
                    TextField(
                        "Pressure",
                        text: $pressure
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(Color.poolBlack)
                    .modifier(TextFieldModifier())
//                    Button(action: {
//                        qualityCheck.toggle()
//
//
//                    },
//                           label: {
                        Image(systemName: qualityCheck ? "checkmark.square.fill" : "square")
                            .modifier(SubmitButtonModifier())
//                    })
                }
                .modifier(ListButtonModifier())
                .modifier(OutLineButtonModifier())
            }
  
            graphicView
        }
        .padding(10)
        
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear(perform: {
            equipmentStatus = equipment.status
        })
        .onChange(of: equipmentStatus, perform: { status in
            if status != equipment.status {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        print("Updating Equipment Status: \(status)")
                        try VM.updateEquipmentStatus(companyId: currentCompany.id, serviceStop: serviceStop, equipmentId: equipment.id, status: status)
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            } else {
                print("Status Is Same As Received")
            }
        })
        .onChange(of: pressure, perform: { datum in
            Task{
                if equipment.category == .filter  {
                    if datum != "" {
                        if datum.isNumber {
                        print("Add Update")
                            if let company = masterDataManager.currentCompany {
                                do {
                                    let measurement = EquipmentMeasurements(
                                        id: UUID().uuidString,
                                        date: Date(),
                                        status: equipmentStatus,
                                        psi: Int(datum)
                                    )
                                    if let currentPressure = equipment.currentPressure{
                                        let difference = Int(datum)! - currentPressure
                                        if difference > 15 {
                                            equipmentStatus = .needsMaintenance
                                        }
                                    }
                                    if serviceStop.otherCompany {
                                        if let mainCompanyId = serviceStop.mainCompanyId {
                                            
                                            try await VM.createEquipmentMeasurment(
                                                companyId: mainCompanyId,
                                                equipmentId: equipment.id,
                                                measurment: measurement
                                            )
                                        }
                                    } else {
                                         
                                        try await VM.createEquipmentMeasurment(
                                            companyId: company.id,
                                            equipmentId: equipment.id,
                                            measurment: measurement
                                        )
                                    }
                                    VM.EquipmentReadings[equipment] = measurement
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }
            
        })
    }
}

extension serviceStopEquipmentCheck {
    var graphicView: some View {
        VStack{
            if equipment.category == .filter {
                
                if let cleanPressure  = equipment.cleanFilterPressure  {
                    HStack{
                        Text("Clean Preasures: ")
                            .bold()
                        Spacer()
                        Text("\(String(format: "%.0f", Double(cleanPressure ))) PSI")
                    }
                    if pressure == "" {
                        if let currentPressure = equipment.currentPressure {
                            let difference = Double(Int(currentPressure) - cleanPressure)
                            HStack{
                                Text("Dirty: ")
                                    .bold()
                                Spacer()
                                Text("\(String(format: "%.0f",(difference/15)*100)) %")
                            }
                        }
                    } else {
                        let difference = Double(( Int(pressure) ?? 0) - cleanPressure)
                        HStack{
                            Text("Dirty: ")
                                .bold()
                            Spacer()
                            Text("\(String(format: "%.0f",(difference/15)*100)) %")
                        }
                    }
                }
                Divider()
                HStack{
                    Text("Last Cleaned: ")
                        .bold()
                    Spacer()
                    Text(shortDate(date:equipment.lastServiceDate))
                }
                HStack{
                    Text("Installed: ")
                        .bold()
                    Spacer()
                    Text(shortDate(date: equipment.dateInstalled))
                    Text("(\(String(format: "%.1f", numberOfYearsBetween(equipment.dateInstalled, Date()))) years)")
                        .font(.footnote)
                }
            }
            Spacer()
            
        }
        
    }
}
