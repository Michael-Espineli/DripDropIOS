//
//  TechPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/30/24.
//


import SwiftUI

struct TechPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var companyUserVM = CompanyUserViewModel()
    
    @Binding var tech : CompanyUser

    @State var search:String = ""
    @State var techs:[CompanyUser] = []
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                   Image(systemName: "xmark")
                })
            }
            techList
            searchBar
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await companyUserVM.getAllCompanyUsers(companyId: company.id)
                    techs = companyUserVM.companyUsers
                }
            } catch {
                print("Error")

            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await companyUserVM.getAllCompanyUsers(companyId: company.id)
                            techs = companyUserVM.companyUsers
                        }
                    } catch {
                        print("Error")

                    }
                }
            } else {
                print("Developer Tech Add Search")
            }
        })
    }
}
extension TechPickerScreen {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search: ")
            })
        .modifier(SearchTextFieldModifier())
        .padding(8)
    }
    var techList: some View {
        ScrollView{
            Divider()

            ForEach(techs){ datum in
                HStack{
                    Spacer()
                    Button(action: {
                        tech = datum
                        dismiss()
                    }, label: {
                        Text("\(datum.userName)")
                    })
                    Spacer()
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(Color.black)
                .cornerRadius(5)
                .padding(2)
                Divider()
            }
        }
    }
}
