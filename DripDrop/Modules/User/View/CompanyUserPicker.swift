//
//  CompanyUserPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//


import SwiftUI

struct CompanyUserPicker: View {
    
    //Init
    init(dataService:any ProductionDataServiceProtocol,companyUser:Binding<CompanyUser>){
        _VM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
        self._companyUser = companyUser
    }
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : TechListViewModel
    
    //Received
    @Binding var companyUser : CompanyUser
    
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            jobList
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.getActiveCompanyUsers(companyId: company.id)
                }
            } catch {
                print("Error")
                
            }
        }
    }
}
extension CompanyUserPicker {

    var jobList: some View {
        ScrollView{
            ForEach(VM.companyUsers){ datum in
                Button(action: {
                    companyUser = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        
                        Text("\(datum.userName) - \(datum.roleName)")
                        
                        Spacer()
                        if datum == companyUser {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.poolGreen)
                        }
                    }
                    .modifier(ListButtonModifier())
                })
                .padding(8)
                
            }
        }
        .padding(16)
    }
}

