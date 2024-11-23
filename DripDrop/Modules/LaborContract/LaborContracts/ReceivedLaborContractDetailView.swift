//
//  ReceivedLaborContractDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/20/24.
//


import SwiftUI

struct ReceivedLaborContractDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:RepeatingLaborContract){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractViewModel

    //Form
    @State var laborContract:RepeatingLaborContract
    @State var selectedLaborContract:RepeatingLaborContract? = nil

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
                .fullScreenCover(isPresented: $generateLaborContract, onDismiss: {
                    print("on Dismiss")

                }, content: {
                    GenerateRouteFromLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $generateLaborContract,isFullScreenCover: true)
                })
            Text("")
                .fullScreenCover(isPresented: $showEditLaborContract, onDismiss: {
                    print("on Dismiss")
                }, content: {
                    EditLaborContract(dataService: dataService, laborContract: laborContract,isPresented: $showEditLaborContract,isFullScreenCover: true)
                })
        }
        .fontDesign(.monospaced)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            notes = laborContract.notes
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
                    notes = laborContract.notes
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
                            Text("\((index ?? 0) + 1): ")
                            Text("\(datum.customerName) - \(datum.jobTemplateName) - \(datum.frequency.rawValue) - \(datum.rate, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            Spacer()
                            if datum.routeSetUp {
                                Image(systemName: "checkmark.circle")
                                    .modifier(SubmitButtonModifier())
                            } else {
                                Image(systemName: "circle")
                                    .modifier(DismissButtonModifier())
                            }
                        }
                        HStack{
                            ForEach(datum.recurringServiceStopIdList,id:\.self){ id in
                                Text(id)
                                    .modifier(ListButtonModifier())
                            }
                            Spacer()
                        }
                        .font(.footnote)
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
            if let company = masterDataManager.currentCompany {
                if !laborContract.receiverAcceptance || !laborContract.senderAcceptance {
                    if company.id != laborContract.receiverId && company.id == laborContract.senderId{
                        HStack{
                            if !laborContract.receiverAcceptance {
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
                                        try await VM.markLaborContractAsAcceptedByReceiver(companyId: company.id, laborContract: laborContract)
                                        alertMessage = "Accepted Succsefully"
                                        showAlert  = true
                                        print(showAlert)
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
                        Button(action: {
                            self.showEditLaborContract.toggle()
                        }, label: {
                            Text("Offer Updated Contract")
                                .modifier(AddButtonModifier())
                        })
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
