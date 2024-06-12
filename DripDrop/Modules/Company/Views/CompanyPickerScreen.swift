//
//  CompanyPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI

struct CompanyPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject private var companyVM = CompanyViewModel()
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
        ///Develper Work on this Later
        /*
         
        .onChange(of: search, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = navigationManager.selectedCompany {
                            try await customerVM.filterAndSortSelected(companyId: company.id, filter: .active, sort: .firstNameHigh)
                            customers = customerVM.customers
                        }
                    } catch {
                        print("Error")

                    }
                }
            } else {
                Task{
                    do {
                        if let company = navigationManager.selectedCompany {
                            try await customerVM.filterCustomerList(filterTerm: term, customers: customerVM.customers)
                            customers = customerVM.filteredCustomers
                            print("Received \(customers.count) Customers")

                        }
                    } catch {
                        print("Error")
                    }
                }
            }
        })
         */
    }
}
extension CompanyPickerScreen {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search: ")
            })
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.basicFontText)
        
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
                            Text("\(datum.name ?? "")")
                        
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
