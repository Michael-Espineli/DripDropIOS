//
//  FindBusinesses.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI

struct FindBusinesses: View {
    @StateObject var VM : BuisnessViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
    }
    @State var search:String = ""
    @State var selectedCompany:Company? = nil
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                searchBar
                businessList
            }
        }
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.searchForBuisnesses(searchTerm: search)

                    try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    FindBusinesses()
//}

extension FindBusinesses {
    var searchBar: some View {
        HStack{
            TextField(
                text: $search,
                label: {
                    Text("Search For Businesses")
                })
            .onSubmit {
                Task{
                    do {
                        try await VM.searchForBuisnesses(searchTerm: search)
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }
        }
        .modifier(SearchTextFieldModifier())
        .padding(8)
    }
    
    var businessList: some View {
        ScrollView{
            ForEach(VM.companyList){ company in
                if let currentCompany = masterDataManager.currentCompany {
                    if company.id != currentCompany.id {
                        Button(action: {
                            selectedCompany = company
                        }, label: {
                            HStack{
                                CompanyCardView(company: company)
                                if VM.buisnessList.contains(where: {$0.companyId == company.id}) {
                                    Image(systemName: "heart.fill")
                                        .modifier(DismissButtonModifier())
                                } else {
                                    Image(systemName: "heart")
                                        .modifier(AddButtonModifier())
                                }
                                Spacer()
                            }
                        })
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal,16)
        .sheet(item: $selectedCompany, onDismiss: {
            Task{
                if let selectedCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.searchForBuisnesses(searchTerm: search)

                        try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }
        }, content: { company in
            CompanyProfileView(dataService: dataService, company: company)
        })
    }
}
