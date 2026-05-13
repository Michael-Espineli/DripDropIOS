//
//  NewRecurringServiceStopFromLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/14/24.
//


import SwiftUI

struct NewRecurringServiceStopFromLaborContract: View {
    init(dataService:any ProductionDataServiceProtocol,laborContract:ReccuringLaborContract,recurringWork:Binding<LaborContractRecurringWork>,isLoading:Binding<Bool>){
//        _VM = StateObject(wrappedValue: NewRecurringServiceStopViewModel(dataService: dataService))

        _laborContract = State(wrappedValue: laborContract)
        self._recurringWork = recurringWork
        self._isLoading = isLoading
    }
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @EnvironmentObject var VM: GenerateRouteFromLaborContractViewModel

    //Received Variables
    @Binding var recurringWork:LaborContractRecurringWork
    @Binding var isLoading:Bool

    @State var laborContract:ReccuringLaborContract
    @State var day:String? = nil

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                form
                button
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    print("On Load")
                    try await VM.onLoadNewReucrringFromLaborContract(
                        companyId: company.id,
                        laborContract: laborContract,
                        laborContractRecurringWork: recurringWork
                    )
                } catch {
                    print("error")
                    print(error)
                }
            }
        }
        .onChange(of: recurringWork, perform: { work in
            Task{
                if let company = masterDataManager.currentCompany {
                    do {
                        print("on Change")
                        try await VM.onLoadNewReucrringFromLaborContract(
                            companyId: company.id,
                            laborContract: laborContract,
                            laborContractRecurringWork: work
                        )
                    } catch {
                        print("error")
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.customerSearch, perform: { search in
            VM.filterCustomerList()
            print("Search \(search)")
        })
    }
}


extension NewRecurringServiceStopFromLaborContract {
    var button: some View {
        VStack{
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany{
                        do {
                            print("generateRecurringStopFromRecurringWork")                        
                            isLoading = true
                            try await VM.generateRecurringStopFromRecurringWork(companyId: company.id)                        
                            isLoading = false
                        } catch {                        
                            isLoading = false

                            print(error)
                        }
                    }
                }
            }, label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())
                    .opacity(isLoading ? 0.75 : 1)
                    .disabled(isLoading)
            })
        }
    }
    var form: some View {
        VStack{
            info
            technical
        }
    }
    var info: some View {
        VStack{
            HStack{
                Text("\(VM.jobType.name)")
                Spacer()
            }
            Button(action: {
                VM.showCompanyUserPicker.toggle()
            }, label: {
                if VM.techEntity.id == "" {
                    Text("Select User")
                        .modifier(AddButtonModifier())
                } else {
                    Text(VM.techEntity.userName)
                        .modifier(AddButtonModifier())
                }
            })
            .sheet(isPresented: $VM.showCompanyUserPicker, content: {
                CompanyUserPicker(dataService: dataService, companyUser: $VM.techEntity)
            })
        }
    }
    var technical: some View {
        VStack{
            ScrollView(.horizontal,showsIndicators: false) {
                HStack{
                    ForEach(DaysOfWeek.allCases,id:\.self){ day in
                        Button(action: {
                            if let selectedDay = VM.selectedDay {
                                if selectedDay == day {
                                    VM.selectedDay = nil
                                } else {
                                    VM.selectedDay = day
                                }
                            } else {
                                VM.selectedDay = day
                            }
                        }, label: {
                            Text(day.rawValue)
                                .padding(4)
                                .padding(.horizontal,2)
                                .background(VM.selectedDay == day ? Color.poolBlue : Color.gray)
                                .foregroundColor(Color.white)
                                .cornerRadius(4)
                                .padding(.horizontal,4)
                        })
                    }
                }
            }
            DatePicker(selection: $VM.startDate, displayedComponents: .date) {
                Text("Start Date")
            }
            Toggle("Never Ends", isOn: $VM.noEndDate)
            if !VM.noEndDate {
                DatePicker(selection: $VM.endDate, displayedComponents: .date) {
                    Text("End Date")
                }
            }
            HStack{
                Text("Description:")
                TextField(
                    "Description",
                    text: $VM.description
                )
                .modifier(PlainTextFieldModifier())
            }
            HStack{
                Text("Estimated Time:")
                TextField(
                    "Estimated Time",
                    text: $VM.estimatedTime
                )
                .modifier(PlainTextFieldModifier())
            }
        }
    }
    
    var daySelector: some View {
        VStack{
            ScrollView(.horizontal,showsIndicators: false){
                HStack{
                    
                    ForEach(DaysOfWeek.allCases,id:\.self){ day in
                        Button(action: {
                            if let selectedDay = VM.selectedDay {
                                if selectedDay == day {
                                    VM.selectedDay = nil
                                } else {
                                    VM.selectedDay = day
                                }
                            } else {
                                VM.selectedDay = day
                            }
                        }, label: {
                            if VM.selectedDay == day {
                                Text(day.rawValue)
                                    .padding(5)
                                    .background(Color.green)
                                    .cornerRadius(5)
                                    .foregroundColor(Color.white)
                            } else {
                                Text(day.rawValue)
                                    .padding(5)
                                    .background(Color.blue)
                                    .cornerRadius(5)
                                    .foregroundColor(Color.white)
                            }
                        })
                    }
                }
            }
        }
    }
}
