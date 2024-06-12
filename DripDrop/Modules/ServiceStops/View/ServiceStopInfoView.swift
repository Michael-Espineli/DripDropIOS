//
//  ServiceStopInfoView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/30/23.
//

import SwiftUI
struct ServiceStopInfoView: View{
    @State var serviceStop: ServiceStop
    @EnvironmentObject var navigationManager : NavigationStateManager

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var customerVM : CustomerViewModel
    @StateObject var jobVM : JobViewModel

    init(serviceStop:ServiceStop,dataService:any ProductionDataServiceProtocol) {
        _serviceStop = State(wrappedValue: serviceStop )
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))

    }
    @State var showSheet:Bool = false
    var body: some View{
        ZStack{
            ScrollView{
                VStack(spacing: 0){

                    VStack(alignment:.leading){
                        Text("Service Stop Id: \(serviceStop.id)")
                            .textSelection(.enabled)
                        Text(fullDateAndDay(date:serviceStop.serviceDate))

                            customerPageLink
                            
                            AddressNavigationCardView(address: serviceStop.address)
                        jobPageLink
                            HStack{
                                Text("Type: ")
                                Text(serviceStop.type)
                            }
                            Spacer()
                           
                        
                        HStack{
                            Text("Tech: ")
                            Text("\(serviceStop.tech ?? "0")")
                        }
                      
                        HStack{
                            HStack{
                                Text("Rate: ")
                                
                                Text("$ " + String(serviceStop.rate ?? 0))
                            }
                            HStack{
                                Text("Duration: ")
                                Text(String(serviceStop.duration))
                                
                            }
                        }
                        VStack{
                            HStack{
                                Text("Check List: ")
                                Button(action: {
                                    
                                }, label: {
                                    Image(systemName: "plus")
                                })
                            }
                            ForEach(serviceStop.checkList,id:\.self){ item in
                                Text(item.description)
                            }
                        }
                    }
                    VStack{
                      
                        
                        HStack{
                            Text("Description: ")
                            Text(serviceStop.description)
                        }
                        Button(action: {
                            showSheet.toggle()
                        }, label: {
                            Text("Show me the money")
                        })
                        .sheet(isPresented: $showSheet, content: {
                            Text("I am the Money")
                        })
                    }
                    
                }
            }
        }
        .textSelection(.enabled)
        .task{
            if let company = masterDataManager.selectedCompany {
                //Check to see if job id is empty, Other wise do not try to find.
                if serviceStop.jobId != "" {
                    do {
                        
                        try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: serviceStop.jobId)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}



extension ServiceStopInfoView {
    var jobPageLink: some View {
        ZStack{
            HStack{
                if UIDevice.isIPhone {
                    if let job = jobVM.workOrder {
                        NavigationLink(value: Route.job(job: job, dataService: dataService), label: {
                            Text("\(serviceStop.jobId)")
                                .padding(5)
                                .foregroundColor(Color.basicFontText)
                                .background(Color.poolBlue)
                                .cornerRadius(5)
                                .padding(5)
                            
                        })
                    } else {
                        Text("\(serviceStop.jobId)")
                    }
                } else {
                    Button(action: {
                            Task{
                                if let company = masterDataManager.selectedCompany {
                                        masterDataManager.selectedCustomer = customerVM.customer
                                        masterDataManager.selectedCategory = .customers
                                        
                                        masterDataManager.selectedID = serviceStop.customerId
                                        
                                    
                                }
                            }
                        
                    }, label: {
                            Text("\(serviceStop.customerName)")
                                .padding(5)
                                .foregroundColor(Color.basicFontText)
                                .background(Color.poolBlue)
                                .cornerRadius(5)
                                .padding(5)
                        
                    })
                }
 
                
                Spacer()
            }
            .padding(10)
        }
    }
    var customerPageLink: some View {
        ZStack{
            HStack{
                
                Button(action: {
                        Task{
                            if let company = masterDataManager.selectedCompany {
                                try await customerVM.getCustomer(companyId: company.id, customerId: serviceStop.customerId)
                                
                                if UIDevice.isIPhone {
                                    masterDataManager.selectedID = serviceStop.customerId
                                    
                                    masterDataManager.selectedCustomer = customerVM.customer
                                    if let customer = customerVM.customer {
                                        //DEVELOPER FIX THIS
                                        navigationManager.routes.append(Route.customer(customer: customer, dataService:dataService))
                                    }
                                } else {
                                    masterDataManager.selectedCustomer = customerVM.customer
                                    masterDataManager.selectedCategory = .customers
                                    
                                    masterDataManager.selectedID = serviceStop.customerId
                                    
                                }
                            }
                        }
                    
                }, label: {
                        Text("\(serviceStop.customerName)")
                            .padding(5)
                            .foregroundColor(Color.basicFontText)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                            .padding(5)
                    
                })
                
                Spacer()
            }
            .padding(10)
        }
    }
}
