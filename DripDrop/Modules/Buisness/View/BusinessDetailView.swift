//
//  ContractorDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BuisnessDetailView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @State var contractor:Company
    init( dataService:any ProductionDataServiceProtocol,contractor:Company){
        _contractor = State(wrappedValue: contractor)
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        detail
                            .padding(.leading,20)

                    }, header: {
                        header
                    })
                })
                .padding(.top,20)
                .clipped()
            }
        }
        .toolbar {
            NavigationLink(destination: {
                Text("Create Update Logic")
            }, label: {
                    Text("Update")
            })
        }
    }
}

#Preview {
    BuisnessDetailView(dataService: MockDataService(), contractor: Company(id: "", ownerId: "", name: "", photoUrl: "", dateCreated: Date()))
}

extension BuisnessDetailView {
    var header: some View {
        VStack{
            Text("\(contractor.name ?? "")")
            
            HStack{
                Text("Out Standing: $ 2,765.50")
                Spacer()
                NavigationLink(value: Route.compileInvoice(dataService: dataService), label: {
                    Text("Send Invoice")
                        .modifier(BasicButtonModifier())

                })
            }
        }
        .padding(.horizontal,10)
        .frame(maxWidth: .infinity)
        .background(Color.listColor)
    }
    var detail: some View {
        VStack{
            Text("Open Contracts")
            Divider()
            VStack{
                HStack{
                    Text("Start Date: \(fullDate(date: Date()))")
                    Spacer()
                }
                HStack{
                    let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
                    Text("Valid Until : \(fullDate(date: endDate))")
                    Spacer()
                }
            }
            VStack{
                Text("Rate Sheet")
                Divider()
                Text("Cleanings")
                HStack{
                    Text("Accounts")
                    Spacer()
                    Text("26")
                    NavigationLink(destination: {
                        Text("Add List Of Clients They are contracted to complete")
                    }, label: {
                        HStack{
                            Text("Details")
                            Image(systemName: "arrow.right")
                        }
                    })
                }
                HStack{
                    Text("Commerical")
                    Spacer()
                    Text("$ 15")
                }
                HStack{
                    Text("Residential")
                    Spacer()
                    Text("$ 25")
                }
    
            }
            NavigationLink(destination: {
                Text("Create Complaint Logic")
            }, label: {
                    Text("Complain")
            })
        }
        .frame(maxWidth: .infinity)
    }
   
}
