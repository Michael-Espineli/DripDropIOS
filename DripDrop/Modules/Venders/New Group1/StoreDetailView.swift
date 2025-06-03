//
//  StoreDetailView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/28/23.
//



import SwiftUI
import MapKit
struct StoreDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var storeVM = StoreViewModel()

    @State var store: Vender

    var body: some View {
        ScrollView{
            Button(action: {
                print("Add Directions to ")
            }, label: {
                image
            })
            
            info
                .padding()
        }
        .toolbar{
            ToolbarItem(){

                NavigationLink(destination:{
                    EditStoreView()
                }, label: {
                    Image(systemName: "pencil")
                        .modifier(EditButtonTextModifier())
                })
                .modifier(EditButtonModifier())
                
            }
        }
        .task {
            do {
                try await storeVM.getStoreInfo(companyId: masterDataManager.currentCompany!.id, vender: store)
            } catch {
                print("Failed to get store Info")
            }
        }
        .navigationTitle("Vender")
    
    }
}
extension StoreDetailView {
    var info: some View {
        VStack{
            Text(store.name ?? "No Name")
            Text(store.id)
            HStack{
                Text("Items Purchased")
                Spacer()
                Text("\(String(storeVM.itemsPurchasedAtVender ?? 0))")
            }
            HStack{
                Text("Money Spent")
                Spacer()
                Text("\(String(storeVM.moneySpentAtVender ?? 0))")
            }
            HStack{
                Text("Data Base Items")
                Spacer()
                Text("\(String(storeVM.dataBaseItemsAtVender ?? 0))")
            }
        }
    }
    var image: some View {
        ZStack{
            VStack{
                BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: store.address.latitude, longitude: store.address.longitude))
                    .frame(height: 150)
            }
            .padding(0)
        }
    }
}
