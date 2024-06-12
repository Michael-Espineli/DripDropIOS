//
//  StoreListView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/28/23.
//
import SwiftUI

struct StoreListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject private var viewModel = StoreViewModel()

    @State var showAddNew = false
    @State var showSearch = false
    @State var searchTerm:String = ""
    var body: some View {
        ZStack{
            ScrollView{
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                        
                    }, label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonTextModifier())
                    })
                    .modifier(DismissButtonModifier())
                }
                ForEach(viewModel.stores){store in
                    NavigationLink(destination: {
                        StoreDetailView(store:store)
                    }, label: {
                        StoreCardView(store: store)
                    })
                }
                .padding()
            }
            VStack{
                Spacer()
                HStack{
                    VStack{
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.green)
                        })
                        .sheet(isPresented: $showAddNew, content: {
                            AddNewVenderView()
                        })
                        .padding()
                        Button(action: {
                            showSearch.toggle()
                        }, label: {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)

                        })
                        .padding()

                    }
                    Spacer()
                }
                if showSearch {
                    HStack{
                        TextField(
                            "CustomerName",
                            text: $searchTerm
                        )
                        .padding()
                        .background(Color.basicFontText.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
            }

        }
        .task{
            if let company = masterDataManager.selectedCompany {
                do {
                    try await viewModel.getAllStores(companyId: company.id)
                } catch {
                    print(error)
                }
            }
            
        }
        .toolbar{
   
            ToolbarItem(){

                NavigationLink{
                    AddNewVenderView()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Store List")
    }
}
