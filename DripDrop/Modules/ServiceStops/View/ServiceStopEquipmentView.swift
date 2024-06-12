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
    
    @State var bodyOfWater:BodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "")
    @State var addNewEquipment:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                bodyOfWaterPicker
                equipmentCheckUp
            }
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 5))
        }
    }
}
extension ServiceStopEquipmentView {
    var bodyOfWaterPicker: some View {
        ZStack{
            //            sideBar
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
    var equipmentCheckUp: some View {
        VStack{
            if let BOW = VM.selectedBOW {
                Divider()
                ForEach(VM.listOfEquipment) { equipment in
                    serviceStopEquipmentCheck(equipment: equipment)
                    Divider()
                }
                Button(action: {
                    addNewEquipment.toggle()
                }, label: {
                    HStack{
                        Text("Add New Equipment")
                    }
                    .foregroundColor(Color.basicFontText)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.poolBlue)
                    .cornerRadius(8)
                    .padding(.horizontal,16)
                })
                .sheet(isPresented: $addNewEquipment, onDismiss: {
                }, content: {
                    AddEquipmentView(dataService: dataService, bodyOfWater: BOW)
                })
            }
        }
        .padding(.horizontal,16)
    }
}
struct serviceStopEquipmentCheck: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel

    @State var equipment:Equipment
    @State var qualityCheck:Bool = false
    @State var pressure:String = ""
    @State var showEqidEquipment:Bool = false
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var equipmentStatus:EquipmentStatus = .operational

    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    showEqidEquipment.toggle()
                }, label: {
                   Image(systemName: "pencil")
                })
                .sheet(isPresented: $showEqidEquipment, content: {
                    EditEquipmentView(dataService: dataService, equipment: equipment)
                })
                Text("\(equipment.name)")
          
                    
                Spacer()
      
                Button(action: {
                    Task{
                        if let company = masterDataManager.selectedCompany {
                            do {
                                let measurement = EquipmentMeasurements(
                                    id: UUID().uuidString,
                                    date: Date(),
                                    status: equipmentStatus,
                                    psi: Int(pressure)
                                )
                                try await VM.createEquipmentMeasurment(
                                    companyId: company.id,
                                    equipmentId: equipment.id,
                                    measurment: measurement
                                )
                                VM.EquipmentReadings[equipment] = measurement
                                qualityCheck.toggle()
                                
                            } catch {
                                print(error)
                            }
                        }
                    }
                },
                       label: {
                    Image(systemName: qualityCheck ? "checkmark.square.fill" : "square")
                        .font(.headline)
                        .foregroundColor(Color.white)
                        .padding(3)
                        .background(qualityCheck ? Color.poolGreen : Color.poolRed)
                        .cornerRadius(5)
                        .padding(5)
                })
                
                
            }
            HStack{
                Text("\(equipment.category)")
                Text("\(equipment.make)")
                Text("\(equipment.model)")

            }
            if equipment.category == .filter {
                TextField(
                    "Pressure",
                    text: $pressure,
                    axis: .vertical
                )
                .padding(8)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(Color.black)
                .keyboardType(.decimalPad)
            }
            HStack{
                Picker("Type", selection: $equipmentStatus) {
                    ForEach(EquipmentStatus.allCases,id: \.self){ status in
                        Text(status.rawValue).tag(status)
                    }
                }
                Spacer()
                NavigationLink(value: Route.equipmentDetailView(dataService: dataService), label: {
                    HStack{
                        Text("Details")
                        Image(systemName: "chevron.right")
                    }
                })
            }
            graphicView
        }
        .padding(10)
        .onChange(of: qualityCheck, perform: { check in
            if equipment.category == .filter && pressure == "" {
                qualityCheck = false
                alertMessage = "Please actually Check Pressure"
                print(alertMessage)
                showAlert = true
            } else {
                
                print("Add Update")
            }

        })
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

extension serviceStopEquipmentCheck {
    var graphicView: some View {
        VStack{
            HStack{
                Text("Installation: \(fullDate(date: equipment.dateInstalled))")
                Spacer()
            }
            HStack{
                if equipment.category == .filter {
                    
                    if let cleanPressure  = equipment.cleanFilterPressure  {
                        Text("Clean Preasures: \(String(format: "%.0f", Double(cleanPressure )))")
                        if pressure == "" {
                            if let currentPressure = equipment.currentPressure {
                                let difference = Double(Int(currentPressure) - cleanPressure)
                                Text("Dirty: \(String(format: "%.0f",(difference/15)*100)) %")
                            }
                        } else {
                            let difference = Double(( Int(pressure) ?? 0) - cleanPressure)
                            Text("Dirty: \(String(format: "%.0f",(difference/15)*100)) %")
                        }
                    }
                    Text("Last Cleaned: \(shortDate(date:equipment.lastServiceDate))")
                }
                Spacer()

            }
        }
    }
}
