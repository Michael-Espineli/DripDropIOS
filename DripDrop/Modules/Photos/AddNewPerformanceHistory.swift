//
//  AddNewPerformanceHistory.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import SwiftUI

struct AddNewPerformanceHistory: View {
    @StateObject var performaceReviewVM : PerformaceHistoryViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager

    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _receivedCompanyUser = State(wrappedValue: companyUser)
        _performaceReviewVM = StateObject(wrappedValue:PerformaceHistoryViewModel(dataService: dataService))
    }
    @State var receivedCompanyUser:CompanyUser

    @State var description:String = ""
    @State var performaceHistoryType:PerformaceHistoryType = .kudo
    @State var photoUrls:[DripDropStoredImage] = []

    var body: some View {
        VStack{
            info
            submitButton
        }
    }
}

//#Preview {
//    AddNewPerformanceHistory()
//}
extension AddNewPerformanceHistory {
    var info: some View {
        VStack{
            Text("AddNewPerformanceHistory")
            HStack{
                Picker("Type", selection: $performaceHistoryType) {
                    ForEach(PerformaceHistoryType.allCases,id:\.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            HStack{
                Text("Description")
                    .font(.headline)
                
                TextField(
                    "Description",
                    text: $description
                )
                .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                Spacer()
            }
            
            PhotoStoredContent(selectedStoredImages: $photoUrls)
        }
    }
    var submitButton: some View {
        Button(action: {
            Task{
                do {
                    if let selectedCompany = masterDataManager.currentCompany {
                        try await performaceReviewVM.createNewPerformanceReview(
                            companyId: selectedCompany.id,
                            companyUserId: receivedCompanyUser.id,
                            performaceHistory: PerformaceHistory(
                                id: UUID().uuidString,
                                userId: receivedCompanyUser.id,
                                userName: receivedCompanyUser.userName,
                                date: Date(),
                                description: description,
                                photoUrls: photoUrls,
                                performaceHistoryType: performaceHistoryType
                            )
                        )
                    }
                } catch {
                    print("Error")
                    print(error)
                }
            }
        },
               label: {
            Text("Submit")
                .modifier(SubmitButtonModifier())
        })
    }
}
