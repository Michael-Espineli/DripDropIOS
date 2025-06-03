//
//  CustomerPageLink.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/24/25.
//

import SwiftUI

struct CustomerPageLink: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    let serviceStop: ServiceStop?
    let job: Job?
    @State var customer: Customer? = nil
    @State var otherCompany: Company? = nil

    var body: some View {

        VStack{
            if let customer {
                NavigationLink(value: Route.customer(customer: customer, dataService: dataService), label: {
                    Text("\(customer.firstName) \(customer.lastName)")
                        .modifier(BlueButtonModifier())
                })
            }
            if let otherCompany {
                Text(otherCompany.name)
                    .font(.footnote)
            }
        }
        
        .task{
            do {
                try await onLoad(serviceStop: serviceStop, job: job)
            } catch {
                print(error)
            }
        }
    }
    func onLoad(serviceStop:ServiceStop?,job:Job?) async throws {
        if let serviceStop {
            print(serviceStop)
            if serviceStop.otherCompany  {
                if let otherCompanyId = serviceStop.mainCompanyId {
                    otherCompany = try await dataService.getCompany(companyId: otherCompanyId)
                    customer = try await dataService.getCustomerById(companyId: otherCompanyId, customerId: serviceStop.customerId)
                }
            } else {
                if let currentCompany = masterDataManager.currentCompany {
                    customer = try await dataService.getCustomerById(companyId: currentCompany.id, customerId: serviceStop.customerId)
                }
            }
        } else if let job {
            print(job)
            if job.otherCompany  {
                if let otherCompanyId = job.senderId {
                    otherCompany = try await dataService.getCompany(companyId: otherCompanyId)
                    customer = try await dataService.getCustomerById(companyId: otherCompanyId, customerId: job.customerId)
                }
            } else {
                if let currentCompany = masterDataManager.currentCompany {
                    customer = try await dataService.getCustomerById(companyId: currentCompany.id, customerId: job.customerId)
                }
            }
        }
    }
}

#Preview {
    CustomerPageLink(serviceStop: nil, job: nil)
}
