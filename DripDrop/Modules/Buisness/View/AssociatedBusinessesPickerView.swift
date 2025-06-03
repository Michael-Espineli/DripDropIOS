//
//  AssociatedBusinessesPickerView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

@MainActor
final class AssociatedBusinessesPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var buisnessList: [AssociatedBusiness] = []
    @Published var searchTerm: String = ""
    @Published var showFindBusinesses: Bool = false

    
    func onLoad(companyId:String) async throws {
        self.buisnessList = try await dataService.getAssociatedBusinesses(companyId: companyId)
    }
}
struct AssociatedBusinessesPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : AssociatedBusinessesPickerViewModel

    init( dataService:any ProductionDataServiceProtocol, business:Binding<AssociatedBusiness>){
        _VM = StateObject(wrappedValue: AssociatedBusinessesPickerViewModel(dataService: dataService))
        self._business = business
    }
    @Binding var business : AssociatedBusiness
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            search
        }
        .task{
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: selectedCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    AssociatedBusinessesPickerView()
//}
extension AssociatedBusinessesPickerView {
    var list: some View {
        ScrollView{
            ForEach(VM.buisnessList){ datum in
                Divider()
                Button(action: {
                    business = datum
                    dismiss()
                }, label: {
                    BusinessCardView(business: datum)
                })
            }
            Button(action: {
                VM.showFindBusinesses.toggle()
            }, label: {
                Text("Find New Business")
                    .modifier(AddButtonModifier())
            })
            .sheet(isPresented: $VM.showFindBusinesses, onDismiss: {
                Task{
                    if let selectedCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.onLoad(companyId: selectedCompany.id)
                        } catch {
                            print("Error")
                            print(error)
                        }
                    }
                }
            }, content: {
                FindBusinesses(dataService: dataService)
            })
        }
        .padding(.horizontal,8)
        .frame(maxWidth: .infinity)
    }
    
    var search: some View {
        VStack{
            Spacer()
            TextField(
                text: $VM.searchTerm,
                label: {
                    Text("Search...")
                })
            .modifier(SearchTextFieldModifier())
            .padding(8)
        }
    }
}
