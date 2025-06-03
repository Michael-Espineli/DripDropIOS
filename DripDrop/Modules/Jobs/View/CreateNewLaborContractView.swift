//
//  CreateNewLaborContractView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//

import SwiftUI

@MainActor
final class CreateNewLaborContractViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }    
    @Published private(set) var jobTaskList: [JobTask] = []
    @Published var selectedJobTaskList: [JobTask] = []
    
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isLoading: Bool = false
    
    @Published var rate: String = "0"    

    @Published var description: String = ""
    @Published var daysToAccept: Int = 10
    @Published var showBuisnessPicker: Bool = false
    
    //Associated Buisnesses
    @Published private(set) var companyUserList: [CompanyUser] = []
    @Published var selectedBuisness: AssociatedBusiness = AssociatedBusiness(
        id: "",
        companyId: "",
        companyName: ""
    )
    @Published var termList:[ContractTerms] = []

    //Terms
    @Published var term:String = ""

    @Published var selectTermsTemplate:Bool = false
    @Published var seeTermsList:Bool = false

    @Published var selectedTermsTemplate:TermsTemplate = TermsTemplate(id: "", name: "")
    @Published var selectedTermList:[ContractTerms] = []

    func onLoad(companyId:String, description:String, jobTaskList: [JobTask]) async throws {
        self.jobTaskList = jobTaskList
        self.description = description
        self.companyUserList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
    }
    func offerNewLaborContract(
        company : Company,
        jobId : String,
        customerId : String,
        customerName : String,
        serviceLocationId : String
    ) async throws {
        print("offerNewLaborContract")
        if !isLoading {
            
            if selectedBuisness.id == "" {
                throw FireBasePublish.unableToPublish
            }
            self.isLoading = true
            var durationSeconds = 0
            for task in selectedJobTaskList {
                durationSeconds = durationSeconds + task.estimatedTime
            }
            
            print("1")
            //Uploading Labor Contract
            let serviceLocation : ServiceLocation = try await dataService.getServiceLocationById(companyId: company.id, locationId: serviceLocationId)
            
            print("2")
            let laborContractId = "lc_" + UUID().uuidString
            let lastDateToAccept = Calendar.current.date(byAdding: .day, value: daysToAccept, to: Date())!
            guard let rateDouble = Double(rate) else {
                throw FireBasePublish.unableToPublish
            }
            print("3")
            let rateCentsDouble = rateDouble*100
            let rateCentsInt = Int(rateCentsDouble)
            
            let laborContract = LaborContract(
                id: laborContractId,
                senderName: company.name,
                senderId: company.id,
                senderAcceptance: true,
                receiverName: selectedBuisness.companyName,
                receiverId: selectedBuisness.companyId,
                receiverAcceptance: false,
                
                type: .businessToBusiness,
                dateSent: Date(),
                lastDateToAccept: lastDateToAccept,
                status: .pending,
                terms: selectedTermList,
                notes: description,
                rate: rateCentsInt,
                senderJobId: IdInfo(id: jobId, internalId: ""),
                customerId: customerId,
                customerName: customerName,
                serviceLocationId: serviceLocationId,
                serviceLocationName: "",
                jobTemplateId: "",
                jobTemplateName: "", 
                isInvoiced: false
            )
            print(laborContract)
            try await dataService.uploadLaborContract(laborContractId: laborContractId, laborContract: laborContract)
            print("----  Labor Contract uploaded  -----")
            //Uploading Tasks to Labor Contract
            for task in selectedJobTaskList {
                //Developer Fix THis
                durationSeconds = durationSeconds + task.estimatedTime
                
                let laborContractTask = LaborContractTask(
                    name: task.name,
                    type: task.type,
                    contractedRate: task.contractedRate,
                    estimatedTime: task.estimatedTime,
                    status: .offered,
                    customerApproval: true,
                    laborContractId: "",
                    serviceStopId: IdInfo(id: "", internalId: ""),
                    jobIsCreated: false,
                    receiverJobId: [],
                    senderJobTaskId : task.id,
                    equipmentId: task.equipmentId,
                    serviceLocationId: task.serviceLocationId,
                    bodyOfWaterId: task.bodyOfWaterId,
                    shoppingListItemId: task.dataBaseItemId
                )
                //Upload Labor Contract Task
                try await dataService.uploadTaskToLaborContract(laborContractId: laborContractId, task: laborContractTask)

                //Update Job Task
                
                try dataService.updateJobTaskWorkerId(companyId: company.id, jobId: jobId, taskId: task.id, workerId: selectedBuisness.companyName)
                try dataService.updateJobTaskWorkerName(companyId: company.id, jobId: jobId, taskId: task.id, workerName: selectedBuisness.companyName)
                
                try dataService.updateJobTaskWorkerType(companyId: company.id, jobId: jobId, taskId: task.id, workerType: .contractor)
                
                try dataService.updateJobTaskLaborContractId(companyId: company.id, jobId: jobId, taskId: task.id, laborContractId: laborContract.id)
                
                try dataService.updateJobTaskStatus(companyId: company.id, jobId: jobId, taskId: task.id, status: .offered)
            }
            
            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
        }
    }
    func calcualteRateAndTime(tasks:[JobTask]) {
        var rate = 0
        var time = 0
        for task in tasks {
            rate = task.contractedRate + rate
            time = task.estimatedTime + time
        }
        self.rate = String(rate/100)
        print("Estiamted Time \(time)")
    }
}
struct CreateNewLaborContractView: View {
    init(
        dataService:any ProductionDataServiceProtocol,
        jobId:String,
        customerId:String,
        customerName:String,
        serviceLocationId:String,
        description:String,
        jobTaskList:[JobTask]
    ){
        _VM = StateObject(wrappedValue: CreateNewLaborContractViewModel(dataService: dataService))
        _jobId = State(wrappedValue: jobId)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _description = State(wrappedValue: description)
        _jobTaskList = State(wrappedValue: jobTaskList)
    }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : CreateNewLaborContractViewModel
    
