//
//  AddNewRateSheet.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI

struct AddNewRateSheet: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var companyUserVM = CompanyUserViewModel()
    
    let template:JobTemplate
    
    @State var rate:String = ""
    @State var startDate:Date = Date()
    var body: some View {
        ScrollView{
            details
            form
            button
        }
    }
}

struct AddNewRateSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddNewRateSheet(template: JobTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), rate: "", color: ""))
    }
}

extension AddNewRateSheet {
    var details: some View {
        VStack{
            Text("\(template.name)")
            
        }
    }
    var form: some View {
        VStack{
                TextField(
                    "Rate",
                    text: $rate
                )
                .padding(5)
                .background(Color.gray)
                .foregroundColor(Color.white)
                .cornerRadius(5)
                .keyboardType(.decimalPad)
            HStack{
                Text("Offered Start Date:")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                    
                }
            }
        }
    }
    var button: some View {
        Button(action: {
            Task{
                if let company = masterDataManager.selectedCompany, let companyUser = masterDataManager.companyUser{
                    do {
                        guard let rate = Double(rate) else {
                            print("failed to change rate into Double")
                            return
                        }
                        try await companyUserVM.addCompanyUserRateSheet(companyId: company.id,
                                                                        companyUserId: companyUser.id,
                                                                        rateSheet: RateSheet(id: UUID().uuidString,
                                                                                             templateId: template.id,
                                                                                             rate: rate,
                                                                                             dateImplemented: startDate,
                                                                                             status: .offered))
                    } catch {
                        print(error)
                    }
                    dismiss()
                }
            }
        }, label: {
            Text("Offer")
        })
    }
}
