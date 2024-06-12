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
    
    @State var search:String = ""
    @State var jobs:[Job] = []
    var body: some View {
        VStack{
            jobList
            searchBar
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.selectedCompany {
                    try await jobVM.getAllUnbilledJobs(companyId: company.id) //DEVELOPER GET LIMITED JOBS
                    jobs = jobVM.workOrders
                }
            } catch {
                print("Error")

            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
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
                        if let company = masterDataManager.selectedCompany {
                            
                            try await jobVM.filterWorkOrderList(filterTerm: term, workOrders: jobs)
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
            text: $search,
            label: {
                Text("Search: ")
            })
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.basicFontText)
        
    }
    var jobList: some View {
        ScrollView{
            Divider()

            ForEach(jobs){ datum in
                HStack{
                    Spacer()
                    Button(action: {
                        job = datum
                        dismiss()
                    }, label: {
                        Text("\(datum.id) - \(datum.customerName) - \(fullDate(date:datum.dateCreated))")
                    })
                
                    Spacer()
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(Color.black)
                .cornerRadius(5)
                .padding(2)
                Divider()
            }
        }
    }
}

