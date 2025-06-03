//
//  JobNavigationLink.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/5/24.
//

import SwiftUI
@MainActor
final class JobNavigationLinkViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var workOrder : Job? = nil
    @Published private(set) var otherCompany : Company? = nil

    func onLoad(companyId:String,jobId:String) async throws {
        self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
//        if let serviceStop {
//            print(serviceStop)
//            if serviceStop.otherCompany  {
//                if let otherCompanyId = serviceStop.mainCompanyId {
//                    self.otherCompany = try await dataService.getCompany(companyId: otherCompanyId)
//                    customer = try await dataService.getCustomerById(companyId: otherCompanyId, customerId: serviceStop.customerId)
//                }
//            } else {
//                if let currentCompany = masterDataManager.currentCompany {
//                    customer = try await dataService.getCustomerById(companyId: currentCompany.id, customerId: serviceStop.customerId)
//                }
//            }
//        } else if let job {
//            print(job)
//            if job.otherCompany  {
//                if let otherCompanyId = job.senderId {
//                    otherCompany = try await dataService.getCompany(companyId: otherCompanyId)
//                    customer = try await dataService.getCustomerById(companyId: otherCompanyId, customerId: job.customerId)
//                }
//            } else {
//                if let currentCompany = masterDataManager.currentCompany {
//                    customer = try await dataService.getCustomerById(companyId: currentCompany.id, customerId: job.customerId)
//                }
//            }
//        }
    }
}
struct JobNavigationLink: View {
    @EnvironmentObject var dataService : ProductionDataService
    init(dataService: any ProductionDataServiceProtocol, companyId:String,jobId:String) {
        _VM = StateObject(wrappedValue: JobNavigationLinkViewModel(dataService: dataService))
        _companyId = State(wrappedValue: companyId)
        _jobId = State(wrappedValue: jobId)
        
    }
    @StateObject var VM : JobNavigationLinkViewModel
    @State var companyId:String
    @State var jobId:String
    var body: some View {
        ZStack{
            if let job = VM.workOrder {
                NavigationLink(value: Route.job(job: job, dataService: dataService), label: {
                    HStack{
                        Text("\(jobId) - ")
                        Text("Created: \(fullDate(date:job.dateCreated))")
                        Spacer()
                        Text("Stops: \(job.serviceStopIds.count)")
                    }
                    .foregroundColor(Color.basicFontText)
                    .padding(8)
                    .background(Color.poolBlue)
                    .cornerRadius(3)
                })
            }
        }
        
        .task {
            do {
                try await VM.onLoad(companyId: companyId, jobId: jobId)
            } catch {
                print(error)
            }
        }
    }

}

#Preview {
    JobNavigationLink(dataService: MockDataService(), companyId: "", jobId: "")
}
