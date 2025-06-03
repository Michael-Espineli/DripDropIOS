//
//  CompanyNameCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/19/24.
//

import SwiftUI

struct CompanyNameCardView: View {
    init(dataService: any ProductionDataServiceProtocol,companyId:String){
        _VM = StateObject(wrappedValue: CompanyCardViewModel(dataService: dataService))
        _companyId = State(wrappedValue: companyId)
    }
    @StateObject var VM : CompanyCardViewModel
    @State var companyId:String
    var body: some View {
        HStack{
            if let company = VM.company {
                Text(company.name)
                    .modifier(CustomerCardModifier())
            }
        }
            .task {
                if companyId != "" {
                    do {
                        try await VM.onLoad(companyId: companyId)
                    } catch {
                        print(error)
                        print("error")
                    }
                }
            }
    }
}

#Preview {
    CompanyNameCardView(dataService: MockDataService(), companyId: "")
}
