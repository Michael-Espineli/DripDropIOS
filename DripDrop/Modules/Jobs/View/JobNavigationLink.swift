//
//  JobNavigationLink.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/5/24.
//

import SwiftUI

struct JobNavigationLink: View {
    @EnvironmentObject var dataService : ProductionDataService
    init(dataService: any ProductionDataServiceProtocol, companyId:String,jobId:String) {
        _VM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _companyId = State(wrappedValue: companyId)
        _jobId = State(wrappedValue: jobId)
        
    }
    @StateObject var VM : JobViewModel
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
                try await VM.getSingleWorkOrder(companyId: companyId, WorkOrderId: jobId)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    JobNavigationLink(dataService: MockDataService(), companyId: "", jobId: "")
}
