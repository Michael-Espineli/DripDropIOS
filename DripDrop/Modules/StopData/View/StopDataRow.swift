//
//  StopDataRow.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//


import SwiftUI

struct StopDataRow: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var serviceStopVM : ServiceStopsViewModel
    init(dataService:any ProductionDataServiceProtocol,stopData:StopData,readingTemplates:[SavedReadingsTemplate],dosageTemplate:[SavedDosageTemplate]) {
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopData = State(initialValue: stopData)
        _readingTemplates = State(initialValue: readingTemplates)
        _dosageTemplate = State(initialValue: dosageTemplate)
    }
    
    @State var stopData:StopData
    @State var readingTemplates:[SavedReadingsTemplate]
    @State var dosageTemplate:[SavedDosageTemplate]
    
    var body: some View {
        HStack{
            date
            readings
            dosages
            Button(action: {
                Task{
                    print("Show Detail View For Service Stop \(stopData.serviceStopId)")
                    if let company = masterDataManager.currentCompany {
                        do {
                            try await serviceStopVM.getServiceStopById(companyId: company.id, serviceStopId: stopData.serviceStopId)
                            if let stop = serviceStopVM.serviceStop {
                                masterDataManager.selectedServiceStops = stop
                                //DEVELOPER CHANGE NAVIGATION LINK
                                navigationManager.routes.append(Route.serviceStop(serviceStop: stop, dataService:dataService))
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }, label: {
                Text("S0000000")
                    .font(.footnote)
                    .foregroundColor(Color.clear)
                    .overlay(Text("\(stopData.serviceStopId)"))
            })
            
            Spacer()
        }
        
    }
}
extension StopDataRow {
    
    
    var date: some View {
        Text("00-00-00")
            .foregroundColor(Color.clear)
            .overlay( Text(shortDate(date:stopData.date)))
        
    }
    var readings: some View {
        HStack{
            ForEach(readingTemplates){ reading in
                
                let amount:String = stopData.readings.first(where: {$0.templateId == reading.readingsTemplateId})?.amount ?? "0"
                if ((Double(amount) ?? 0) >= (reading.highWarning ?? 0)) || ((Double(amount) ?? 0) <= (reading.lowWarning ?? 0)) {
                    
                    Text("\(reading.name)")
                        .font(.footnote)
                        .frame(width: 50)
                        .foregroundColor(Color.clear)
                        .overlay(
                            Text(amount == "0" ? "-" : "\(amount)")
                                .foregroundStyle(Color.red)
                        )
                } else {
                    Text("\(reading.name)")
                        .font(.footnote)
                        .frame(width: 50)
                        .foregroundColor(Color.clear)
                        .overlay(
                            Text(amount == "0" ? "-" : "\(amount)")
                                .foregroundStyle(Color.green)
                        )
                }
                
            }
        }
    }
    var dosages: some View {
        HStack{
            ForEach(dosageTemplate){ dosage in
                let name:String = dosage.name ?? ""
                if let dosage:Dosage = stopData.dosages.first(where: {$0.templateId == dosage.dosageTemplateId}) {
                    Text("\(name)")
                        .font(.footnote)
                        .frame(width: 50)
                        .foregroundColor(Color.clear)
                        .overlay(
                            Text(dosage.amount == "0" ? "-":"\(dosage.amount ?? "0")")
                        )
                } else {
                    Text("\(name)")
                        .font(.footnote)
                        .frame(width: 50)
                        .foregroundColor(Color.clear)
                        .overlay(
                           Text("-")
                        )
                }
            }
        }
    }
}

struct StopDataRowTitle: View {
    let readingTemplates:[SavedReadingsTemplate]
    let dosageTemplates:[SavedDosageTemplate]
    
    var body: some View {
        HStack{
            Text("00-00-00")
                .foregroundColor(Color.clear)
                .overlay(
                    Text("Date")
                        .font(.footnote)
                )
            readings
            dosages
            Text("S0000000")
                .foregroundColor(Color.clear)
                .overlay(Text("Stop Id"))
            Spacer()
        }
    }
}
extension StopDataRowTitle {
    var readings: some View {
        HStack{
            ForEach(readingTemplates){ template in
                Text("\(template.name)")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.footnote)
            }
        }
    }
    var dosages: some View {
        HStack{
            ForEach(dosageTemplates){ template in
                Text("\(template.name ?? "")")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.footnote)
            }
        }
    }
}
