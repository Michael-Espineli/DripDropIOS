//
//  EditRateSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/15/24.
//

import SwiftUI

struct EditRateSheet: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var companyUserVM = CompanyUserViewModel()
    
    let template:JobTemplate
    let rateSheet: RateSheet
    
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

struct EditRateSheet_Previews: PreviewProvider {
    static var previews: some View {
        EditRateSheet(template: JobTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), rate: "", color: ""), rateSheet: RateSheet(id: "", templateName: "", templateId: "", rate: 0, dateImplemented: Date(), status: .active, laborType: .hour))
    }
}

extension EditRateSheet {
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
                if let company = masterDataManager.currentCompany, let companyUser = masterDataManager.companyUser{
                    do {
                        guard let rate = Double(rate) else {
                            print("failed to change rate into Double")
                            return
                        }
                        try await companyUserVM.addCompanyUserRateSheet(companyId: company.id,
                                                                        companyUserId: companyUser.id,
                                                                        rateSheet: RateSheet(id: UUID().uuidString, 
                                                                                             templateName: template.name,
                                                                                             templateId: template.id,
                                                                                             rate: rate,
                                                                                             dateImplemented: startDate,
                                                                                             status: .offered,
                                                                                             laborType: .hour))
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