    @State var jobId:String
    @State var customerId:String
    @State var customerName:String
    @State var serviceLocationId:String
    @State var description:String
    @State var jobTaskList:[JobTask]
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            formView
                .padding(8)
            if VM.isLoading {
                VStack{
                    ProgressView()
                    Text("Loading...")
                }
                .padding(8)
                .background(Color.gray)
                .cornerRadius(8)
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    
                    try await VM.onLoad(companyId: currentCompany.id, description:description, jobTaskList:jobTaskList)
                } catch {
                    print(error)
                }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: VM.selectedJobTaskList, perform: { tasks in
            VM.calcualteRateAndTime(tasks: tasks)
        })
    }
}

//#Preview {
//    CreateNewLaborContractView(jobId: "J1234567")
//}
extension CreateNewLaborContractView {
    var formView : some View {
        VStack{
            associatedBusinessesPicker
            HStack{
                Text("Days To Accept: ")
                Picker("Days To Accept", selection: $VM.daysToAccept) {
                    Text("Days To Accept").tag(1)
                    ForEach(1...100,id: \.self){
                        Text(String($0)).tag($0)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
            }
            HStack{
                Text("Rate")
                TextField(
                    "Rate",
                    text: $VM.rate
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .keyboardType(.decimalPad)
            }
            HStack{
                Text("Description")
                TextField(
                    "Description",
                    text: $VM.description
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
            }
            Rectangle()
                .frame(height: 1)
            Text("Select Tasks List")
                .font(.headline)
            Divider()
            ForEach(VM.jobTaskList){ type in
                switch type.status{
                case .accepted, .offered, .scheduled, .finished, .inProgress:
                    HStack{
                        Spacer()
                        Text("\(type.type) - \(type.status.rawValue) : \(type.name)")
                            .lineLimit(1)
                    }
                    .modifier(ListButtonModifier())
                    .opacity(0.5)
                case .unassigned, .rejected, .draft:
                        Button(action: {
                            if VM.selectedJobTaskList.contains(where: {$0.id == type.id}) {
                                VM.selectedJobTaskList.removeAll(where: {$0.id == type.id})
                            } else {
                                VM.selectedJobTaskList.append(type)
                            }
                        }, label: {
                            
                        HStack{
                            if VM.selectedJobTaskList.contains(where: {$0.id == type.id}) {
                                Image(systemName: "checkmark.square")
                            } else {
                                Image(systemName: "square")
                            }
                            Spacer()
                            Text("\(type.type) - \(type.status.rawValue) : \(type.name)")
                                .lineLimit(1)
                        }
                        .modifier(ListButtonModifier())
                    })
                }
            }
            Rectangle()
                .frame(height: 1)
            terms
            Button(action: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.offerNewLaborContract(
                                company: currentCompany,
                                jobId: jobId,
                                customerId: customerId,
                                customerName: customerName,
                                serviceLocationId: serviceLocationId
                            )
                            
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                }
            }, label: {
                HStack{
                    Spacer()
                    Text("Offer New Contract")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())
            })
            .disabled(VM.isLoading)
            .opacity(VM.isLoading ? 0.5 : 1)
            .padding(.top,8)
        }
    }
    var terms: some View {
        VStack{
            HStack{
                Text("Terms:")
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    VM.selectTermsTemplate.toggle()
                }, label: {
                    Text("Use Terms Template")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $VM.selectTermsTemplate, onDismiss: {
                    VM.termList = VM.selectedTermList
                }, content: {
                    TermsTemplatePicker(dataService: dataService, selectedTemplate: $VM.selectedTermsTemplate, termsList: $VM.selectedTermList)
                })
            }
            HStack{
                HStack{
                    Button(action: {
                        VM.term = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    TextField(
                        "Term",
                        text: $VM.term
                    )
                }
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                Spacer()
                Button(action: {
                    if VM.term != "" {
                        VM.termList.append(ContractTerms(description: VM.term))
                        VM.term = ""
                    }
                }, label: {
                    Text("Add Terms")
                        .modifier(AddButtonModifier())
                })
                .disabled(VM.term == "")
                .opacity(VM.term == "" ? 0.6 : 1)
            }
            HStack{
                Spacer()
                Button(action: {
                    VM.seeTermsList.toggle()
                }, label: {
                    Text("See Terms")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $VM.seeTermsList, onDismiss: {

                }, content: {
                    ContractTermsList(contractTerms: VM.termList)
                })
            }
        }
    }
    var associatedBusinessesPicker: some View {
        VStack{
            HStack{
                Button(action: {
                    VM.showBuisnessPicker.toggle()
                }, label: {
                    if VM.selectedBuisness.id == "" {
                        
                        HStack{
                            Spacer()
                            Text("Associated Buisness")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    } else {
                        
                        HStack{
                            Spacer()
                            Text(VM.selectedBuisness.companyName)
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    }
                })
                Spacer()
            }
            .sheet(isPresented: $VM.showBuisnessPicker, onDismiss: {
                
            }, content: {
                AssociatedBusinessesPickerView(dataService: dataService, business: $VM.selectedBuisness)
            })
        }
    }

}
