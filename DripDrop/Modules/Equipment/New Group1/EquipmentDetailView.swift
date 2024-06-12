//
//  EquipmentDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI
import MapKit

struct EquipmentDetailView: View {
    //ViewModels
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var equipmentVM : EquipmentViewModel
    
    
    init(dataService:any ProductionDataServiceProtocol){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        
    }
    //received Variables
    
    
    //Variables for use
    @State var showEditSheet:Bool = false
    @State var showAddSheet:Bool = false
    @State var showRepairSheet:Bool = false
    @State var showNewPart:Bool = false
    
    @State var isLoading:Bool = false
    let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 300))
    ]
    @State var equipmentParts:[EquipmentPart] = [
        
    ]
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            if isLoading {
                ProgressView()
            } else {
                VStack{
                    Divider()
                        edit
                    
                    if UIDevice.isIPhone{
                        VStack {
                            info
                            
                            repairHistory
                        }
                    } else {
                        HStack {
                            info
                            Divider()
                            repairHistory
                        }
                    }
                 
                }
            }
        }
        .task {
            do {
                if let company = masterDataManager.selectedCompany, let equipment = masterDataManager.selectedEquipment {
                    try await equipmentVM.getAllPartsByEquipment(companyId: company.id, equipmentId: equipment.id)
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: masterDataManager.selectedEquipment, perform: { datum in
            Task{
                
                if let eq = datum {
                    do {
                        if let company = masterDataManager.selectedCompany {
                            try await equipmentVM.getAllPartsByEquipment(companyId: company.id, equipmentId: eq.id)
                        }
                    } catch {
                        print("Error")
                    }
                }
            }
        })
        
    }
    func getNextServiceDate(lastServiceDate:Date,every:String,frequency:String) -> Date {
        let calendar = Calendar.current
        
        var date = Date()
        
        
        if let repeatingEvery = Int(every) {
            switch frequency {
            case "Day":
                print("Day")
                date = calendar.date(byAdding: .day, value: repeatingEvery, to: lastServiceDate)!

            case "Week":
                print("Week")

                let week = repeatingEvery * 7
                date = calendar.date(byAdding: .day, value: week, to: lastServiceDate)!

            case "Month":
                print("Month")

                date = calendar.date(byAdding: .month, value: repeatingEvery, to: lastServiceDate)!

            case "Year":
                print("Year")

                date = calendar.date(byAdding: .year, value: repeatingEvery, to: lastServiceDate)!

            default:
                print("None")
            }
        } else {
            print("Error Converting Number")
        }
        return date
    }
}
extension EquipmentDetailView {
    var edit: some View {
        HStack{
            
            Spacer()
            Button(action: {
                showEditSheet = true
            }, label: {
             Text("Edit")
                    .padding(8)
                    .foregroundColor(Color.basicFontText)
                    .background(Color.poolBlue)
                    .cornerRadius(8)

            })
            .sheet(isPresented: $showEditSheet, content: {
                if let EQ = masterDataManager.selectedEquipment {
                    EditEquipmentView(dataService: dataService, equipment: EQ)
                }
            })
        }
        .padding()
    }
    var repairHistory: some View {
        VStack{
            ZStack{
               
                HStack{
                    Text("Part List")
                        .font(.headline)
                    Button(action: {
                        showNewPart.toggle()
                    }, label: {
                        Text("Add Part")
                    })
                    .foregroundColor(Color.reverseFontText)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                    .padding(5)
                    .sheet(isPresented: $showNewPart, content: {
                        Text("Add New Part View")
                    })
                }
            }
            ForEach(equipmentVM.partList) { part in
                HStack{
                    Text("Part: \(part.name)")
                    Text("Date Replaced: \(fullDate(date:part.date))")
                    Button(action: {
                        showRepairSheet.toggle()
                    }, label: {
                        Text("Detail")
                    })
                    .sheet(isPresented: $showRepairSheet, content: {
                        EquipmentPartDetailView(equipmentPart: part)
                    })
                }
            }
        }
    }
    var info: some View {
        VStack{
            if let selectedEquipment = masterDataManager.selectedEquipment {
                VStack{
                    HStack{
                        Text("Category: ")
                        
                        
                        Text("\(selectedEquipment.category)")
                        Spacer()
                    }
                    HStack{
                        Text("Make: ")
                        
                        
                        Text("\(selectedEquipment.make)")
                        Spacer()
                    }
                    HStack{
                        Text("Model: ")
                        
                        Text("\(selectedEquipment.model)")
                        Spacer()
                    }
                }
                VStack{
                    HStack{
                        Text("Date Installed: ")
                        
                        Text("\(fullDate(date: selectedEquipment.dateInstalled))")
                        
                        Spacer()
                    }
                    HStack{
                        Text("Status: ")
                        
                        Text("\(selectedEquipment.status)")
                        Spacer()
                    }
                    if selectedEquipment.needsService {
                        if let serviceDate = selectedEquipment.lastServiceDate {
                            if let every = selectedEquipment.serviceFrequencyEvery {
                                if let frequency = selectedEquipment.serviceFrequency {
                                    if let nextServiceDate = selectedEquipment.nextServiceDate {
                                        HStack{
                                            Text("Last Service Date: ")
                                            
                                            Text("\(fullDate(date:serviceDate))")
                                            Spacer()
                                        }
                                        HStack{
                                            Text("Service Frequency: ")
                                            
                                            Text("\(every) \(frequency)")
                                            Spacer()
                                        }
                                        HStack{
                                            Text("Next Service Date: ")
                                            
                                            Text("\(fullDate(date: nextServiceDate))")
                                                .padding(5)
                                            
                                                .background(nextServiceDate > Date() ? Color.poolGreen : Color.poolRed)
                                                .cornerRadius(5)
                                                .foregroundColor(Color.basicFontText)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    HStack{
                        Text("Notes: ")
                        
                        Text("\(selectedEquipment.notes)")
                        Spacer()
                    }
                    
                }
            }
        }
    }
    
}



