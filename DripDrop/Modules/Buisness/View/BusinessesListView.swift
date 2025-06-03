//
//  ContractorsListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BusinessesListView: View {
    @StateObject var VM : BuisnessViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
    }
    
    //Variables
    @State var showFindBusinesses:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            Text("")
                .sheet(isPresented: $showFindBusinesses, onDismiss: {
                    Task{
                        if let selectedCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                            } catch {
                                print("Error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    FindBusinesses(dataService: dataService)
                })
        }
        .navigationTitle("Businesses List")
        .task{
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
        .toolbar{
            Button(action: {
                showFindBusinesses.toggle()
            }, label: {
                Text("Search")
                    .fontDesign(.monospaced)
            })
        }
    }
}

#Preview {
    BusinessesListView(dataService: MockDataService())
}
extension BusinessesListView {
    var list: some View {
        ScrollView{
            ForEach(VM.buisnessList){ business in
                Divider()
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.business(business: business, dataService: dataService), label: {
                        BusinessCardView(business: business)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedCategory = .businesses
                        masterDataManager.selectedBuisness = business
                    }, label: {
                        BusinessCardView(business: business)
                    })
                }
            }
        }
        .padding(.horizontal,8)
        .frame(maxWidth: .infinity)
    }
}
