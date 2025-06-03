//
//  PerformaceHistoryViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import Foundation
enum PerformaceHistoryType:String, Codable, CaseIterable {
    case kudo = "Kudo"
    case complaint = "Complaint"
}
struct PerformaceHistory:Codable,Identifiable,Hashable{ // the Id of UserAccess Will Always be the same as the companyId
    
    var id :String
    var userId : String
    var userName : String
    var date: Date
    var description: String
    var photoUrls: [DripDropStoredImage]
    var performaceHistoryType: PerformaceHistoryType
}
@MainActor
final class PerformaceHistoryViewModel:ObservableObject{
    @Published var performaceHistoryList:[PerformaceHistory] = []
    let dataService:any ProductionDataServiceProtocol
    
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    func createNewPerformanceReview(companyId:String,companyUserId:String,performaceHistory:PerformaceHistory) async throws {
        
    }

    func getPerformaceReivewByUserId(companyId:String,companyUserId:String) async throws {
        self.performaceHistoryList = MockDataService.mockPerformaceHistory
    }
}
