//
//  JobIdCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/27/25.
//


import SwiftUI

@MainActor
final class JobIdCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private (set) var job: Job? = nil
    func onLoad(companyId:String,jobId:String) async throws {
        self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
    }
}
struct JobIdCardView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : JobIdCardViewModel
    
    init(dataService:any ProductionDataServiceProtocol,jobId:String){
        _VM = StateObject(wrappedValue: JobIdCardViewModel(dataService: dataService))
        _jobId = State(wrappedValue: jobId)
    }
    
    @State var jobId:String
    
    var body: some View {
        VStack(alignment: .leading){
            if let job = VM.job {
                HStack{
                    Text("\(job.internalId)")
                    Spacer()
                    Text("\(job.customerName)")
                        .lineLimit(1)
                }
            } else {
                Text("\(jobId)")
            }
        }
        .font(.headline)
        .padding(.horizontal,8)
        .padding(.vertical,4)
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, jobId: jobId)
                } catch {
                    print(error)
                }
            }
        }
    }
}
