//
//  CompileInvoice.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI

struct CompileInvoice: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var VM : TechInvoiceViewModel



    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: TechInvoiceViewModel(dataService: dataService))
    }
    
    let lastInvoiceDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State var showCompanyChangeSheet : Bool = false
    @State var showDetailSheet : Bool = false

    
    @State var company:Company = Company(id: "")
    @State var billableCompany:Company = Company(id: "")
    
    @State var invoiceTerms:AcountingTermsTypes = .net15
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        summary
                    }, header: {
                        header
                    })
                })
            }
            .padding(.top,20)
            .clipped()
        }
        .task {
            if let selectedCompany = masterDataManager.selectedCompany, let user = masterDataManager.user, let companyUser = masterDataManager.companyUser {
                company = selectedCompany
                do {
                    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

                    try await VM.onInitialLoad(companyId: selectedCompany.id, userId: user.id, startDate: startDate, endDate: Date())
                } catch {
                    print(error)
                }
            } else {
                //If no Company available, Return to previous screen
                dismiss()
            }
        }
        .onChange(of: company, perform: { company in
            Task{
                if let user = masterDataManager.user, let companyUser = masterDataManager.companyUser {
                    do {
                        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

                        try await VM.onInitialLoad(companyId: company.id, userId: user.id, startDate: startDate, endDate: Date())
                    } catch {
                        print(error)
                    }
                } else {
                    //If no Company available, Return to previous screen
                    dismiss()
                }
            }
        })
    }
}

struct CompileInvoice_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        CompileInvoice(dataService: dataService)
    }
}
extension CompileInvoice {
    var summary: some View {
        VStack{
            HStack{
                Text("Summary")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showDetailSheet.toggle()
                }, label: {
                    HStack{
                        Text("Details")
                        Image(systemName: "arrow.right")
                        
                    }
        
                })
                .sheet(isPresented: $showDetailSheet, content: {
                    ScrollView{
                        ForEach(VM.serviceStops) { stop in
                            ServiceStopCardViewSmall(serviceStop: stop)
                        }
                    }
                })
            }
            Picker("", selection: $invoiceTerms) {
                Text("Pick tech").tag("Tech")
                ForEach(AcountingTermsTypes.allCases,id: \.self) { terms in
                    Text(terms.rawValue).tag(terms)
                }
            }
            
            VStack{
                ForEach(VM.stripeLineItems){ lineItem in
                    HStack{
                        Text("\(lineItem.description)")
                        Spacer()
                        Text("\(lineItem.total) X")
                        Text("$ \(String(format:"%2.f",Double(lineItem.induvidualCost)/100))")
                        Text(" = $ \(String(format:"%2.f",Double(lineItem.induvidualCost*lineItem.total)/100))")
                    }
                }
            }
            Button(action: {
                Task {
                    if let company = masterDataManager.selectedCompany,let total = VM.invoiceTotal {
                        if VM.stripeLineItems.count != 0 {
                            do {
                                try await VM.sendInvoice(
                                    companyId: company.id,
                                    invoice: StripeInvoice(
                                        id: UUID().uuidString,
                                        internalIdenifier: UUID().uuidString,//DEVELOPER CHANGE
                                        senderId: company.id,
                                        senderName: company.name ?? "",
                                        receiverId: billableCompany.id,
                                        receiverName: billableCompany.name ?? "",
                                        dateSent: Date(),
                                        total: Int(total),
                                        terms: invoiceTerms,
                                        paymentStatus: .unpaid,
                                        paymentType: .check,
                                        paymentRefrence: "",
                                        lineItems: VM.stripeLineItems
                                    )
                                )
                            } catch {
                                print(error)
                            }
                        } else {
                            print("Line Item Count Empty")
                        }
                    }
                }
            },
                   label: {
                HStack{
                    Text("Send")
                    if let total = VM.invoiceTotal {
                        Text("Total: \(String(format:"%2.f",Double(total)/100))")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .clipShape(Capsule())
                .padding(.horizontal,20)
            })
        }
        .padding(EdgeInsets(top: 20, leading: 6, bottom: 0, trailing: 6))
        .fontDesign(.monospaced)
        .foregroundColor(Color.basicFontText)
    }
    var header: some View {
        VStack{
            HStack{
                if let company = masterDataManager.selectedCompany {
                    
                    Text("Current Company \(company.name ?? "")")
                }
                Spacer()
                Button(action: {
                    showCompanyChangeSheet.toggle()
                }, label: {
                    HStack{
                            Text("\(company.name ?? "")")
                        Image(systemName: "gobackward")
                    }
                        .padding(8)
                        .background(Color.poolBlue)
                        .cornerRadius(8)
                })
                .sheet(isPresented: $showCompanyChangeSheet, content: {
                    CompanyPickerScreen(company: $company)
                })
            }
            Text("Last Invoice Date: \(fullDate(date:lastInvoiceDate))")
        }
        .background(Color.listColor)
        .fontDesign(.monospaced)
        .foregroundColor(Color.basicFontText)
    }
}
