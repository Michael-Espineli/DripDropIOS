//
//  SentLaborContractDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/20/24.
//

import SwiftUI

struct SentLaborContractDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : RecurringLaborContractViewModel
    
    //Received
    @State var laborContract:ReccuringLaborContract

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
                .sheet(isPresented: $VM.showGenerateLaborContract , onDismiss: {
                    print("on Dismiss")
                    
                }, content: {
                    GenerateRouteFromLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $VM.showGenerateLaborContract,isFullScreenCover: false)
                })
            Text("")
                .sheet(isPresented: $VM.showEditLaborContract, onDismiss: {
                    print("on Dismiss")
                }, content: {
                    EditRecurringLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $VM.showEditLaborContract,isFullScreenCover: false)
                })
        }
        .fontDesign(.monospaced)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            VM.notes = laborContract.notes
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
                    VM.notes = laborContract.notes
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
extension SentLaborContractDetailView{
    var header: some View {
        VStack(alignment:.leading){
            HStack{
                Text("To:")
                    .fontWeight(.bold)
                Text("\(laborContract.receiverName)")
                Spacer()
                if laborContract.receiverAcceptance {
                    Text("\(LaborContractStatus.accepted.rawValue)")
                        .padding(4)
                        .padding(.horizontal,2)
                        .background(VM.getBackGroundColor(status: LaborContractStatus.accepted))
                        .cornerRadius(4)
                        .foregroundColor(VM.getForeGroundColor(status: LaborContractStatus.accepted))
                        .font(.footnote)
                }
            }
            .lineLimit(1)
            HStack{
                Text("Date Sent:")
                    .fontWeight(.bold)
                Text("\(fullDate(date:laborContract.dateSent))")
                Spacer()
            }
            VStack{
                HStack{
                    Text("Start Date: \(fullDate(date: laborContract.startDate))")
                        .fontWeight(.bold)
                    Text("\(fullDate(date: laborContract.startDate))")
                    Spacer()
                }
                HStack{
                    Text("End Date: ")
                        .fontWeight(.bold)
                    Text("\(fullDate(date: laborContract.endDate))")
                    Spacer()
                }
            }
            Divider()
        }
        .padding(.vertical,8)
        .padding(.horizontal,8)
        .foregroundColor(Color.poolWhite)
        .background(Color.darkGray)
        .fontDesign(.default)
    }
    
    var details: some View {
        VStack(alignment:.leading){
            HStack{
                Text("Notes:")
                    .fontWeight(.bold)
                TextField("Notes", text: $VM.notes, prompt: Text("Notes"))
                    .modifier(TextFieldModifier())
                Text("\(laborContract.notes)")
                Spacer()
            }
            .padding(.top,8)
            Rectangle()
                .frame(height: 1)
            recurringWorkView
            Rectangle()
                .frame(height: 1)
            termsView
        }
        .padding(.horizontal,16)
        .frame(maxWidth: .infinity)
    }
    
    var recurringWorkView: some View {
        VStack{
            VStack{
                Text("Recurring Work")
                    .fontWeight(.bold)
                HStack{
                    Text("Accounts")
                    Spacer()
                    //                    Text("\(laborContract.recurringWork.count)")
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
                        Button(action: {
                            VM.selectedRecurringWorkOptional = datum
                        }, label: {
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
                                Text("\(datum.jobTemplateName) - \(datum.rate, format: .currency(code: "USD").precision(.fractionLength(2))) - \(datum.timesPerFrequency) \(datum.frequency.rawValue)")
                                    .font(.footnote)
                            }
                            .modifier(ListButtonModifier())
                        })
                        if VM.selectedRecurringWorkId == datum.id {
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        VM.selectedRecurringWorkId = ""
                                    }, label: {
                                        Text("Close Details")
                                            .modifier(RedLinkModifier())
                                    })
                                }
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
                                Spacer()
                                Button(action: {
                                    VM.selectedRecurringWorkId = datum.id
                                }, label: {
                                    
                                    Text("See Details")
                                        .modifier(RedLinkModifier())
                                })
                            }
                            .padding(.leading,16)
                        }
                    }
                    .sheet(item: $VM.selectedRecurringWorkOptional, onDismiss: {
                        
                    }, content: { work in
                        VStack{
                            Text("\(work.customerName)")
                            Rectangle()
                                .frame(height: 1)
                            Button(action: {
                            }, label: {
                                
                                Text("Cancel Work")
                                    .frame(maxWidth: .infinity)
                                    .modifier(ListButtonModifier())
                            })
                            Button(action: {
                                VM.showOfferNewRate.toggle()
                            }, label: {
                                Text("Offer New Rate")
                                    .frame(maxWidth: .infinity)
                                    .modifier(ListButtonModifier())
                            })
                            .sheet(isPresented: $VM.showOfferNewRate,
                                   onDismiss: {
                                print("Dismiss")
                            }, content: {
                                OfferNewRate(
                                    dataService: dataService,
                                    isPresented: $VM.showOfferNewRate,
                                    laborContract: laborContract,
                                    recurringWork: datum
                                )
                            })
                        }
                        .padding(8)
                        .presentationDetents([.medium,.large])
                    })
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
            if !laborContract.receiverAcceptance || !laborContract.senderAcceptance {
                HStack{
                    if !laborContract.receiverAcceptance {
                        Button(action: {
                            Task{
                                if let currentCompany = masterDataManager.currentCompany {
                                    do {
                                        try await VM.deleteLaborContract(companyId: currentCompany.id, laborContract: laborContract)
                                    } catch {
                                        print("error")
                                        print(error)
                                    }
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
                        if let currentCompany = masterDataManager.currentCompany {
                            
                            //                                do {
                            //                                    try await VM.sendRevisedLaborContractFromSender(companyId: company.id, laborContract: laborContract)
                            //                                } catch {
                            //                                    print("error")
                            //                                    print(error)
                            //                                }
                        }
                        //                            }
                        VM.showEditLaborContract.toggle()
                    }, label: {
                        Text("Revise Contract")
                            .modifier(AddButtonModifier())
                    })
                }
            } else {
                // Both Sides have accepted Contract
                HStack{
                    Spacer()
                    Button(action: {
                        VM.showEditLaborContract.toggle()
                    }, label: {
                        Text("Offer Updated Contract")
                            .modifier(AddButtonModifier())
                    })
                }
            }
            
        }
        .padding(.vertical,8)
        .padding(.horizontal,8)
        .background(Color.darkGray)
    }
}

