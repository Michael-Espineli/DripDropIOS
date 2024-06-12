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
//            list
            icons
            
        }
            .task {
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await equipmentVM.getAllEquipmentBy25(companyId: company.id)
                    } catch {
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
                            dataService: dataService
                        ),label: {
                            EquipmentCardView(equipment: equipment)
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedEquipment = equipment
                            navigationManager.routes.append(Route.equipmentDetailView(dataService:dataService))
                        }, label: {
                            EquipmentCardView(equipment: equipment)
                        })
                    }
                    Divider()
                }
                ProgressView()
                    .onAppear(perform: {
                        Task{
                            if let company = masterDataManager.selectedCompany {
                                do {
                                    print("Get Next 25")
                                    try await equipmentVM.getAllEquipmentBy25(companyId: company.id)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    })
            }
        }
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        showFilerOptions.toggle()
                    }, label: {
                        
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.orange)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                                )
                    })
                    
                    .sheet(isPresented: $showFilerOptions, content: {
                        VStack{
                            Text("Filters")
                            
                        }
                        .padding(10)
                        .presentationDetents([.medium])
                    })
                }
                .padding(20)
            }
        }
    }
}
