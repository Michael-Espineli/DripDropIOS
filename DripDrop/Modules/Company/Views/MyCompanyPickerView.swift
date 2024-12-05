//
//  MyCompanyPickerView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/30/24.
//

import SwiftUI

struct MyCompanyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @Binding var company : Company

    @State var search:String = ""
    @State var companies:[Company] = []
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
            companyList
//            searchBar
        }
        .padding()
        .task {
            if let user = masterDataManager.user {
                do {
                    try await companyVM.getCompaniesByUserAccessList(userId: user.id )
                    companies = companyVM.listOfCompanies
                } catch {
                    print(error)
                }
            }
        }
    }
}
extension MyCompanyPickerView {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search: ")
            })
        .modifier(SearchTextFieldModifier())
        .padding(8)
        
    }
    var companyList: some View {
        ScrollView{
            Divider()

            ForEach(companies){ datum in
                    Button(action: {
                        company = datum
                        dismiss()
                    }, label: {
                        HStack{
                            Spacer()
                            CompanyCardView(company: datum)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(Color.black)
                        .cornerRadius(5)
                        .padding(2)
                    })
                Divider()
            }
        }
    }
}
