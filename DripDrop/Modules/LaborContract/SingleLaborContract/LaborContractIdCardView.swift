//
//  LaborContractIdCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/24/25.
//




import SwiftUI
@MainActor
final class LaborContractIdCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var laborContract : LaborContract? = nil
    func onLoad(companyId:String,laborContractId:String) {
        Task{
            do {
                self.laborContract = try await dataService.getLaborContract(laborContractId: laborContractId)
            } catch {
                print(error)
            }
        }
    }
}
struct LaborContractIdCardView: View{
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : LaborContractIdCardViewModel

    @State var laborContractId: String
    init(dataService:any ProductionDataServiceProtocol,laborContractId: String) {
        _laborContractId = State(wrappedValue: laborContractId)
        _VM = StateObject(wrappedValue: LaborContractIdCardViewModel(dataService: dataService))
    }
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            if let laborContract = VM.laborContract, let currentCompany = masterDataManager.currentCompany {
                HStack{
                    VStack(spacing: 0){
                        HStack{
                            VStack{
                                if currentCompany.id == laborContract.senderId {
                                    //Display Receiver Info for sender to see
                                    HStack{
                                        Text(laborContract.receiverName )
                                    }
                                } else {
                                    //Display Sender Info for receiver to see
                                    HStack{
                                        Text(laborContract.senderName )
                                    }
                                }
                                HStack{
                                    Spacer()
                                    Text(laborContract.status.rawValue)
                                        .modifier(YellowButtonModifier())
                                    
                                }
                            }
                        }
                        HStack{
                            Spacer()
                            Text("Something:")
                                .font(.footnote)
                        }
                    }
                }
                .modifier(ListButtonModifier())
            }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id, laborContractId: laborContractId)
            }
        }
    }
}

