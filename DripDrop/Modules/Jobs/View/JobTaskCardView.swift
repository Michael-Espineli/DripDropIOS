//
//  JobTaskCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//

import SwiftUI
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class JobTaskCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var serviceStop : ServiceStop? = nil
    @Published private(set) var laborContract : LaborContract? = nil
    @Published private(set) var isLoading : Bool = false
    
    @Published private(set) var bow : BodyOfWater? = nil
    @Published private(set) var equipment : Equipment? = nil
    @Published private(set) var shoppingListItem : ShoppingListItem? = nil
    @Published private(set) var dataBaseItem : DataBaseItem? = nil

    func onLoad(companyId:String,jobTask:JobTask) async throws {
        print("")
        print("-------------- on Load JobTaskCardView - [JobTaskCardViewModel]---------------------")
        switch jobTask.workerType {
        case .contractor:
            print("contractor")
            print("jobTask.laborContractId \(jobTask.laborContractId)")
            self.laborContract = try await dataService.getLaborContract(laborContractId: jobTask.laborContractId)
        case .employee:
            print("Employee")
            print("jobTask.serviceStopId.id \(jobTask.serviceStopId.id)")
            self.serviceStop = try await dataService.getServiceStopById(serviceStopId: jobTask.serviceStopId.id, companyId: companyId)
        case .notAssigned:
            print("notAssigned")
        }
        print(jobTask.type)
        switch jobTask.type {
        case .basic, .clean, .inspection:
            print("")
        case .cleanFilter:
            self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: jobTask.equipmentId)
        case .emptyWater:
            self.bow = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: jobTask.bodyOfWaterId)
        case .fillWater:
            self.bow = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: jobTask.bodyOfWaterId)
        case .install:
            self.dataBaseItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: jobTask.dataBaseItemId)
        case .remove:
            self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: jobTask.equipmentId)
        case .replace:
            self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: jobTask.equipmentId)
            self.dataBaseItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: jobTask.dataBaseItemId)
        case .maintenance:
                self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: jobTask.equipmentId)
        case .repair:
            self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: jobTask.equipmentId)
        }
    }
}
struct JobTaskCardView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : JobTaskCardViewModel
    @State var jobId : String
    @State var jobTask : JobTask
    
    init(dataService:any ProductionDataServiceProtocol,jobId : String,jobTask:JobTask){
        _VM = StateObject(wrappedValue: JobTaskCardViewModel(dataService: dataService))
        _jobId = State(wrappedValue: jobId)
        _jobTask = State(wrappedValue: jobTask)
    }
    var body: some View {
        ZStack{
            switch jobTask.status{
            case .accepted, .offered, .scheduled, .finished, .inProgress:
                info
                    .modifier(YellowButtonModifier())
                    .opacity(0.6)
                    .disabled(true)
            case .unassigned, .rejected, .draft:
                info
                    .modifier(ListButtonModifier())
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, jobTask: jobTask)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    JobTaskCardView()
//}
extension JobTaskCardView {
    var info: some View {
        VStack{
            HStack{
                Text(jobTask.name)
                Spacer()
                Text(jobTask.status.rawValue)
                    .modifier(BlueButtonModifier())
                    .lineLimit(1)
                    .font(.footnote)
            }
            HStack{
                switch jobTask.workerType {
                case .contractor:
                    Text(jobTask.laborContractId)
                    Button(action: {
                    }, label: {
                        HStack{
                            Text("Labor Contract Details")
                            Spacer()
                        }
                    })
                case .employee:
                    if let serviceStop = VM.serviceStop {
                        NavigationLink(value: Route.serviceStop(serviceStop: serviceStop, dataService: dataService), label: {
                            HStack{
                                Text("Service Stop Details")
                                Spacer()
                            }
                        })
                    } else {
                        HStack{
                            Text("Service Stop Details")
                            Spacer()
                        }
                    }
                case .notAssigned:
                    Text("Not Assigned")
                }
                Spacer()
                Text(jobTask.type.rawValue)
                    .modifier(YellowButtonModifier())
            }
            HStack{
                Text("\(Double(jobTask.contractedRate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")

                Spacer()
                Text(displayNumberAsMinAndHour(seconds: jobTask.estimatedTime))
            }
            Divider()
            switch jobTask.type {
            case .basic, .clean:
                Text("")
            case .cleanFilter:
                if let equipment = VM.equipment {
                    Text("\(equipment.name) - \(equipment.make):\(equipment.make)")
                }
            case .emptyWater:
                if let bow = VM.bow {
                    Text("\(bow.name)")
                }
            case .fillWater:
                if let bow = VM.bow {
                    Text("\(bow.name)")
                }
            case .inspection:
                Text("")
            case .install:
                if let dataBaseItem = VM.dataBaseItem {
                    Text("\(dataBaseItem.name)")
                }
            case .remove:
                if let equipment = VM.equipment {
                    Text("\(equipment.name) - \(equipment.make):\(equipment.make)")
                }
            case .replace:
                if let equipment = VM.equipment {
                    Text("\(equipment.name) - \(equipment.make):\(equipment.make)")
                }
                if let dataBaseItem = VM.dataBaseItem {
                    Text("\(dataBaseItem.name)")
                }
            case .maintenance:
                if let equipment = VM.equipment {
                    Text("\(equipment.name) - \(equipment.make):\(equipment.make)")
                }
            case .repair:
                if let equipment = VM.equipment {
                    Text("\(equipment.name) - \(equipment.make):\(equipment.make)")
                }
                
            }
        }
    }
}
