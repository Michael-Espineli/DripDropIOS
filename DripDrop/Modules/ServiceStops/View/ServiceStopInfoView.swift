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
    init(dataService:any ProductionDataServiceProtocol,serviceStopId:String) {
        _VM = StateObject(wrappedValue: ServiceStopInfoViewModel(dataService: dataService))
        _serviceStopId = State(wrappedValue: serviceStopId )
    }
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel

    @StateObject var VM : ServiceStopInfoViewModel
    
    @State var serviceStopId: String
    @State var taskList : [ServiceStopTask] = []
    @State var showSheet:Bool = false
    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack(spacing: 8){ // Spacing was 8
                    siteInfo
                    Divider()
                    if let serviceStop {
                        ServiceLocationContactInfo(dataService: dataService, locationId: serviceStop.serviceLocationId)
                    }
                    Divider()
                    stopInfo
                }
            }
            .padding(.horizontal,8)
        }
        .textSelection(.enabled)
        .task{
            if let company = masterDataManager.currentCompany, let serviceStop {
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
            if let serviceStop {
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
                        if serviceStop.operationStatus != .finished {
                            Button(action: {
                                vm.startServiceStop(companyId: masterDataManager.currentCompany?.id, serviceStopId: serviceStop.id)
                            }, label: {
                                Text("Restart Time")
                                    .modifier(BlueButtonModifier())
                            })
                            
                        }
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
                        Text("Not Finished Yet")
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
                }
                Text(serviceStop.description)
                    .frame(maxWidth: .infinity)
                    .modifier(PlainTextFieldModifier())
            }
        }
    }
    var jobPageLink: some View {
        HStack{
            if let serviceStop {
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
        
    }
    var customerPageLink: some View {
        HStack{
            if let serviceStop {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("10") {
                        CustomerPageLink(
                            serviceStop: serviceStop,
                            job: nil
                        )
                        
                    } else {
                        Text("\(serviceStop.customerName)")
                            .modifier(ListButtonModifier())
                    }
                }
                Spacer()
            }
        }
    }
    
    var addressNavigationLink : some View {
        ZStack{
            if let serviceStop {
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
}
@MainActor
final class ServiceLocationContactInfoViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    let locationId:String
    init(dataService:any ProductionDataServiceProtocol, locationId:String){
        self.dataService = dataService
        self.locationId = locationId
    }
    @Published private(set) var serviceLocation: ServiceLocation?
    func onLoad(companyId:String?){
        guard let companyId else {return}
        Task{
            do {
                self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: locationId)
            } catch {
                print("[ServiceLocationContactInfoViewModel][onLoad] Error \(error)")
            }
        }
    }
}
struct ServiceLocationContactInfo: View{
    @EnvironmentObject var navigationManager : NavigationStateManager
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var VM : ServiceLocationContactInfoViewModel
    
    init(dataService:any ProductionDataServiceProtocol, locationId:String) {
        _VM = StateObject(wrappedValue: ServiceLocationContactInfoViewModel(dataService: dataService, locationId: locationId))
        _locationId = State(wrappedValue: locationId )
    }
    @State var locationId: String
    @State var taskList : [ServiceStopTask] = []
    @State var showSheet:Bool = false
    var body: some View{
        ZStack{
            if let location = VM.serviceLocation {
                ContactInfo(contact: location.mainContact)
            }
        }
        .onAppear(perform: {
            VM.onLoad(companyId: masterDataManager.currentCompany?.id)
        })
    }
}
