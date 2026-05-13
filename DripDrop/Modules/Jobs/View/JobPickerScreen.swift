//
//  JobPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/28/24.
//

import SwiftUI

struct JobPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var jobVM : JobViewModel
    @Binding var job : Job
    
    init(dataService:any ProductionDataServiceProtocol,job:Binding<Job>){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        
        self._job = job
    }
    
    @State var jobs:[Job] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                Text("Select Job")
                jobList
                searchBar
            }
            .padding()
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await jobVM.getAllUnbilledJobs(companyId: company.id) //DEVELOPER GET LIMITED JOBS
                    jobs = jobVM.workOrders
                }
            } catch {
                print("Error")
                
            }
        }
        .onChange(of: jobVM.searchTerm, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await jobVM.getAllUnbilledJobs(companyId: company.id) //DEVELOPER GET LIMITED JOBS
                            jobs = jobVM.workOrders
                        }
                    } catch {
                        print("Error")
                        
                    }
                }
            } else {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            
                            try await jobVM.filterWorkOrderList()
                            jobs = jobVM.filteredWorkOrders
                        }
                    } catch {
                        print("Error")
                    }
                }
            }
        })
    }
}
extension JobPickerScreen {
    var searchBar: some View {
        TextField(
            text: $jobVM.searchTerm,
            label: {
                Text("Search: ")
            })
        .modifier(SearchTextFieldModifier())
        .padding(8)
        
    }
    var jobList: some View {
        ScrollView{
            ForEach(jobs){ datum in
                Button(action: {
                    job = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        
                        Text("\(datum.internalId) - \(datum.customerName) - \(fullDate(date:datum.dateCreated))")
                        
                        Spacer()
                        if datum == job {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.poolGreen)
                        }
                    }
                    .modifier(ListButtonModifier())
                })
            }
        }
    }
}

