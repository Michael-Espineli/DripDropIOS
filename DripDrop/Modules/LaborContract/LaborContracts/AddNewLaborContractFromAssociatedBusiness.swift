//
//  AddNewLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct AddNewLaborContractFromAssociatedBusiness: View {
    //Init
    init(dataService:ProductionDataService,associatedBusiness:AssociatedBusiness,isPresented:Binding<Bool>,isFullScreen:Bool){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
        _associatedBusiness = State(wrappedValue: associatedBusiness)
        self._isPresented = isPresented
        _isFullScreen = State(wrappedValue: isFullScreen)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : BuisnessViewModel
    @EnvironmentObject var dataService : ProductionDataService
    @Binding var isPresented:Bool
    @State var isFullScreen:Bool
    
    //Form
    @State var associatedBusiness:AssociatedBusiness
    @State var laborContract:LaborContractRecurringWork = LaborContractRecurringWork(
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
        recurringServiceStopIdList: []
    )
    @State var recurringWork:[LaborContractRecurringWork] = []
    @State var notes:String = ""
    @State var term:String = ""
    @State var endDate:Date = Date()
    @State var startDate:Date = Date()
    
    @State var lastDateToAccept:Date = Date()
    
    @State var atWill:Bool = false
    @State var termList:[ContractTerms] = []
    @State var contractLengthInMonthsStr:String = ""
    
    @State var selectedTermsTemplate:TermsTemplate = TermsTemplate(id: "", name: "")
    @State var selectedTermList:[ContractTerms] = []
    
    //Alert
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var addRecurringWork:Bool = false
    
    @State var selectTermsTemplate:Bool = false
    
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
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            endDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())!
        }
    }
}

//#Preview {
//    AddNewVehical()
//}
extension AddNewLaborContractFromAssociatedBusiness {
    var form: some View {
        VStack{
            DatePicker("Date To Accept", selection: $lastDateToAccept, in: Date()...,displayedComponents: .date)
            Toggle("At Will", isOn: $atWill)
                .padding(.trailing,8)
            Divider()
            work
            
            Divider()
            terms
            Divider()
            HStack{
                Text("Notes:")
                TextField(
                    "Notes",
                    text: $notes
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                
                Spacer()
            }
        }
    }
    var work: some View {
        VStack{
            
            HStack{
                Text("Recurring Work Requested:")
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    addRecurringWork.toggle()
                }, label: {
                    Text("Add Work")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $addRecurringWork,
                       onDismiss: {
                    print("Dismissed")
                    if laborContract.customerId != "" && laborContract.serviceLocationId != "" && laborContract.jobTemplateId != "" && laborContract.rate != 0  {
                        recurringWork.append(laborContract)
                        laborContract = LaborContractRecurringWork(
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
                            recurringServiceStopIdList: []
                        )
                        print("Added Recurring Work")
                        
                    } else {
                        print("Did not add Recurring Work")

                        print("customerId \(laborContract.customerId)")
                        print("serviceLocationId \(laborContract.serviceLocationId)")
                        print("jobTemplateId \(laborContract.jobTemplateId)")
                        print("rate \(laborContract.rate)")
                        
                    }
                },
                       content: {
                    LaborContractRecurringWorkPicker(dataService: dataService, laborContractRecurringWork: $laborContract)
                })
            }
            ForEach(recurringWork,id:\.self){ datum in
                let index = recurringWork.firstIndex(of: datum)
                HStack{
                    Text("\((index ?? 0) + 1): ")
                    Text("\(datum.customerName): \(datum.jobTemplateName) - \(datum.rate, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    Spacer()
                    Button(action: {
                        recurringWork.remove(datum)
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
                Button(action: {
                    selectTermsTemplate.toggle()
                }, label: {
                    Text("Use Terms Template")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $selectTermsTemplate, onDismiss: {
                    termList = selectedTermList
                }, content: {
                    TermsTemplatePicker(dataService: dataService, selectedTemplate: $selectedTermsTemplate, termsList: $selectedTermList)
                })
            }
            HStack{
                HStack{
                    Button(action: {
                        term = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    TextField(
                        "Term",
                        text: $term
                    )
                }
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                Spacer()
                Button(action: {
                    if term != "" {
                        termList.append(ContractTerms(description: term))
                        term = ""
                    }
                }, label: {
                    Text("Add Terms")
                        .modifier(AddButtonModifier())
                })
                .disabled(term == "")
                .opacity(term == "" ? 0.6 : 1)
            }
            ForEach(termList,id:\.self){ datum in
                let index = termList.firstIndex(of: datum)
                HStack{
                    Text("\((index ?? 0) + 1):")
                    Text(datum.description)
                    Spacer()
                    Button(action: {
                        termList.remove(datum)
                    }, label: {
                        Image(systemName: "trash.fill")
                            .modifier(DismissButtonModifier())
                    })
                }
                
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
                            var contractLengthInMonths:Int? = 0
                            if !atWill {
                                contractLengthInMonths = Int(contractLengthInMonthsStr)
                            }
                            try await VM.sendNewLaborContractToAssociatedBusiness(
                                companyId: selectedCompany.id,
                                laborContract: RepeatingLaborContract(
                                    id: UUID().uuidString,
                                    senderName: selectedCompany.name,
                                    senderId: selectedCompany.id,
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
                                    terms: termList,
                                    notes: notes,
                                    atWill: atWill,
                                    contractLengthInMonths:contractLengthInMonths
                                ),
                                recurringWork:recurringWork
                            )
                            alertMessage = "Successfully Added"
                            showAlert = true
                            print(alertMessage)
                            recurringWork = []
                            notes = ""
                            term = ""
                            endDate = Date()
                            startDate = Date()
                            atWill = false
                            termList = []
                            contractLengthInMonthsStr = ""
                            selectedTermsTemplate = TermsTemplate(id: "", name: "")
                            selectedTermList = []
                            
                        } catch {
                            alertMessage = "Failed To Added"
                            showAlert = true
                            print(alertMessage)
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
    }
}
