    //
    //  AddNewLaborContract.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 7/4/24.
    //

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class AddNewLaborContractFromAssociatedBusinessViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var findNewBusiness : Bool = false
    
    @Published private(set) var buisness : AssociatedBusiness? = nil
    @Published private(set) var buisnessList : [AssociatedBusiness] = []
    @Published private(set) var company : Company? = nil
    @Published private(set) var companyList : [Company] = []
    
    @Published private(set) var companyUsers: [CompanyUser] = []
    
    @Published private(set) var owner : DBUser? = nil
    
    @Published private(set) var sentContracts : [ReccuringLaborContract] = []
    @Published private(set) var receivedContracts : [ReccuringLaborContract] = []
        //Form
    @Published var laborContract:LaborContractRecurringWork = LaborContractRecurringWork(
        id: UUID().uuidString,
        customerId: UUID().uuidString,
        customerName: "Jessica",
        serviceLocationId: "",
        serviceLocationName: "",
        jobTemplateId: "",
        jobTemplateName: "",
        rate: 0,
        laborType: .job,
        frequency: .weekly,
        timesPerFrequency: 1,
        timesPerFrequencySetUp: 0,
        routeSetUp: false,
        recurringServiceStopIdList: [],
        isActive: true,
        lastBilled: Date()
    )
    @Published var recurringWork:[LaborContractRecurringWork] = []
    @Published var notes:String = ""
    @Published var term:String = ""
    @Published var endDate:Date = Date()
    @Published var startDate:Date = Date()
    
    @Published var lastDateToAccept:Date = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
    
    @Published var atWill:Bool = false
    @Published var termList:[ContractTerms] = []
    @Published var contractLengthInMonthsStr:String = ""
    
    @Published var selectedTermsTemplate:TermsTemplate = TermsTemplate(id: "", name: "")
    @Published var selectedTermList:[ContractTerms] = []
    
        //Alert
    @Published var alertMessage:String = ""
    @Published var showAlert:Bool = false
    @Published var addRecurringWork:Bool = false
    
    @Published var selectTermsTemplate:Bool = false
    
    func sendNewLaborContractToAssociatedBusiness(company:Company,associatedBusiness:AssociatedBusiness) async throws {
        if recurringWork.isEmpty {
            throw FireBaseRead.unableToRead
        }
        print("1")
        var contractLengthInMonths:Int? = 0
        
        if !atWill {
            contractLengthInMonths = Int(contractLengthInMonthsStr)
        }
        
        print("2")
        let recurringContract = ReccuringLaborContract(
            id: UUID().uuidString,
            senderName: company.name,
            senderId: company.id,
            senderAcceptance: true,
            receiverName: associatedBusiness.companyName,
            receiverId: associatedBusiness.companyId,
            receiverAcceptance: false,
            dateSent: Date(),
            lastDateToAccept: lastDateToAccept,
            dateAccepted: nil,
            startDate: startDate,
            endDate: endDate,
            status: .pending,
            isActive: false,
            terms: termList,
            notes: notes,
            atWill: atWill,
            contractLengthInMonths:contractLengthInMonths
        )
        
        
        print("3")
        try await dataService.addLaborContract(companyId: company.id, laborContract: recurringContract)
        
        print("4")
        try await dataService.addLaborContract(companyId: recurringContract.receiverId, laborContract: recurringContract)
        
        print("5")
        for work in recurringWork {
            try await dataService.addLaborContractRecurringWork(companyId: company.id, laborContractId: recurringContract.id, laborContractRecurringWork: work)
            try await dataService.addLaborContractRecurringWork(companyId: recurringContract.receiverId, laborContractId: recurringContract.id, laborContractRecurringWork: work)
        }
        
        print("6")
        try await dataService.addDripDropAlert(
            companyId: recurringContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .receivedLaborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "New Labor Contract",
                description: "From \(recurringContract.senderName)",
                date: Date()
            )
        )
        
        print("7")
            //Reset
        self.alertMessage = "Successfully Added"
        self.showAlert = true
        print(alertMessage)
        self.recurringWork = []
        self.notes = ""
        self.term = ""
        self.endDate = Date()
        self.startDate = Date()
        self.atWill = false
        self.termList = []
        self.contractLengthInMonthsStr = ""
        self.selectedTermsTemplate = TermsTemplate(id: "", name: "")
        self.selectedTermList = []
        
    }
}
struct AddNewLaborContractFromAssociatedBusiness: View {
        //Objects
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager
    
    @StateObject var VM : AddNewLaborContractFromAssociatedBusinessViewModel
    
    @Binding var isPresented:Bool
    @State var isFullScreen:Bool
    @State var associatedBusiness:AssociatedBusiness
    
