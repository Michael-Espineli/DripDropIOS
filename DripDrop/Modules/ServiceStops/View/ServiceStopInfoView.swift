    //
    //  ServiceStopInfoView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 12/30/23.
    //

import SwiftUI
@MainActor
final class ServiceStopInfoViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var workOrder: Job? = nil
    @Published private(set) var customer: Customer? = nil

    func onLoad(companyId: String,WorkOrderId:String) async throws{
        self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: WorkOrderId)
    }
    func getCustomer(companyId: String,customerId:String) async throws{
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
        
    }
}
struct ServiceStopInfoView: View{
    @State var serviceStop: ServiceStop
    @EnvironmentObject var navigationManager : NavigationStateManager
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var VM : ServiceStopInfoViewModel
    
    init(serviceStop:ServiceStop,dataService:any ProductionDataServiceProtocol) {
        _serviceStop = State(wrappedValue: serviceStop )
        _VM = StateObject(wrappedValue: ServiceStopInfoViewModel(dataService: dataService))
    }
    @State var taskList : [ServiceStopTask] = []
    @State var showSheet:Bool = false
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack(spacing: 8){ // Spacing was 8
                    siteInfo
                    Rectangle()
                        .frame(height: 1)
                    stopInfo
                }
            }
            .padding(.horizontal,8)
        }
        .textSelection(.enabled)
        .task{
            if let company = masterDataManager.currentCompany {
                    //Check to see if job id is empty, Other wise do not try to find.
                if serviceStop.jobId != "" {
                    do {
                        
                        try await VM.onLoad(companyId: company.id, WorkOrderId: serviceStop.jobId)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}



extension ServiceStopInfoView {
    var siteInfo: some View {
        VStack(alignment:.leading){
            HStack{
                Spacer()
                Text("Site Information")
                    .font(.title3)
                Spacer()
            }
            customerPageLink
            addressNavigationLink
        }
    }
    var stopInfo: some View {
 
        VStack(alignment:.leading){
            HStack{
                Spacer()
                Text("Service Stop Information")
                    .font(.title3)
                Spacer()
            }
            
            Text(fullDateAndDay(date:serviceStop.serviceDate))
            HStack{
                Text("Service Stop Id: ")
                    .bold()
                Spacer()
                Text(serviceStop.internalId)
                    .textSelection(.enabled)
                    .modifier(BlueButtonModifier())
            }
            jobPageLink
            
            HStack{
                Text("Tech: ")
                    .bold()
                Spacer()
                Text("\(serviceStop.tech)")
            }
            HStack{
                Text("Type: ")
                    .bold()
                Spacer()
                Text(serviceStop.type)
            }
            HStack{
                Text("Estimated Duration: ")
                    .bold()
                Spacer()
                Text(displayMinAsMinAndHour(min: serviceStop.estimatedDuration))
            }
            HStack{
                Text("Start Time: ")
                    .bold()
                Spacer()
                if let startTime = serviceStop.startTime {
                    Text(shortDateAndTime(date:startTime))

                } else {
                    Text("Not Started Yet")
                }
                
            }
            HStack{
                Text("End Time: ")
                    .bold()
                Spacer()
                if let endTime = serviceStop.endTime {
                    Text(shortDateAndTime(date:endTime))

                } else {
                    Text("Not Started Yet")
                }
                
            }
            HStack{
                Text("Duration: ")
                    .bold()
                Spacer()
                Text(displayMinAsMinAndHour(min: serviceStop.duration))
                
            }
            HStack{
                Text("Description: ")
                    .bold()
                Spacer()
                Text(serviceStop.description)
            }

            Button(action: {
                showSheet.toggle()
            }, label: {
                Text("Show me the money")
                    .modifier(BlueButtonModifier())
            })
            .sheet(isPresented: $showSheet, content: {
                Text("I am the Money")
            })
        }
        
    }
    var jobPageLink: some View {
        HStack{
            if UIDevice.isIPhone {
                if let job = VM.workOrder {
                    Text("Job Id: ")
                        .bold()
                    Spacer()
                    NavigationLink(value: Route.job(job: job, dataService: dataService), label: {
                        Text("\(job.internalId)")
                        .padding(5)
                        .foregroundColor(Color.basicFontText)
                        .background(Color.poolBlue)
                        .cornerRadius(5)
                        
                        })
                    } else {
                        Text("\(serviceStop.jobId)")
                    }
                } else {
                    Button(action: {
                        Task{
                            if let company = masterDataManager.currentCompany {
                                masterDataManager.selectedCategory = .customers
                                masterDataManager.selectedID = serviceStop.customerId
                            }
                        }
                    }, label: {
                        Text("\(serviceStop.customerName)")
                            .padding(5)
                    })
                }
        }
        
    }
    var customerPageLink: some View {
        ZStack{
            HStack{
                if UIDevice.isIPhone {
                    CustomerPageLink(
                        serviceStop: serviceStop,
                        job: nil
                    )
                } else {
                    Button(action: {
                        Task{
                            if let company = masterDataManager.currentCompany {
                                try await VM.getCustomer(companyId: company.id, customerId: serviceStop.customerId)
                          
                                    masterDataManager.selectedCustomer = VM.customer
                                    masterDataManager.selectedCategory = .customers
                                    masterDataManager.selectedID = serviceStop.customerId
                                
                            }
                        }
                        
                    }, label: {
                        Text("\(serviceStop.customerName)")
                            .modifier(BlueButtonModifier())
                    })
                }
                Spacer()
            }
        }
    }
    
    var addressNavigationLink : some View {
        ZStack{
            VStack(alignment: .leading, spacing: 2){
                Button(action: {
                    
                    let address = "\(serviceStop.address.streetAddress) \(serviceStop.address.city) \(serviceStop.address.state) \(serviceStop.address.zip)"
                    
                    let urlText = address.replacingOccurrences(of: " ", with: "?")
                    
                    let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
                }, label: {
                    VStack{
                        Text("\(serviceStop.address.streetAddress)")
                        HStack{
                            Text("\(serviceStop.address.city)")
                            Text("\(serviceStop.address.state)")
                            Text("\(serviceStop.address.zip)")
                        }
                    }
                    .modifier(BlueButtonModifier())
                })
            }
        }
    }
}
