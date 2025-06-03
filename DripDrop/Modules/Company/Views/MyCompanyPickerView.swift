//
//  MyCompanyPickerView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/30/24.
//

import SwiftUI
@MainActor
final class MyCompanyPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var search:String = ""
    @Published var companies:[Company] = []
    
    func onLoad(userId:String) async throws {
        let accessList = try await dataService.getAllUserAvailableCompanies(userId: userId)
        print("Received List of \(accessList.count) Companies available to Access")
        var listOfCompanies:[Company] = []
        for access in accessList{
            let company = try await dataService.getCompany(companyId: access.id)// access id is company id
            listOfCompanies.append(company)
        }
        self.companies = listOfCompanies
    }
}
struct MyCompanyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : MyCompanyPickerViewModel
    init(dataService: any ProductionDataServiceProtocol,company:Binding<Company>) {
        _VM = StateObject(wrappedValue: MyCompanyPickerViewModel(dataService: dataService))
        self._company = company
    }
    @Binding var company : Company
    var body: some View {
        VStack{
            companyList
            searchBar
        }
        .padding()
        .task {
            if let user = masterDataManager.user {
                do {
                    try await VM.onLoad(userId: user.id )
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
            text: $VM.search,
            label: {
                Text("Search: ")
            })
        .modifier(SearchTextFieldModifier())
        .padding(8)
        
    }
    var companyList: some View {
        ScrollView{
            ForEach(VM.companies){ datum in
                Button(action: {
                    company = datum
                    dismiss()
                }, label: {
                    CompanyCardView(company: datum)
                })
                Divider()
            }
        }
    }
}
