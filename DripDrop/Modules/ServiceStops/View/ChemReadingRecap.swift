//
//  ChemReadingRecap.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/1/24.
//

import SwiftUI

struct ChemReadingRecap: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var stopDataVM : StopDataViewModel
    
    @EnvironmentObject var VM : ServiceStopDetailViewModel

    @State var templates: [SavedReadingsTemplate]
    @State var BOW: BodyOfWater
    
    init(dataService:any ProductionDataServiceProtocol,templates:[SavedReadingsTemplate],BOW:BodyOfWater) {
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
        _templates = State(wrappedValue: templates)
        _BOW = State(wrappedValue: BOW)
    }
    
    var body: some View {
        VStack{
                ForEach(templates) { template in
                    HStack{
                        if let stopData = VM.currentStopData[BOW], let reading = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId})  {
                            if Double(reading.amount ?? "0") ?? 1_000 > (template.highWarning ?? 1_000) {
                                Text("\(reading.amount ?? "0")")
                                    .foregroundStyle(Color.poolRed)
                            } else  if Double(reading.amount ?? "0") ?? 0 < (template.lowWarning ?? 0) {
                                    Text("\(reading.amount ?? "0")")
                                    .foregroundStyle(Color.poolRed)
                                } else {
                                    Text("\(reading.amount ?? "0")")
                                }
                        } else {
                            Text(" - ")
                          
                        }
//                        if let stopData = VM.currentServiceStopData.first(where: {$0.bodyOfWaterId == BOW.id}), let reading = stopData.readings.first(where: {$0.templateId == template.id}) {
//                            if Double(reading.amount ?? "0") ?? 1_000 > (template.highWarning ?? 1_000) {
//                                Text("\(reading.amount ?? "0")")
//                                    .foregroundStyle(Color.poolRed)
//                            } else  if Double(reading.amount ?? "0") ?? 0 < (template.lowWarning ?? 0) {
//                                    Text("\(reading.amount ?? "0")")
//                                    .foregroundStyle(Color.poolRed)
//                                } else {
//                                    Text("\(reading.amount ?? "0")")
//                                }
//                            
//                            
//                        } else {
//                            Text(" - ")
//                          
//                        }
                    }
                }
            
        }
//        .task{
//            do {
//                if let company = masterDataManager.selectedCompany, let stop = masterDataManager.selectedServiceStops{
//                    try await stopDataVM.getStopDataByServiceStopIdAndBodyOfWater(companyId: company.id, serviceStopId: stop.id,bodyOfWaterId: BOW.id)
////                        print("Successfully Got Reading And Dosage Templates")
//               
//                }
//            } catch {
//                print("Throw Error")
//            }
//        }

    }
}

struct ChemReadingRecap_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ChemReadingRecap(dataService: dataService, templates: [], BOW: BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date()))
    }
}
