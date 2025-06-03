//
//  AllCompanyRouteTechStopView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class AllCompanyRouteTechStopViewModel:ObservableObject{

    @Published var isContractedOut:Bool = false
    @Published private(set) var isSameCompany:Bool = true

    @Published private(set) var companyName:String = ""

    func onLoad (companyId:String,companyList: [Company],stops:[RecurringServiceStop],day : String,techId:String){
        
        //Make This Better
        var companyName = ""
        var phrase = ""
        
        var count = 0
        for stop in stops {
            if count == 0 {
                count = count + 1
                if stop.otherCompany {
                    if let contractedCompnyId = stop.contractedCompanyId, let mainCompanyId = stop.mainCompanyId{
                        if companyId == mainCompanyId {
                            if let contractedCompany = companyList.first(where: {$0.id == contractedCompnyId}) {
    //                                Text("Contracted with")
                                phrase = "Contracted with " + contractedCompany.name
                                companyName = contractedCompany.name
                                self.companyName = companyName
                                self.isContractedOut = true
                            }
                        } else {
                            if let contractedCompany = companyList.first(where: {$0.id == contractedCompnyId}) {
    //                                Text("Contracted by")
                                phrase = "Contracted By " + contractedCompany.name
                                companyName = contractedCompany.name
                                self.companyName = companyName
                                self.isContractedOut = false
                            }
                        }
                    }
                }
                
            } else {
                if stop.otherCompany {
                    if let contractedCompnyId = stop.contractedCompanyId, let mainCompanyId = stop.mainCompanyId{
                        if companyId == mainCompanyId {
                            if let contractedCompany = companyList.first(where: {$0.id == contractedCompnyId}) {
    //                                Text("Contracted with")
                                if phrase != "Contracted with " + contractedCompany.name {
                                    self.isSameCompany = false
                                }
                            }
                        } else {
                            if let contractedCompany = companyList.first(where: {$0.id == contractedCompnyId}) {
    //                                Text("Contracted by")
                                if phrase != "Contracted By " + contractedCompany.name {
                                    self.isSameCompany = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
struct AllCompanyRouteTechStopView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM = AllCompanyRouteTechStopViewModel()
    @Binding var showDialog: Bool
    @Binding var selectedDay: String
    @Binding var selectedTechId: String
    
    //Maybe Make these enviromental Variables
    let companyList: [Company]
    let recurringServiceStops : [RecurringServiceStop]
    let basicTechnicanInfo : [BasicTechnicanInfo]
    let techId :String
    let day : String
    var body: some View {
        VStack{

            //Tech Info
            if let technician = basicTechnicanInfo.first(where: {$0.id == techId}) {
                if let company = masterDataManager.currentCompany {
                    if VM.isSameCompany {
                        TechnicianRouteSameCompanyCard(
                            technicianName: technician.techName,
                            isContractedOut: VM.isContractedOut,
                            companyName: VM.companyName,
                            showDialogConfirmation: $showDialog
                        )
                    } else {
                        TechnicianRouteSummaryCardView(
                            technicianName: technician.techName,
                            roleName: technician.roleName,
                            isOtherCompany: company.id != technician.companyId,
                            companyName: technician.companyName,
                            showDialogConfirmation: $showDialog
                        )
                    }
                }
            }
            //Stop info
            if selectedTechId == techId && selectedDay == day {
                ForEach(recurringServiceStops){ rss in
                    VStack{
                        HStack{
                                //                                            Image(systemName: "\(String(order.order)).square.fill")
                            Image(systemName: "\(String(1)).square.fill")
                            Spacer()
                            VStack{
                                HStack{
                                        //                                                    Text("\(order.customerName)")
                                    Text("\(rss.customerName)")
                                        .padding(5)
                                        .background(Color.blue)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(5)
                                    switch rss.frequency {
                                    case .daily:
                                        Text("- Daily")
                                    case .weekDay:
                                        Text("- Week Day")
                                    case .weekly:
                                        Text("- Weekly")
                                    case .monthly:
                                        Text("- Monthly")
                                    case .yearly:
                                        Text("- Annually")
                                    default:
                                        Text("Frequency")
                                    }
                                }
                                HStack{
                                    Text("\(fullDate(date:rss.startDate))")
                                        .font(.footnote)
                                    
                                    Text(" - ")
                                        .font(.footnote)
                                    
                                    if rss.noEndDate {
                                        Text("No End Date")
                                            .font(.footnote)
                                        
                                    } else {
                                        if let endDate = rss.endDate {
                                            Text("\(fullDate(date:endDate))")
                                                .font(.footnote)
                                            
                                        } else  {
                                            Text("No End Date")
                                                .font(.footnote)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                            Button(action: {
                            }, label: {
                                Image(systemName: "pencil")
                                
                            })
                        }
                        Divider()
                        if !VM.isSameCompany {
                            HStack{
                                if rss.otherCompany {
                                    if let contractedCompnyId = rss.contractedCompanyId, let mainCompanyId = rss.mainCompanyId, let company = masterDataManager.currentCompany {
                                        if company.id == mainCompanyId {
                                            if let contractedCompany = companyList.first(where: {$0.id == contractedCompnyId}) {
                                                Text("Contracted with")
                                                    .font(.footnote)
                                                Text(contractedCompany.name)
                                                    .font(.footnote)
                                                    .modifier(CustomerCardModifier())
                                            }
                                        } else {
                                            if let contractedCompany = companyList.first(where: {$0.id == contractedCompnyId}) {
                                                Text("Contracted by")
                                                    .font(.footnote)
                                                Text(contractedCompany.name)
                                                    .font(.footnote)
                                                    .modifier(GreenCardModifier())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(5)
                }
            } else {
                HStack{
                    Spacer()
                    Button(action: {
                        selectedTechId = techId
                        selectedDay = day
                    }, label: {
                        Text("Expand")
                            .modifier(DismissButtonModifier())
                    })
                }
            }
        }
        .onAppear(perform: {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId:currentCompany.id,companyList: companyList, stops: recurringServiceStops, day: day, techId: techId)
            }
        })
    }
}

//#Preview {
//    AllCompanyRouteTechStopView()
//}
