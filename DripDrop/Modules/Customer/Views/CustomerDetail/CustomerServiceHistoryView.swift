//
//  CustomerServiceHistoryView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/10/23.
//
///There are a whole Bunch of duplicate functions in here if I call one it calls them all, so fix that
import SwiftUI

struct CustomerServiceHistoryView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager


    @StateObject var customerVM : CustomerViewModel
    @StateObject var jobVM : JobViewModel
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var stopDataVM : StopDataViewModel
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel

    @State var customer:Customer
    
    init(dataService:any ProductionDataServiceProtocol,customer:Customer) {
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
        
    }
    
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    
    @State var edit:Bool = false
    @State var bodyOfWaterId:String = "1"
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    @State var serviceLocationList:[ServiceLocation] = []
    @State var serviceLocation:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false
    )
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date())
    
    @State var viewList:[String] = ["Chem History","Service History","Equipment History"]
    @State var stringView:String = "Chem History"
    var body: some View {
        VStack{
            ScrollView(showsIndicators: false){
                HStack{
                    Button(action: {
                        edit.toggle()
                    }, label: {
                        Text("Edit")
                        
                    })
                    Spacer()
                }
                .padding()
                locationAndBodyOfWaterPicker
                switch stringView{
                case "Chem History":
                    chemHistory
                case "Service History":
                    serviceHistory
                case "Equipment History":
                    equipmentHistory
                default:
                    chemHistory
                }
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany{
                    if let cus = masterDataManager.selectedCustomer {
                        customer = cus
                    } else {
                        masterDataManager.selectedCustomer = customer
                    }
                 
                        try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
                        serviceLocationList = serviceLocationVM.serviceLocations
                        if serviceLocationList.count != 0{
                            serviceLocation = serviceLocationList.first!
                            masterDataManager.selectedServiceLocation = serviceLocationList.first
                        }
                    
          
//                        try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: serviceLocation)
//                        bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
//                        if bodyOfWaterList.count != 0{
//                            bodyOfWater = bodyOfWaterList.first!
//                            masterDataManager.selectedBodyOfWater = bodyOfWaterList.first
//
//                        }
//
//                    try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: bodyOfWater.id)
//                    try await serviceStopVM.getAllServiceStopsByCustomer(companyId: company.id, customerId: customer.id, startDate: startDate, endDate: endDate)

                    try await settingsVM.getDosageTemplates(companyId: company.id)
                    try await settingsVM.getReadingTemplates(companyId: company.id)
                    
                }
            } catch {
                print("Customer History Error On Appear")
            }
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { selectedCustomer in
            Task{
                do {
                    if let company = masterDataManager.currentCompany{
                        if let cus = masterDataManager.selectedCustomer {
                            customer = cus
                        } else {
                            masterDataManager.selectedCustomer = customer
                        }
           
                            try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
                            serviceLocationList = serviceLocationVM.serviceLocations
                            if serviceLocationList.count != 0{
                                serviceLocation = serviceLocationList.first!
                                masterDataManager.selectedServiceLocation = serviceLocationList.first

                            }
//
//
//                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: serviceLocation)
//                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
//                            if bodyOfWaterList.count != 0{
//                                bodyOfWater = bodyOfWaterList.first!
//                                masterDataManager.selectedBodyOfWater = bodyOfWaterList.first
//
//                            }
//
//                        try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: bodyOfWater.id)
//                        try await serviceStopVM.getAllServiceStopsByCustomer(companyId: company.id, customerId: customer.id, startDate: startDate, endDate: endDate)

                    }
                } catch {
                    print("Customer History Error on Change of Customer")
                }
            }
        })
        .onChange(of: serviceLocation, perform: { location in
            Task{
                do {
                    if let company = masterDataManager.currentCompany{
               
                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: location)
                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                            if bodyOfWaterList.count != 0{
                                bodyOfWater = bodyOfWaterList.first!
                                masterDataManager.selectedBodyOfWater = bodyOfWaterList.first
                            }
//
//                        try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: bodyOfWater.id)
//                        try await serviceStopVM.getAllServiceStopsByCustomer(companyId: company.id, customerId: customer.id, startDate: startDate, endDate: endDate)

                    }
                } catch {
                    print("Change Of service Location Error")
                }
            }
        })
        .onChange(of: bodyOfWater, perform: { selectedBodyOfWater in
            Task{
                if let company = masterDataManager.currentCompany{

                do {
    
                                masterDataManager.selectedBodyOfWater = selectedBodyOfWater
                     
                        try await stopDataVM.getStopDataByBodyOfWater(companyId: company.id, bodyOfWaterId: selectedBodyOfWater.id)
                        

                } catch {
                    print("Change of body of water Error - Get Stop Data Error")
                }
                    do {
                        if let customer = masterDataManager.selectedCustomer {
                            //This should be by body of Water
                            try await serviceStopVM.getServiceStopsBetweenDatesAndByCustomer(companyId: company.id, startDate: startDate, endDate: endDate, customer: customer)
                            
                            //                        try await serviceStopVM.getServiceStopsBetweenDatesAndByType(companyId: company.id, startDate: startDate, endDate: endDate, workOrderType: "All")
                        }
                    } catch {
                        print("Change of body of water Error - Get Service Stop Error")
                    }
                }

            }
        })

    }
}


