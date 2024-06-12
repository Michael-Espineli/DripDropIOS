//
//  CustomerUpcomingWork.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/22/23.
//

import SwiftUI

struct CustomerUpcomingWork: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : CustomerProfileViewModel

    @State var customer:Customer
    init(dataService:any ProductionDataServiceProtocol,customer:Customer) {
        _VM = StateObject(wrappedValue: CustomerProfileViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
    }
    @State var editRSS:Bool = false
    @State var addRSS:Bool = false
    
    @State var addRepairRequest:Bool = false
    
    @State var addJob:Bool = false
    
    @State var addItem:Bool = false

    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeleteConfirmation:Bool = false
    @State var rssID:String = ""

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
  
                repairRequests
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .cornerRadius(4)

                jobs
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .cornerRadius(4)
                
                recurringServiceStops
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .cornerRadius(4)
                items
            }
            .padding(.horizontal,8)
        }
        .task{
            if let company = masterDataManager.selectedCompany {

                do {
                    try await VM.onLoad(companyId: company.id, customerId: customer.id)
                } catch {
                    print(error)
                }
            }
        }
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    if rssID != "" {
                        Task{
                            if let company = masterDataManager.selectedCompany {
                                do {
                                    try await VM.deleteRecurringServiceStop(companyId: company.id, RecurringServiceStopId: rssID)
                                    rssID = ""
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

extension CustomerUpcomingWork {
    var recurringServiceStops: some View {
        VStack{
            HStack{
                Button(action: {
                    self.editRSS.toggle()
                }, label: {
                    Image(systemName: "square.and.pencil")
                        .modifier(BasicButtonModifier())
                })
                Spacer()
                Text("Recurring Service Stops")
                    .font(.headline)
                Spacer()
                Button(action: {
                    self.addRSS.toggle()

                }, label: {
                    Image(systemName: "plus")
                        .modifier(BasicButtonModifier())
                })
                .sheet(isPresented: $addRSS, content: {
                    Text("Add RSS Logic")
                })
          
            }
            ForEach(VM.recurringServiceStops) { RSS in
                Divider()
                HStack{
                    NavigationLink(value: Route.routeBuilder(dataService: dataService), label: {
                        RecurringServiceStopSmallCardView(recurringServiceStop: RSS)
                    })
                    Button(action: {
                        rssID = RSS.id
                        if rssID != "" {
                            self.showDeleteConfirmation.toggle()
                        }
                    }, label: {
                        Image(systemName: "trash.fill")
                            .modifier(DismissButtonModifier())
                    })
                }
            }
        }
    }

    var repairRequests: some View {
        VStack{
            HStack{
                Spacer()
                Text("Repair Requests")
                    .font(.headline)
                Spacer()
                Button(action: {
                    self.addRepairRequest.toggle()

                }, label: {
                    Image(systemName: "plus")
                        .modifier(BasicButtonModifier())
                })
                .sheet(isPresented: $addRepairRequest, content: {
                    AddNewRepairRequest(dataService: dataService)
                })
            }
            ForEach(VM.repairRequest) { repair in
                Divider()
                NavigationLink(value: Route.repairRequest(repairRequest: repair, dataService: dataService), label: {
                    RepairRequestCardView(repairRequest: repair)
                })
            }
        }
    }
    var jobs: some View {
        VStack{
            HStack{
                Spacer()
                Text("Jobs")
                    .font(.headline)
                Spacer()
                Button(action: {
                    self.addJob.toggle()

                }, label: {
                    Image(systemName: "plus")
                        .modifier(BasicButtonModifier())
                })
                .sheet(isPresented: $addJob, content: {
                    AddNewJobView(dataService: dataService)
                })
            }

            ForEach(VM.jobs) { job in
                Divider()
                JobCardView(job: job)
            }
        }
    }
    var items: some View {
        VStack{
            HStack{
                Spacer()
                Text("Items")
                    .font(.headline)
                Spacer()
                Button(action: {
                    self.addItem.toggle()

                }, label: {
                    Image(systemName: "plus")
                        .modifier(BasicButtonModifier())
                })
                .sheet(isPresented: $addItem, content: {
                    
                    AddNewItemToShoppingList(dataService: dataService)
                })
            }
        }
    }
}
