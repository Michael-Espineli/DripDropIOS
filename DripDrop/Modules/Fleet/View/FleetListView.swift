//
//  FleetListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct FleetListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @State var showSearch:Bool = false
    @State var searchTerm:String = ""
    @StateObject var fleetVM : FleetViewModel

    init(dataService:ProductionDataService){
        _fleetVM = StateObject(wrappedValue: FleetViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            list
            icons
        }
        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await fleetVM.readFleetList(companyId: company.id)
                } catch {
                    print("Fleet Error")
                }
            }
        }
    }
}

struct FleetListView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        FleetListView(dataService: dataService)
    }
}
extension FleetListView {
    var list: some View {
        VStack{
            ScrollView{
                Divider()
                ForEach(fleetVM.listOfVehicals){ vehical in
                    VehicleCardView(vehical: vehical)
                    Divider()
                }
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

                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color.white)
                            )
                        }
                        
                       
                    })
                    .padding(10)
    
                            Button(action: {

                            }, label: {
                                ZStack{
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.green)
                                }
                            })

                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                        }
                    })
                    .padding(10)

                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
                        text: $searchTerm
                    )
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                }
            }
            
        }

    }
}
