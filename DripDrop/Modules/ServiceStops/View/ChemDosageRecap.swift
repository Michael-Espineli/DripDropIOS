//
//  ChemDosageRecap.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/1/24.
//



import SwiftUI

struct ChemDosageRecap: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var stopDataVM : StopDataViewModel
    
    @EnvironmentObject var VM : ServiceStopDetailViewModel

    @State var templates: [SavedDosageTemplate]
    @State var BOW: BodyOfWater
    init(dataService:any ProductionDataServiceProtocol,templates:[SavedDosageTemplate],BOW:BodyOfWater) {
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
        _templates = State(wrappedValue: templates)
        _BOW = State(wrappedValue: BOW)
    }


    var body: some View {
        VStack{
                ForEach(templates) { template in
                    HStack{
                        if let stopData = VM.currentStopData[BOW], let reading = stopData.dosages.first(where: {$0.templateId == template.dosageTemplateId}) {
                            Text("\(reading.amount ?? "-")")
                            
                        } else {
                            Text(" - ")
                        }
                    }
                }
            
        }
//        .task{
//            do {
//                if let company = masterDataManager.selectedCompany, let stop = masterDataManager.selectedServiceStops{
//                    try await stopDataVM.getStopDataByServiceStopIdAndBodyOfWater(companyId: company.id, serviceStopId: stop.id,bodyOfWaterId: BOW.id)
//                        print("Successfully Got Reading And Dosage Templates")
//                }
//            } catch {
//                print("Throw Error")
//            }
//        }

    }
}

struct ChemDosageRecap_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        ChemDosageRecap(dataService: dataService,  templates: [], BOW: BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date()))
    }
}

