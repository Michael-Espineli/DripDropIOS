//
//  ServiceStopEquipmentView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI

struct ServiceStopEquipmentView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    
    let serviceStop: ServiceStop
    @Binding var stopData: StopData
    
    @State private var addNewEquipment: Bool = false
    
    private var equipmentList: [Equipment] {
        VM.listOfEquipment.filter { $0.bodyOfWaterId == VM.selectedBOW?.id }
    }
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                bodyOfWaterPicker
                ScrollView(showsIndicators: false) {
                    equipmentSection
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .padding(.top)
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany,
               let BOW = VM.selectedBOW {
                try? await VM.getAllEquipmentFromBodyOfWater(
                    companyId: currentCompany.id,
                    bodyOfWater: BOW
                )
            }
        }
        .onChange(of: VM.selectedBOW) { BOW in
            if let BOW {
                Task {
                    if serviceStop.otherCompany,
                       serviceStop.contractedCompanyId != "" {
                        try? await VM.getAllEquipmentFromBodyOfWater(
                            companyId: serviceStop.contractedCompanyId,
                            bodyOfWater: BOW
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Body Of Water Picker

extension ServiceStopEquipmentView {
    
    var bodyOfWaterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                
                if VM.bodiesOfWater.isEmpty {
                    Text("No Bodies of Water")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(VM.bodiesOfWater) { BOW in
                        Button {
                            VM.selectedBOW = BOW
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: VM.selectedBOW == BOW ? "drop.fill" : "drop")
                                Text(BOW.name)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        VM.selectedBOW == BOW
                                        ? Color.poolGreen
                                        : Color.gray.opacity(0.15)
                                    )
                            )
                            .foregroundStyle(
                                VM.selectedBOW == BOW
                                ? Color.white
                                : Color.primary
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Equipment Section

extension ServiceStopEquipmentView {
    
    var equipmentSection: some View {
        VStack(spacing: 16) {
            
            if let BOW = VM.selectedBOW {
                
                ForEach(equipmentList) { datum in
                    EquipmentCard(
                        serviceStop: serviceStop,
                        equipmentId: datum.id,
                        stopData: $stopData
                    )
                }
                
                Button {
                    addNewEquipment.toggle()
                } label: {
                    HStack {
                        Spacer()
                        Text("Add New Equipment")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                }
                .sheet(isPresented: $addNewEquipment) {
                    AddEquipmentView(dataService: dataService, bodyOfWater: BOW)
                }
            }
        }
    }
}

// MARK: - Equipment Card

struct EquipmentCard: View {
    
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    
    let serviceStop: ServiceStop
    let equipmentId: String
    @Binding var stopData: StopData
    
    @State private var pressure: String = ""
    @State private var showEquipment: Bool = false
    @State private var equipmentStatus: EquipmentStatus = .operational
    @State private var showEquipmentStatus: Bool = false
    
    private var equipment: Equipment? {
        VM.listOfEquipment.first { $0.id == equipmentId }
    }
    
    var body: some View {
        if let equipment {
            
            VStack(alignment: .leading, spacing: 14) {
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(equipment.name)
                            .font(.headline)
                        
                        Text("\(equipment.type.rawValue) • \(equipment.make) \(equipment.model)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    NavigationLink(
                        value: Route.equipmentDetailView(
                            equipment: equipment,
                            dataService: dataService
                        )
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Status Row
                HStack {
                    Button {
                        showEquipmentStatus.toggle()
                    } label: {
                        Text(equipmentStatus.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.15))
//                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button("Edit") {
                        showEquipment.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Filter Section
                if equipment.type == .filter {
                    filterSection(equipment: equipment)
                }
                
                // Info Section
                infoSection(equipment: equipment)
            }
            .ddCard()
            .sheet(isPresented: $showEquipment) {
                EditEquipmentView(dataService: dataService, equipment: equipment)
            }
            .sheet(isPresented: $showEquipmentStatus) {
                EquipmentStatusPicker(
                    dataService: dataService,
                    status: $equipmentStatus
                )
                .presentationDetents([.fraction(0.3), .fraction(0.5)])
            }
            .onAppear {
                equipmentStatus = equipment.status
                if let measurement = stopData.equipmentMeasurements.first(where: { $0.equipmentId == equipment.id }) {
                    pressure = String(measurement.poundForcePerSquareInch ?? 0)
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch equipmentStatus {
        case .operational: return .blue
        case .nonoperational: return .red
        case .needsRepair: return .orange
        case .needsMaintenance: return .yellow
        }
    }
    
    @ViewBuilder
    private func filterSection(equipment: Equipment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                Text("Pressure")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                TextField("PSI", text: $pressure)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            if let cleanPressure = equipment.cleanFilterPressure {
                
                Divider()
                
                HStack {
                    Text("Clean Pressure")
                    Spacer()
                    Text("\(Int(cleanPressure)) PSI")
                }
                .font(.footnote)
                
                HStack {
                    Text("Dirty Level")
                    Spacer()
                    
                    let current = Int(pressure) ?? equipment.currentPressure ?? 0
                    let difference = Double(current) - Double(cleanPressure)
                    let percent = (difference / 15) * 100
                    
                    Text("\(String(format: "%.0f", percent))%")
                }
                .font(.footnote)
            }
            
            HStack {
                Text("Last Cleaned")
                Spacer()
                Text(shortDate(date: equipment.lastServiceDate))
            }
            .font(.footnote)
        }
    }
    
    @ViewBuilder
    private func infoSection(equipment: Equipment) -> some View {
        VStack(spacing: 6) {
            Divider()
            

            HStack {
                Text("Installed")
                Spacer()
                Text(shortDate(date: equipment.dateInstalled))
                Text("(\(String(format: "%.1f", numberOfYearsBetween(equipment.dateInstalled, Date()))) yrs)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .font(.footnote)
    }
}
private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddSectionTitle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}


/*
    struct ServiceStopEquipmentView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel

    let serviceStop:ServiceStop
    @Binding var stopData : StopData

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

    private var equipmentList: [Equipment] {
        VM.listOfEquipment.filter( {$0.bodyOfWaterId == VM.selectedBOW?.id})
    }
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    var equipmentCheckUp: some View {
        VStack{
            
            if let BOW = VM.selectedBOW {
                Rectangle()
                    .frame(height: 1)
                ForEach(equipmentList) { datum in
                    serviceStopEquipmentCheck( serviceStop: serviceStop,equipmentId: datum.id, stopData: $stopData)
                    Rectangle()
                        .frame(height: 1)
                }
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
            }
        }
    }
    }

    struct serviceStopEquipmentCheck: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject private var VM: ServiceStopDetailViewModel

    @State var serviceStop:ServiceStop
    @State var equipmentId:String
    @Binding var stopData : StopData

    @State var qualityCheck:Bool = false
    @State var pressure:String = ""
    @State var showEquipment:Bool = false

    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var equipmentStatus:EquipmentStatus = .operational
    @State var showEquipmentStatus:Bool = false
    @FocusState var pressureInput:Bool
    private var equipment:Equipment? {
        VM.listOfEquipment.first { $0.id == equipmentId }
    }
    var body: some View {
        if let equipment {
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
                    Text("\(equipment.type.rawValue)")
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
                if equipment.type == .filter {
                    HStack{
                        Text("Pressure: ")
                        TextField(
                            "Pressure",
                            text: $pressure
                        )
                        .keyboardType(.decimalPad)
                        .foregroundColor(Color.poolBlack)
                        .modifier(TextFieldModifier())
                        .focused($pressureInput)
                        Button(action: {
                            qualityCheck.toggle()
                        },
                               label: {
                            Image(systemName: qualityCheck ? "checkmark.square.fill" : "square")
                                .modifier(SubmitButtonModifier())
                        })
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
                if let measurement = stopData.equipmentMeasurements.first(where: {$0.equipmentId == equipment.id}) {
                    pressure = String(measurement.poundForcePerSquareInch ?? 0)
                } else {
                    pressure = ""
                }
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
            .onChange(
                of: pressure,
                perform: { datum in
                    Task{
                        if equipment.type == .filter  {
                            if datum != "" {
                                if datum.isNumber {
                                    print("Add Update")
                                    if let company = masterDataManager.currentCompany {
                                        do {
                                            let measurement = EquipmentMeasurements(
                                                id: UUID().uuidString,
                                                equipmentId: equipment.id,
                                                date: Date(),
                                                status: equipmentStatus,
                                                poundForcePerSquareInch: Int(datum)
                                            )
                                            if let currentPressure = equipment.currentPressure{
                                                let difference = Int(datum)! - currentPressure
                                                if difference > 15 {
                                                    equipmentStatus = .needsMaintenance
                                                }
                                            }
                                            stopData.equipmentMeasurements.removeAll(where: { $0.equipmentId == equipment.id })
                                            stopData.equipmentMeasurements.append(measurement)
                                            
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
    }

    extension serviceStopEquipmentCheck {
    var graphicView: some View {
        
        VStack{
            if let equipment {
                if equipment.type == .filter {
                    
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
}
*/
