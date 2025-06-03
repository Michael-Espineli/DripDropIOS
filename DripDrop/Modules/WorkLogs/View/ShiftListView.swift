//
//  ShiftListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class ShiftListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var previousShifts : [WorkShift] = []
    @Published private(set) var nextShifts : [WorkShift] = []
    func onLoad(companyId:String, userId:String) async throws {
        self.previousShifts = try await dataService.getNextShiftByUserId(companyId: companyId, userId: userId, count: 1)
        self.nextShifts = try await dataService.getPreviousShiftByUserId(companyId: companyId, userId: userId, count: 3)
        
    }
}

struct ShiftListView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : ShiftListViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: ShiftListViewModel(dataService: dataService))
    }
    //Mock Data
    @State var previousShift : WorkShift = WorkShift(
        date: Date(),
        techId: UUID().uuidString,
        techName: "John Doe",
        isCurrent: false,
        estimatedTime: 100,
        estimatedMiles: 15
    )
    //Next Shift
    //Mock Data
    @State var nextShift : WorkShift = WorkShift(
        date: Date(),
        techId: UUID().uuidString,
        techName: "John Doe",
        isCurrent: false,
        estimatedTime: 1000,
        estimatedMiles: 30
    )
    var body: some View {
        ScrollView{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    Text("Next Shift - ")
                    Spacer()
                }
                ForEach(VM.nextShifts) { shift in
                    ShiftCardView(dataService: dataService, workShift: shift)
                }
                HStack{
                    Text("Previous Shift - ")
                    Spacer()
                }
                ForEach(VM.previousShifts) { shift in
                    ShiftCardView(dataService: dataService, workShift: shift)
                }
            }
            .padding(8)
        }
    }
}

//#Preview {
//    ShiftListView()
//}
