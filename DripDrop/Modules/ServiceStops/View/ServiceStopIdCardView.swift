//
//  ServiceStopIdCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/7/24.
//


import SwiftUI
@MainActor
final class ServiceStopIdCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var serviceStop : ServiceStop? = nil
    func onLoad(companyId:String,serviceStopId:String) {
        Task{
            do {
                self.serviceStop = try await dataService.getServiceStopById(serviceStopId: serviceStopId, companyId: companyId)
            } catch {
                print(error)
            }
        }
    }
}
struct ServiceStopIdCardView: View{
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : ServiceStopIdCardViewModel

    @State var serviceStopId: String
    
    init(dataService:any ProductionDataServiceProtocol,serviceStopId: String) {
        _serviceStopId = State(wrappedValue: serviceStopId)
        _VM = StateObject(wrappedValue: ServiceStopIdCardViewModel(dataService: dataService))
    }
    
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            if let serviceStop = VM.serviceStop {
                VStack(spacing: 0){
                    HStack{
                        Text(serviceStop.customerName )
                    }
                    HStack{
                        Text(fullDateAndDay(date:serviceStop.serviceDate))
                            .font(.footnote)
                        Spacer()
                        Text("Tech: \(serviceStop.tech)")
                            .font(.footnote)
                    }
                    HStack{
                        Spacer()
                        Text(serviceStop.operationStatus.rawValue)
                    }
                }
                .modifier(ListButtonModifier())
            }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id, serviceStopId: serviceStopId)
            }
        }
    }
}