        //Init
    init(dataService:ProductionDataService,associatedBusiness:AssociatedBusiness,isPresented:Binding<Bool>,isFullScreen:Bool){
        _VM = StateObject(wrappedValue: AddNewLaborContractFromAssociatedBusinessViewModel(dataService: dataService))
        _associatedBusiness = State(wrappedValue: associatedBusiness)
        self._isPresented = isPresented
        _isFullScreen = State(wrappedValue: isFullScreen)
    }
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                submitButton
                form
            }
            .fontDesign(.monospaced)
            .padding(8)
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            VM.endDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())!
        }
    }
}

    //#Preview {
    //    AddNewVehical()
    //}
extension AddNewLaborContractFromAssociatedBusiness {
    var form: some View {
        VStack{
            DatePicker("Date To Accept", selection: $VM.lastDateToAccept, in: Date()...,displayedComponents: .date)
            Toggle("At Will", isOn: $VM.atWill)
                .padding(.trailing,8)
            Divider()
            work
            
            Divider()
            terms
            Divider()
            HStack{
                Text("Notes:")
                    .bold()
                Spacer()
            }
            TextField(
                "Notes",
                text: $VM.notes
            )
            .modifier(PlainTextFieldModifier())
        }
    }
    var work: some View {
        VStack{
            HStack{
                Spacer()
                    Text("Recurring Work Requested:")
                        .fontWeight(.bold)
                Spacer()
            }
            .lineLimit(1)
            HStack{
                Spacer()
                Button(action: {
                    VM.addRecurringWork.toggle()
                }, label: {
                    Text("Add Work")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $VM.addRecurringWork,
                       onDismiss: {
                    print("Dismissed")
                    if VM.laborContract.customerId != "" && VM.laborContract.serviceLocationId != "" && VM.laborContract.jobTemplateId != "" && VM.laborContract.rate != 0  {
                        VM.recurringWork.append(VM.laborContract)
                        VM.laborContract = LaborContractRecurringWork(
                            id: UUID().uuidString,
                            customerId: UUID().uuidString,
                            customerName: "",
                            serviceLocationId: "",
                            serviceLocationName: "",
                            jobTemplateId: "",
                            jobTemplateName: "",
                            rate: 0,
                            laborType: .job,
                            frequency: .weekly,
                            timesPerFrequency: 1,
                            timesPerFrequencySetUp: 0,
                            routeSetUp: false,
                            recurringServiceStopIdList: [],
                            isActive: true,
                            lastBilled: Date()
                        )
                        print("Added Recurring Work")
                        
                    } else {
                        print("Did not add Recurring Work")
                        
                        print("Customer Id: \(VM.laborContract.customerId)")
                        print("Service Location Id: \(VM.laborContract.serviceLocationId)")
                        print("Job Template Id: \(VM.laborContract.jobTemplateId)")
                        print("Rate: \(VM.laborContract.rate)")
                        
                    }
                },
               content: {
                    LaborContractRecurringWorkPicker(dataService: dataService, laborContractRecurringWork: $VM.laborContract)
                })
            }
            ForEach(VM.recurringWork,id:\.self){ datum in
                let index = VM.recurringWork.firstIndex(of: datum)
                HStack{
                    Text("\((index ?? 0) + 1): ")
                    Text("\(datum.customerName): \(datum.jobTemplateName) - \(datum.rate/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    Spacer()
                    Button(action: {
                        VM.recurringWork.remove(datum)
                    }, label: {
                        Image(systemName: "trash.fill")
                            .modifier(DismissButtonModifier())
                    })
                }
                
            }
        }
    }
    var terms: some View {
        VStack{
            HStack{
                Text("Terms:")
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(value: Route.contractTermsList(dataService: dataService, termsList: VM.termList), label: {
                    Text("See Terms")
                        .modifier(RedLinkModifier())
                })
            }
            
            Button(action: {
                VM.selectTermsTemplate.toggle()
            }, label: {
                Text("Use Terms Template")
                    .modifier(AddButtonModifier())
            })
            .sheet(isPresented: $VM.selectTermsTemplate, onDismiss: {
                VM.termList = VM.termList + VM.selectedTermList
            }, content: {
                TermsTemplatePicker(dataService: dataService, selectedTemplate: $VM.selectedTermsTemplate, termsList: $VM.selectedTermList)
            })
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
                .modifier(PlainTextFieldModifier())
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
        }
    }
    var submitButton: some View {
        HStack{
            if isFullScreen {
                Button(action: {
                    isPresented.toggle()
                }, label: {
                    Image(systemName: "xmark")
                        .modifier(DismissButtonModifier())
                })
            }
            Spacer()
            Button(action: {
                Task{
                    if let selectedCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.sendNewLaborContractToAssociatedBusiness(
                                company: selectedCompany,
                                associatedBusiness: associatedBusiness
                            )
                        } catch {
                            VM.alertMessage = "Failed To Added"
                            VM.showAlert = true
                            print(VM.alertMessage)
                            print("Error")
                            print(error)
                        }
                    }
                }
            },
                   label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())
            })
        }
        .padding(.vertical,8)
    }
}
