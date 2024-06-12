//
//  BodyOfWaterDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI
import MapKit

struct BodyOfWaterDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    //ViewModels
    //received Variables
  
    init(dataService:any ProductionDataServiceProtocol,bodyOfWater:BodyOfWater){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _bodyOfWater = State(wrappedValue: bodyOfWater)
    }
    @StateObject var equipmentVM : EquipmentViewModel
    @State var bodyOfWater:BodyOfWater

    //Variables for use
    @State var equipmentList:[Equipment] = []
    @State var selectedEquipment:Equipment? = nil
    @State var showEditSheet:Bool = false
    @State var showAddSheet:Bool = false
    @State var isLoading:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if isLoading {
                    VStack{
                        Spacer()
                        LoadingSpinner()
                        Spacer()
                    }
                } else {
                    Divider()
                        edit
                    
                    info
                    equipment
                }
            }
        }
        .task{
            isLoading = true
            do {
                if let bodyOfWater = masterDataManager.selectedBodyOfWater {
                    try await equipmentVM.getAllEquipmentFromBodyOfWater(companyId: masterDataManager.selectedCompany!.id, bodyOfWater: bodyOfWater)
                    equipmentList = equipmentVM.listOfEquipment
                    if equipmentList.count != 0 {
                        selectedEquipment = equipmentList.first!
                        masterDataManager.selectedEquipment = equipmentList.first!
                    }
                }
            } catch{
                print("Error")
            }
            isLoading = false
        }
        .onChange(of: selectedEquipment, perform: { datum in
            Task{
                isLoading = true
               sleep(1)
                isLoading = false
            }
        })

    }
}
extension BodyOfWaterDetailView {
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
                if let BOW = masterDataManager.selectedBodyOfWater {
                    EditBodyOfWaterView(dataService:dataService, bodyOfWater: BOW)
                }
            })
        }
        .padding()
    }
    var info: some View {
        VStack{
            if let bodyOfWater = masterDataManager.selectedBodyOfWater {
                VStack{
                    HStack{
                        Text("Name: \(bodyOfWater.name)")
                        Spacer()
                    }
                }
                VStack{
                    HStack{
                        Text("gallons: \(bodyOfWater.gallons)")
                        Spacer()
                    }

                }
                VStack{
                    HStack{
                        Text("material: \(bodyOfWater.material)")
                        Spacer()
                    }
                }
            }
        }
    }
    var equipment: some View {
        VStack{
            Divider()
            Text("Equipment Detail View")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    Button(action: {
                        showAddSheet = true
                    }, label: {
                        Image(systemName: "plus.square.on.square")
                            .font(.headline)
                            .padding(8)
                            .foregroundColor(Color.basicFontText)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                    .sheet(isPresented: $showAddSheet, content: {
                        AddEquipmentView(dataService: dataService, bodyOfWater: bodyOfWater)
                    })
                if equipmentList.count == 0 {
                    Button(action: {
                        showAddSheet = true
                    }, label: {
                        Text("Add First Body Of Water")
                    })
                } else {
                    ForEach(equipmentList){ equipment in
                        Button(action: {
                            Task{
                                selectedEquipment = nil
                                selectedEquipment = equipment
                                masterDataManager.selectedEquipment = equipment
                            }
                        }, label: {
                            HStack{
                                if equipment.status != .operational {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color.poolRed)
                                }
                                Text(equipment.category.rawValue)
                                    .padding(5)
                                    .background(selectedEquipment == equipment ? Color.accentColor : Color.gray)
                                    .foregroundColor(selectedEquipment == equipment ? Color.white : Color.white)
                                    .cornerRadius(5)
                            }
                        })
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    }
  
                }
                
            }
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            if selectedEquipment == nil {
                Text("Please select an Equipment")
            } else {
            
                    EquipmentDetailView(dataService:dataService)
                
            }
        }
    }
    var image: some View {
        ZStack{
            VStack{
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 150)
            }
            .padding(0)
        }
    }
}
struct BodyOfWaterDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        
        BodyOfWaterDetailView(dataService: dataService, bodyOfWater: BodyOfWater(id: UUID().uuidString,
                                                                                 name: "",
                                                                                 gallons: "",
                                                                                 material: "",
                                                                                 customerId: "",
                                                                                 serviceLocationId: ""))
        
    }
}


