//
//  SentLaborContractDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/20/24.
//

import SwiftUI

struct SentLaborContractDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:RepeatingLaborContract){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractViewModel
    
    //Received
    @State var laborContract:RepeatingLaborContract
    
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
                .fullScreenCover(isPresented: $VM.showGenerateLaborContract , onDismiss: {
                    print("on Dismiss")
                    
                }, content: {
                    GenerateRouteFromLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $VM.showGenerateLaborContract,isFullScreenCover: true)
                })
            Text("")
                .fullScreenCover(isPresented: $VM.showEditLaborContract, onDismiss: {
                    print("on Dismiss")
                }, content: {
                    EditLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $VM.showEditLaborContract,isFullScreenCover: true)
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
                    try await VM.onLoadDetailView(companyId: currentCompany.id, laborContractId: laborContract.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
        .onChange(of: masterDataManager.selectedLaborContract, perform: { datum in
            Task{
                if let datum {
                    print("Change In Labor Contract")
                    laborContract = datum
                    VM.notes = laborContract.notes
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.onLoadDetailView(companyId: currentCompany.id, laborContractId: laborContract.id)
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
                        .padding(8)
                        .background(VM.getBackGroundColor(status: LaborContractStatus.accepted))
                        .cornerRadius(8)
                        .foregroundColor(VM.getForeGroundColor(status: LaborContractStatus.accepted))
                }
            }
            HStack{
                Text("Date Sent:")
                    .fontWeight(.bold)
                Text("\(fullDate(date:laborContract.dateSent))")
                Spacer()
            }
            VStack{
                HStack{
                    Text("Start Date: \(fullDate(date: laborContract.startDate))")
                    Spacer()
                }
                HStack{
                    Text("End Date : \(fullDate(date: laborContract.endDate))")
                    Spacer()
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
                        HStack{
                            Text("\((index ?? 0) + 1): \(datum.customerName): \(datum.jobTemplateName) - \(datum.rate, format: .currency(code: "USD").precision(.fractionLength(2))) - \(datum.timesPerFrequency) \(datum.frequency.rawValue)")
                            Spacer()
                            if datum.routeSetUp {
                                Image(systemName: "checkmark.circle")
                                    .modifier(SubmitButtonModifier())
                            } else {
                                Image(systemName: "circle")
                                    .modifier(DismissButtonModifier())
                            }
                            Button(action: {
                                
                            }, label: {
                                Text("More")
                                    .font(.footnote)
                                    .padding(8)
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
                                        Text(id)
                                            .modifier(ListButtonModifier())
                                        RecurringWorkRecurringServicestopCardView(dataService: dataService, recurringServiceStopId: id, laborContract: laborContract)
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
        VStack{
            Text("Terms")
                .fontWeight(.bold)
            ForEach(laborContract.terms,id:\.self){ datum in
                let index = laborContract.terms.firstIndex(of: datum)
                HStack{
                    Text("\((index ?? 0) + 1):")
                    Text(datum.description)
                    Spacer()
                }
            }
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

