//
//  ServiceStopListView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct ServiceStopListView: View{
    //Environment
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    //View Models
    @StateObject private var serviceStopVM : ServiceStopsViewModel
    @StateObject private var customerVM: CustomerViewModel
    @StateObject private var settingsVM = SettingsViewModel()

    init(dataService:any ProductionDataServiceProtocol){
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
    }
    //Variables Received
    //Variables for Use
    @State private var serviceStops:[ServiceStop] = []
    
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State var workOrderType:String = "All"

    @State private var showFilters: Bool = false
    @State private var isPresented: Bool = false
    @State private var editing: Bool = false
    @State private var isLoading: Bool = false
    @State var searchTerm:String = ""
    @State private var nav: Bool = false
    @State var showActive:Bool = true
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    
    @State var showSearch:Bool = false
    @State var showAddNew:Bool = false
    
    var body: some View{
        ZStack{
            list
            icons
        }
        
        .task {
            //Add Subscriber
            do {
                if let company = masterDataManager.selectedCompany {
                    try await settingsVM.getWorkOrderTemplates(companyId: company.id)
                    try await serviceStopVM.getServiceStopsBetweenDatesAndByType(companyId: company.id, startDate: startDate, endDate: endDate, workOrderType: workOrderType)
                    serviceStops = serviceStopVM.serviceStops
                }
            } catch {
                alertMessage = "Unable to get Service Stops"
                showAlert = true
            }
        }
        .alert(isPresented:$showAlert) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: searchTerm){ term in
            if term == "" {
                serviceStops = serviceStopVM.serviceStops
            } else {
                serviceStopVM.filterServiceStopList(filterTerm: term, serviceStoplist: serviceStopVM.serviceStops)
                serviceStops = serviceStopVM.serviceStopsFilterd
            }
        }
    }
    
}

extension ServiceStopListView {
    var icons: some View{
        VStack{
            if showSearch {
                Color.basicFontText.opacity(0.5)
                    .onTapGesture {
                        showSearch.toggle()
                    }
            }
            VStack{
                Spacer()
                HStack{
                    VStack{
                        Button(action: {
                            showFilters.toggle()
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "slider.horizontal.3")
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(Color.white)
                                    )
                            }
                            
                            
                        })
                        .padding(10)
                        .sheet(isPresented: $showFilters, onDismiss: {
                            Task{
                                do {
                                    if let company = masterDataManager.selectedCompany {
                                        try await serviceStopVM.getServiceStopsBetweenDatesAndByType(companyId: company.id, startDate: startDate, endDate: endDate, workOrderType: workOrderType)
                                        serviceStops = serviceStopVM.serviceStops
                                    }
                                } catch {
                                    alertMessage = "Unable to get Customers"
                                    showAlert = true
                                }
                            }
                        }, content: {
                            VStack{
                                HStack{
                                    Text("Start Date: ")
                                    DatePicker(selection: $startDate, displayedComponents: .date) {
                                    }
                                }
                                HStack{
                                    Text("End Date: ")
                                    
                                    DatePicker(selection: $endDate, displayedComponents: .date) {
                                    }
                                }
                                HStack{
                                    Text("Work Order Type: ")
                                    Picker("", selection: $workOrderType) {
                                        Text("All").tag("All")
                                        ForEach(settingsVM.jobTemplates) { template in
                                            Text("\(template.name)").tag(template.name)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                        })
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.poolGreen)
                            }
                        })
                        .sheet(isPresented: $showAddNew, content: {
                            AddNewServiceStop(dataService: dataService)
                        })
                        .padding()
                        Button(action: {
                            showSearch.toggle()
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        })
                        .padding()
                        
                    }
                    Spacer()
                }
                if showSearch {
                    HStack{
                        TextField(
                            "Search",
                            text: $searchTerm
                        )
                        .padding()
                        .background(Color.basicFontText)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    var list: some View{
        VStack{
            if serviceStops.count == 0 {
                    Button(action: {
                        showAddNew.toggle()
                    }, label: {
                        
                        Text("Add First Service Stop")
                            .padding(UIDevice.isIPhone ? 0 : 10)
                            .background(UIDevice.isIPhone ? Color.clear: Color.blue)
                            .foregroundColor(UIDevice.isIPhone ? Color.blue : Color.white)
                            .cornerRadius(UIDevice.isIPhone ? 0 : 10)
                    })
                    
                    
            } else {
                
            
                List(selection:$masterDataManager.selectedID){
                    
                    ForEach(serviceStops){ serviceStop in
                        NavigationLink(value: Route.serviceStop(serviceStop: serviceStop,dataService: dataService), label: {
                            if UIDevice.isIPhone {
                                ServiceStopCardViewSmall(serviceStop: serviceStop)
                            } else {
                                ServiceStopCardViewLarge(serviceStop: serviceStop)
                            }
                        })
                        //                            NavigationLink(destination: {
                        //                                ServiceStopDetailView(showSignInView: $showSignInView, company: company, user: user, serviceStop: serviceStop)
                        //
                        //                            }, label: {
                        //                                ServiceStopCardViewSmall(serviceStop: serviceStop)
                        //                            })
                    }
                }
                
                .disabled(showSearch)
            }
        }
    }
}
