//
//  BodyOfWaterPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct BodyOfWaterPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    
    @Binding var bodyOfWater : BodyOfWater
    @State var serviceLocationId : String

    init(dataService:any ProductionDataServiceProtocol,serviceLocationId:String,bodyOfWater:Binding<BodyOfWater>){
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        self._bodyOfWater = bodyOfWater
        _serviceLocationId = State(wrappedValue: serviceLocationId)
    }
    
    @State var search:String = ""
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    
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
                    try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: ServiceLocation(id: serviceLocationId, nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: ""))
                    bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                    if bodyOfWaterList.count == 1 {
                        bodyOfWater = bodyOfWaterList.first!
                        dismiss()
                    }
                }
            } catch {
                print(error)
            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                
                bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                
                
            } else {
                
                bodyOfWaterVM.filterBodiesOfWater(bodiesOfWaterList: bodyOfWaterVM.bodiesOfWater, term: term)
                bodyOfWaterList = bodyOfWaterVM.filteredBodiesOfWater
                print("Received \(bodyOfWaterList.count) Customers")
                
            }
        })
    }
}
extension BodyOfWaterPicker {
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
            ForEach(bodyOfWaterList){ datum in
                
                Button(action: {
                    bodyOfWater = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Text("\(bodyOfWater.name)")
                        Spacer()
                    }
                    .padding(.horizontal,8)
                    .foregroundColor(Color.basicFontText)
                })
                
                Divider()
            }
        }
    }
}
