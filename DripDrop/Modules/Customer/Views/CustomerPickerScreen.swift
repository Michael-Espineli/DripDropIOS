//
//  CustomerPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/12/24.
//

import SwiftUI

struct CustomerPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var customerVM : CustomerViewModel
    @Binding var customer : Customer
    
    init(dataService:any ProductionDataServiceProtocol,customer:Binding<Customer>){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        
        self._customer = customer
    }
    
    @State var search:String = ""
    @State var customers:[Customer] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    .padding(16)
                }
                customerList
                searchBar
            }
        }
        .task {
            do {
                if let company = masterDataManager.selectedCompany {
                    try await customerVM.filterAndSortSelected(companyId: company.id, filter: .active, sort: .firstNameHigh)
                    customers = customerVM.customers
                }
            } catch {
                print("Error")
                
            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
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
                        if let company = masterDataManager.selectedCompany {
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
    }
}
extension CustomerPickerScreen {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search: ")
            })
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(8)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.basicFontText)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)

        
    }
    var customerList: some View {
        ScrollView{
            ForEach(customers){ datum in
                
                Button(action: {
                    customer = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        if datum.displayAsCompany {
                            Text("\(datum.company ?? "\(datum.firstName) \(datum.lastName)")")
                        } else {
                            Text("\(datum.firstName) \(datum.lastName)")
                        }
                        
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
