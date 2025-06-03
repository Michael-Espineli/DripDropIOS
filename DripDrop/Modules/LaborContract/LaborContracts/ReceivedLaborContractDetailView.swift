//
//  ReceivedLaborContractDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/20/24.
//


import SwiftUI

struct ReceivedLaborContractDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : RecurringLaborContractViewModel

    //Form
    @State var laborContract:ReccuringLaborContract
    @State var selectedLaborContract:ReccuringLaborContract? = nil

    @State var showEditLaborContract:Bool = false
    @State var generateLaborContract:Bool = false

    @State var notes:String = ""

    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    var body: some View {
        ZStack{
            Color.darkGray.ignoresSafeArea()
            VStack{
                header
                ScrollView(.vertical, showsIndicators: false) {
                    details
                }
                .background(Color.listColor)
                footer
            }
            Text("")
                .sheet(isPresented: $generateLaborContract, onDismiss: {
                    print("on Dismiss")

                }, content: {
                    GenerateRouteFromLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $generateLaborContract,isFullScreenCover: false)
                })
            Text("")
                .sheet(isPresented: $showEditLaborContract, onDismiss: {
                    print("on Dismiss")
                }, content: {
                    EditRecurringLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $showEditLaborContract,isFullScreenCover: false)
                })
        }
        .fontDesign(.monospaced)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            notes = laborContract.notes
            VM.receiverAcceptance = laborContract.receiverAcceptance
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadDetailView(companyId: currentCompany.id, laborContract: laborContract)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
        .onChange(of: masterDataManager.selectedRecurringLaborContract, perform: { datum in
            Task{
                if let datum {
                    print("Change In Labor Contract")
                    laborContract = datum
                    notes = laborContract.notes
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.onLoadDetailView(companyId: currentCompany.id, laborContract: laborContract)
                        } catch {
                            print("Error")

                            print(error)
                        }
                    }
                } else {
                    print("Optional")
                }
            }
        })
    }
}
extension ReceivedLaborContractDetailView{
    var header: some View {
        VStack(alignment:.leading){
            if let company = masterDataManager.currentCompany {
                if company.id != laborContract.senderId {
                    HStack{
                        Text("From:")
                            .fontWeight(.bold)
                        Text("\(laborContract.senderName)")
                        Spacer()
                        if laborContract.senderAcceptance {
                            Text("\(LaborContractStatus.accepted.rawValue)")
                                .padding(8)
                                .background(VM.getBackGroundColor(status: LaborContractStatus.accepted))
                                .cornerRadius(8)
                                .foregroundColor(VM.getForeGroundColor(status: LaborContractStatus.accepted))
                        }

                    }
                }
                if company.id != laborContract.receiverId {
                    HStack{
                        Text("To:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(laborContract.receiverName)")
                        if laborContract.receiverAcceptance {
                            Text("\(LaborContractStatus.accepted.rawValue)")
                                .padding(8)
                                .background(VM.getBackGroundColor(status: LaborContractStatus.accepted))
                                .cornerRadius(8)
                                .foregroundColor(VM.getForeGroundColor(status: LaborContractStatus.accepted))
                        }
                    }
                }
            }
            HStack{
                Text("Date Sent:")
                    .fontWeight(.bold)
                Spacer()
                Text("\(fullDate(date:laborContract.dateSent))")
            }
            VStack{
                HStack{
                    Text("Start Date:")
                        .bold()
                    Spacer()
                    Text("\(fullDate(date: laborContract.startDate))")
                }
                HStack{
                    Text("End Date:")
                        .bold()
                    Spacer()
                    Text("\(fullDate(date: laborContract.endDate))")
                }
            }
            Divider()


        }
        .padding(.vertical,8)
        .padding(.horizontal,8)
        .foregroundColor(Color.poolWhite)
        .background(Color.darkGray)
    }
    var details: some View {
        VStack(alignment:.leading){
            HStack{
                Text("Notes:")
                    .fontWeight(.bold)
                TextField("Notes", text: $notes, prompt: Text("Notes"))
                    .modifier(TextFieldModifier())
                Text("\(laborContract.notes)")
                Spacer()
            }
            Divider()

            recurringWorkView
            Divider()
            termsView
        }
        .padding(.horizontal,16)
        .frame(maxWidth: .infinity)
    }
    var recurringWorkView: some View {
        VStack{
            VStack{
                Text("Recurring Work 1")
                    .fontWeight(.bold)
                HStack{
                    Text("Accounts")
                    Spacer()
                    NavigationLink(destination: {
                        Text("Add List Of Clients They are contracted to complete")
                    }, label: {
                        HStack{
                            Text("Details")
                            Image(systemName: "arrow.right")
                        }
                    })
                }
                ForEach(VM.laborContractRecurringWorkList,id:\.self){ datum in
                    let index = VM.laborContractRecurringWorkList.firstIndex(of: datum)
                    VStack{
                        HStack{
                            Text("\((index ?? 0) + 1): \(datum.customerName)")
                            Spacer()
                            if datum.routeSetUp {
                                Image(systemName: "checkmark.circle")
                                    .modifier(SubmitButtonModifier())
                            } else {
                                Image(systemName: "circle")
                                    .modifier(DismissButtonModifier())
                            }
                        }
                        Text("\(datum.jobTemplateName) - \(datum.rate/100, format: .currency(code: "USD").precision(.fractionLength(2))) - \(datum.timesPerFrequency) \(datum.frequency.rawValue)")
                            .font(.footnote)
                        HStack{
                            Rectangle()
                                .frame(height: 1)
                            Spacer()
                        }
                        if VM.selectedRecurringWorkId == datum.id {
                            VStack{
                                HStack{
                                    Button(action: {
                                        VM.selectedRecurringWorkId = ""
                                    }, label: {
                                        Text("Close Details")
                                            .foregroundColor(Color.poolRed)
                                    })
                                    Spacer()
                                }
                                Rectangle()
                                    .frame(height: 1)
                                    .padding(.horizontal,17)
                                ForEach(datum.recurringServiceStopIdList,id:\.self){ id in
                                    HStack{
                                        Text(id.internalId)
                                            .modifier(ListButtonModifier())
                                        //Developer Update IdInfo
                                        RecurringWorkRecurringServicestopCardView(dataService: dataService, recurringServiceStopId: id.internalId, laborContract: laborContract)
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            .padding(.leading,16)
                        } else {
                            HStack{
                                Button(action: {
                                    VM.selectedRecurringWorkId = datum.id
                                }, label: {
                                    
                                    Text("See Details")
                                        .foregroundColor(Color.poolRed)
                                })
                                Spacer()
                            }
                            .padding(.leading,16)
                        }
                    }
                }
            }
        }
    }
    var termsView: some View {
        HStack{
            Text("Terms")
                .fontWeight(.bold)
            Spacer()
            NavigationLink(value: Route.contractTermsList(dataService: dataService, termsList: laborContract.terms), label: {
                HStack{
                    Text("See More")
                    Image(systemName: "chevron.right")
                }
                .modifier(RedLinkModifier())
                .lineLimit(1)
            })
        }
    }

    var footer: some View {
        VStack{
            if let company = masterDataManager.currentCompany {
                if !laborContract.receiverAcceptance || !laborContract.senderAcceptance {
                    if company.id != laborContract.receiverId && company.id == laborContract.senderId{
                        HStack{
                            if !VM.receiverAcceptance {
                                Button(action: {
                                    Task{
                                        do {
                                            try await VM.deleteLaborContract(companyId: company.id, laborContract: laborContract)
                                        } catch {
                                            print("error")
                                            print(error)
                                        }
                                    }
                                }, label: {
                                    Text("Delete Contract")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                            Spacer()
                            Button(action: {
                                //                            Task{
                                //                                do {
                                //                                    try await VM.sendRevisedLaborContractFromSender(companyId: company.id, laborContract: laborContract)
                                //                                } catch {
                                //                                    print("error")
                                //                                    print(error)
                                //                                }
                                //                            }
                                showEditLaborContract.toggle()
                            }, label: {
                                Text("Revise Contract")
                                    .modifier(AddButtonModifier())
                            })
                       
                            
                        }
                    } else if company.id != laborContract.senderId && company.id == laborContract.receiverId {
                        HStack{
                            Button(action: {
                                Task{
                                    do {
                                        //Accept Contract
                                        try await VM.markLaborContractAsAcceptedByReceiver(companyId: company.id, laborContract: laborContract)
                                        
                                        alertMessage = "Accepted Succsefully"
                                        // Reload Page
                                        if let currentCompany = masterDataManager.currentCompany {
                                            try await VM.onLoadDetailView(companyId: currentCompany.id, laborContract: laborContract)
                                        }

//                                        showAlert  = true
                                        print(alertMessage)
                                    } catch {
                                        print("error")
                                        print(error)
                                    }
                                }
                            }, label: {
                                Text("Accept")
                                    .modifier(SubmitButtonModifier())
                            })
                            Button(action: {
                                Task{
                                    do {
                                        try await VM.markLaborContractAsRejectedByReceiver(companyId: company.id, laborContract: laborContract)
                                    } catch {
                                        print("error")
                                        print(error)
                                    }
                                }
                            }, label: {
                                Text("Reject")
                                    .modifier(DismissButtonModifier())
                            })
                            .padding(.horizontal,8)
                            Spacer()
                            Button(action: {
                                //                            Task{
                                //                                do {
                                //                                    try await VM.sendRevisedLaborContractFromReceiver(companyId: company.id, laborContract: laborContract)
                                //                                } catch {
                                //                                    print("error")
                                //                                    print(error)
                                //                                }
                                //                            }
                                showEditLaborContract.toggle()
                            }, label: {
                                Text("Revise Contract")
                                    .modifier(AddButtonModifier())
                            })
                      
                        }
                    } else {
                        Text("Developer: Why are you looking at someone elses Labor Contract")
                    }
                } else {
                    // Both Sides have accepted Contract
                    
                    HStack{
                        if company.id == laborContract.receiverId {
                            Button(action: {
                                selectedLaborContract = laborContract
                                generateLaborContract.toggle()
                            }, label: {
                                Text("Generate Route From Contract")
                                    .modifier(AddButtonModifier())
                            })
                        }
                        Spacer()
                        if let associatedBusiness = VM.associatedBusiness {
                            NavigationLink(value: Route.createBulkInvoice(dataService: dataService, associatedBusiness: associatedBusiness), label: {
                                Text("Send Bulk Invoice")
                                    .modifier(AddButtonModifier())
                            })
                        }
                    }
                }
                
            } else {
                HStack{
                    Text("No Selected Company")
                 
                }
            }
        }
        .padding(.vertical,8)
        .padding(.horizontal,8)
        .background(Color.darkGray)
    }
    
}
