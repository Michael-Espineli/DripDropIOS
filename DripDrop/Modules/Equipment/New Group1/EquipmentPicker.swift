//
//  EquipmentPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import SwiftUI

struct EquipmentPickerByServiceLocationId: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : EquipmentViewModel
    
    @Binding var equipment : Equipment
    @State var serviceLocationId : String

    init(dataService:any ProductionDataServiceProtocol,serviceLocationId:String,equipment:Binding<Equipment>){
        _VM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        self._equipment = equipment
        _serviceLocationId = State(wrappedValue: serviceLocationId)
    }
    
    @State var search:String = ""
    
    @State var equipmentList:[Equipment] = []
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{

                    searchBar
                BodyOfWaterList
                    
                
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.getAllEquipmentFromServiceLocationId(companyId: company.id, serviceLocationId: serviceLocationId)
                    if VM.listOfEquipment.count == 1 {
                        equipment = VM.listOfEquipment[0]
                        dismiss()
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
extension EquipmentPickerByServiceLocationId {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search...")
            })
        .modifier(SearchTextFieldModifier())
    }

    var BodyOfWaterList: some View {
        ScrollView{
            ForEach(VM.listOfEquipment){ datum in
                
                Button(action: {
                    equipment = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Text("\(datum.name) - \(datum.category.rawValue)")
                        Spacer()
                        if equipment == datum {
                            Image(systemName: "checkmark.cirlce.fill")
                                .foregroundColor(Color.poolGreen)
                        }
                    }
                    .padding(.horizontal,8)
                    .foregroundColor(Color.basicFontText)
                })
                
                Divider()
            }
        }
    }
}
