//
//  EquipmentList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

struct EquipmentList: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var navigationManager : NavigationStateManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject private var equipmentVM : EquipmentViewModel
    init(
        dataService:any ProductionDataServiceProtocol
    ){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
    }
    @State var count:Int = 20
    @State var showFilerOptions:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            icons
            
        }
        .navigationTitle("Equipment")
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await equipmentVM.getAllEquipmentBy25(companyId: company.id)
                } catch {
                    print("[EquipmentList][task]equipmentVM.getAllEquipmentBy25")
                    print(error)
                }
            }
            
        }
    }
}

#Preview {
    EquipmentList(dataService: ProductionDataService())
}
extension EquipmentList {
    var list: some View {
        ScrollView{
            LazyVStack{
                ForEach(equipmentVM.listOfEquipment) { equipment in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.equipmentDetailView(
                            equipment: equipment, dataService: dataService
                        ),label: {
                            EquipmentCardView(equipment: equipment)
                                .modifier(ListButtonModifier())
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedEquipment = equipment
                        }, label: {
                            EquipmentCardView(equipment: equipment)
                                .modifier(ListButtonModifier())
                                .padding(.horizontal,8)
                        })
                    }
                }
            }
        }
        .padding(8)
    }
    
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    /*
                    if let role = masterDataManager.role {
                        if role.permissionIdList.contains("62") {
                            Button(action: {
                                VM.showAddNewEquipment.toggle()
                            }, label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .foregroundColor(Color.white)
                                    .padding(8)
                                    .background(Color.poolGreen)
                                    .cornerRadius(5)
                            })
                            .padding(8)
                        }
                    }
                     */
                    
//                    Button(action: {
//                        showFilerOptions.toggle()
//                    }, label: {
//                        Image(systemName: "slider.horizontal.3")
//                            .font(.headline)
//                            .foregroundColor(Color.white)
//                            .padding(8)
//                            .background(Color.orange)
//                            .cornerRadius(5)
//                    })
//                    .padding(8)
                    
//                    .sheet(isPresented: $showFilerOptions, content: {
//                        VStack{
//                            Text("Filters")
//                            
//                        }
//                        .padding(10)
//                        .presentationDetents([.medium])
//                    })
                    Button(action: {
                        Task{
//                            VM.showSearch = true
                        }
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                    })
                    .padding(8)
                }
            }
        }
    }
}