extension CustomerServiceHistoryView{
    var locationAndBodyOfWaterPicker: some View {
        HStack{
            Picker("Service Location", selection: $serviceLocation) {
                Text("Pick Location")
                ForEach(serviceLocationList) {
                    Text($0.address.streetAddress).tag($0)
                }
            }
            Picker("Body Of Water", selection: $bodyOfWater) {
                Text("Pick Body Of Water")
                ForEach(bodyOfWaterList) {
                    Text($0.name).tag($0)
                }
            }
            Picker("View", selection: $stringView) {
                ForEach(viewList,id:\.self){
                    Text($0).tag($0)
                }
            }
        }
    }
    var serviceHistory: some View {
        VStack{
            
            Text("Service History")
            ScrollView(.horizontal){
                ForEach(serviceStopVM.serviceStops) { datum in
                    HStack{
                        Text("\(fullDate(date:datum.serviceDate))")
                        Text("\(datum.tech)")
                        Text("\(datum.type)")
                        switch datum.operationStatus {
                        case .finished:
                            Text("\(datum.operationStatus.rawValue)")
                                .foregroundColor(Color.green)
                        case .notFinished:
                            Text("\(datum.operationStatus.rawValue)")
                                .foregroundColor(Color.red)
                        case .skipped:
                            Text("Skipped)")
                                .foregroundColor(Color.realYellow)
                        }
                        Button(action: {
                            
                        }, label: {
                            Text("See Details")
                        })
                        .foregroundColor(Color.basicFontText)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                        .padding(5)
                        
                    }
                }
            }
        }
    }
    var equipmentHistory: some View {
        VStack{
            
            Text("Equipment History")

        }
    }
    var chemHistory: some View {
        VStack{
            
            Text("Chem History")
            ScrollView(.horizontal){
                titleRow
                ForEach(stopDataVM.readingHistory) { datum in
                    
//                        EditStopDataRowView(stopData: $datum, readingTemplates: settingsVM.readingTemplates, dosageTemplate: settingsVM.dosageTemplates,bodyOfWaterId: bodyOfWaterId)
                        
                        StopDataRowView(stopData: datum, readingTemplates: settingsVM.readingTemplates, dosageTemplate: settingsVM.dosageTemplates)
                    
                }
            }
        }
    }
    var titleRow: some View {
        HStack{
            Text("00-00-0000")
                .foregroundColor(Color.clear)
                .overlay(Text("Date"))
            HStack{
                ForEach(settingsVM.readingTemplates){ template in
                    Text("\(template.name)")
                        .frame(minWidth: 35)
                }
            }
            HStack{
                ForEach(settingsVM.dosageTemplates){ template in
                    Text("\(template.name ?? "")")
                        .frame(minWidth: 35)
                }
            }
            Spacer()
        }
    }
}
