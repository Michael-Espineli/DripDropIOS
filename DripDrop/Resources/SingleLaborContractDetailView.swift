//
//  SingleLaborContractDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/30/24.
//

import SwiftUI

struct SingleLaborContractDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:LaborContract){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    @Environment(\.dismiss) private var dismiss
 
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractViewModel

    //Form
    @State var laborContract:LaborContract
    @State var selectedLaborContract:LaborContract? = nil

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
                .sheet(isPresented: $generateLaborContract,
                       onDismiss: {
                            print("on Dismiss")
                        },
                       content: {
                    GenerateJobFromLaborContract(
                        dataService: dataService,
                        laborContract: laborContract,
                        isPresented: $generateLaborContract,
                        isFullScreenCover: true
                    )
                })
            Text("")
                .sheet(isPresented: $showEditLaborContract, onDismiss: {
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
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadDetailView(companyId: currentCompany.id, laborContract: laborContract)
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
extension SingleLaborContractDetailView{
    var header: some View {
        VStack(alignment:.leading){
            if let company = masterDataManager.currentCompany {
                if company.id != laborContract.senderId {
                    receiverHeader
                    
                }
                if company.id != laborContract.receiverId {
                    senderHeader
                    
                    
                }
            }
            Divider()


        }
        .padding(.vertical,8)
        .padding(.horizontal,8)
        .foregroundColor(Color.poolWhite)
        .background(Color.darkGray)
    }
    
    var receiverHeader: some View {
        VStack{
            HStack{
                Text("From:")
                    .fontWeight(.bold)
                Text("\(laborContract.senderName)")
                Spacer()
            }
            HStack{
                Text("Customer:")
                    .fontWeight(.bold)
                Text("\(laborContract.customerName)")
                Spacer()
            }
            HStack{
                Text("Date Sent:")
                    .fontWeight(.bold)
                Text("\(fullDate(date:laborContract.dateSent))")
                Spacer()
            }
            VStack{
                if VM.status == .accepted {
                    HStack{
                        Text("Date Accepted:")
                            .fontWeight(.bold)
                        Text("\(fullDate(date: Date()))")
                        Spacer()
                    }
                } else if VM.status == .rejected {
                    HStack{
                        Text("Date Rejected:")
                            .fontWeight(.bold)
                        Text("\(fullDate(date: Date()))")
                        Spacer()
                    }
                } else if VM.status == .accepted {
                    HStack{
                        Text("Last Date To Accept:")
                            .fontWeight(.bold)
                        Text("\(fullDate(date: laborContract.lastDateToAccept))")
                        Spacer()
                    }
                }
            }
            HStack{
                switch laborContract.status {
                case .pending, .accepted:
                    Text("\(laborContract.status.rawValue)")
                        .modifier(YellowButtonModifier())

                case .rejected:
                    Text("\(laborContract.status.rawValue)")
                        .modifier(DismissButtonModifier())

                case .finished:
                    Text("\(laborContract.status.rawValue)")
                        .modifier(SubmitButtonModifier())

                }
                Spacer()
                if laborContract.isInvoiced {
                    Text("Invoiced")
                        .modifier(SubmitButtonModifier())
                } else {
                    Text("Not Invoiced")
                        .modifier(YellowButtonModifier())
                }
            }
            .font(.footnote)
        }
    }
    
    var senderHeader: some View {
        VStack{
            HStack{
                Text("To:")
                    .fontWeight(.bold)
                Text("\(laborContract.receiverName)")
                Spacer()
            }
            HStack{
                Text("Customer:")
                    .fontWeight(.bold)
                Text("\(laborContract.customerName)")
                Spacer()
            }
            HStack{
                Text("Date Sent:")
                    .fontWeight(.bold)
                Text("\(fullDate(date:laborContract.dateSent))")
                Spacer()
            }
            VStack{
                if VM.status == .accepted {
                    HStack{
                        Text("Date Accepted:")
                            .fontWeight(.bold)
                        Text("\(fullDate(date: Date()))")
                        Spacer()
                    }
                } else if VM.status == .rejected {
                    HStack{
                        Text("Date Rejected:")
                            .fontWeight(.bold)
                        Text("\(fullDate(date: Date()))")
                        Spacer()
                    }
                } else if VM.status == .accepted {
                    HStack{
                        Text("Last Date To Accept:")
                            .fontWeight(.bold)
                        Text("\(fullDate(date: laborContract.lastDateToAccept))")
                        Spacer()
                    }
                }
            }
            HStack{
                switch laborContract.status {
                case .pending, .accepted:
                    Text("\(laborContract.status.rawValue)")
                        .modifier(YellowButtonModifier())

                case .rejected:
                    Text("\(laborContract.status.rawValue)")
                        .modifier(DismissButtonModifier())

                case .finished:
                    Text("\(laborContract.status.rawValue)")
                        .modifier(SubmitButtonModifier())

                }
                Spacer()
                if laborContract.isInvoiced {
                    Text("Invoiced")
                        .modifier(SubmitButtonModifier())
                } else {
                    Text("Not Invoiced")
                        .modifier(YellowButtonModifier())
                }
            }
            .font(.footnote)
        }
    }
    
    var details: some View {
        VStack(alignment:.leading){
            recurringWorkView
            Divider()
            HStack{
                Text("Terms")
                Spacer()
    //                    Text("\(laborContract.recurringWork.count)")
                NavigationLink(value: Route.contractTermsList(dataService: dataService, termsList: laborContract.terms), label: {
                    HStack{
                        Text("Details")
                        Image(systemName: "arrow.right")
                    }
                })
            }
         
            Divider()
            if let currentCompany = masterDataManager.currentCompany {
                HStack{
                    Text("Notes:")
                        .fontWeight(.bold)
                }
                TextField("Notes", text: $notes, prompt: Text("Notes"), axis: .vertical)
                    .modifier(TextFieldModifier())
                    .lineLimit(5)
                    .disabled(currentCompany.id != laborContract.senderId)
            }
        }
        .padding(.horizontal,16)
        .frame(maxWidth: .infinity)
    }
    var recurringWorkView: some View {
        VStack{
            VStack{
                Text("Tasks")
                    .fontWeight(.bold)
                ForEach(VM.laborContractTaskList){ datum in
                    let index = VM.laborContractTaskList.firstIndex(of: datum)
                    VStack{
                        HStack{
                            Text("\((index ?? 0) + 1): ")
                            VStack{
                                Text("\(datum.name)")
                                Text("\(datum.type.rawValue)")
                                Text("\(datum.contractedRate/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            }
                            Spacer()
                            if datum.jobIsCreated {
                                Image(systemName: "checkmark.circle")
                                    .modifier(SubmitButtonModifier())
                            } else {
                                Image(systemName: "circle")
                                    .modifier(DismissButtonModifier())
                            }
                        }
                        HStack{
                            Text(datum.status.rawValue)
                            Spacer()
                        }
                        HStack{
                            ScrollView(.horizontal) {
                                
                                ForEach(datum.receiverJobId,id:\.self){ id in
                                    Text(id.internalId)
                                        .modifier(ListButtonModifier())
                                }
                            }
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
                if !VM.receiverAcceptance || !VM.senderAcceptance {
                    if company.id != laborContract.receiverId && company.id == laborContract.senderId{
                        senderFooterPreAcceptance
                    } else if company.id != laborContract.senderId && company.id == laborContract.receiverId {
                        receiverFooterPreAcceptance
                    } else {
                        Text("Developer: Why are you looking at someone elses Labor Contract")
                    }
                } else {
                    // Both Sides have accepted Contract
                    if company.id != laborContract.senderId && company.id == laborContract.receiverId {
                        receiverFooterPostAcceptance
                    } else if company.id == laborContract.senderId && company.id != laborContract.receiverId {
                        senderFooterPostAcceptance
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
    
    var senderFooterPreAcceptance: some View {
        HStack{
            if let company = masterDataManager.currentCompany {

            if !VM.receiverAcceptance {
                Button(action: {
                    Task{
                        do {
                            try await VM.deleteLaborContract(
                                companyId: company.id,
                                laborContract: laborContract,
                                taskList: VM.laborContractTaskList
                            )
                            dismiss()
                        } catch {
                            print("error")
                            print(error)
                        }
                    }
                },
                       label: {
                    Text("Delete Contract")
                        .lineLimit( 2, reservesSpace: true)
                        .modifier(DismissButtonModifier())
                })
            }
            Spacer()
            Button(action: {
                
                showEditLaborContract.toggle()
            }, label: {
                Text("Revise Contract")
                    .lineLimit( 2, reservesSpace: true)
                    .modifier(AddButtonModifier())
            })
        }
    }
    }
    
    var senderFooterPostAcceptance: some View {
        VStack{
            HStack{
                Spacer()
                Text("Cancel?")
            }
        }
    }
    
    var receiverFooterPreAcceptance: some View {
        HStack{
            if let company = masterDataManager.currentCompany {
                Button(action: {
                    Task{
                        do {
                                //Accept Contract
                            try await VM.markLaborContractAsAcceptedByReceiver(companyId: company.id, laborContract: laborContract)
                            alertMessage = "Accepted Succsefully"
                            showAlert  = true
                            print(alertMessage)
                        } catch {
                            print("error")
                            print(error)
                        }
                    }
                }, label: {
                    Text("Accept")
                        .lineLimit( 2, reservesSpace: true)
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
                        .lineLimit( 2, reservesSpace: true)
                        .modifier(DismissButtonModifier())
                })
                .padding(.horizontal,8)
                Spacer()
                Button(action: {
                    showEditLaborContract.toggle()
                }, label: {
                    Text("Revise Contract")
                        .lineLimit( 2, reservesSpace: true)
                        .modifier(AddButtonModifier())
                })
            }
        }
    }
    
    var receiverFooterPostAcceptance: some View {
        VStack{
            HStack{
                if VM.job == nil {
                    Button(action: {
                        selectedLaborContract = laborContract
                        generateLaborContract.toggle()
                    }, label: {
                        Text("Generate Job From Contract")
                            .modifier(AddButtonModifier())
                    })
                } else {
//                    Text("nil JOb")
                }
                if laborContract.status == LaborContractStatus.finished {
                    if !laborContract.isInvoiced {
                        if let associatedBusiness = VM.associatedBusiness {
                            NavigationLink(value: Route.createBulkInvoice(dataService: dataService, associatedBusiness: associatedBusiness), label: {
                                Text("Send Bulk Invoice")
                                    .modifier(AddButtonModifier())
                                
                            })
                        }
                        Spacer()
                        NavigationLink(value: Route.createLaborContractInvoice(dataService: dataService, laborContract: laborContract), label: {
                            Text("Send Invoice")
                                .modifier(AddButtonModifier())
                        })
                    } else {
                        if let invoice = VM.invoice {
                            HStack{
                                NavigationLink(value: Route.accountsReceivableDetail(invoice: invoice, dataService: dataService), label: {
                                    Text(invoice.internalIdenifier)
                                        .modifier(AddButtonModifier())
                                })
                            }
                        } else {
//                            Text("Invoice Nil")
                        }
                    }
                } else {
//                    Text("Finish Job")
                }
            }
        }
    }
}
