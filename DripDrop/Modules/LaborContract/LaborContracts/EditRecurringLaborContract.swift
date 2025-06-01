//
//  EditLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//

import SwiftUI

struct EditRecurringLaborContract: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:ReccuringLaborContract,isPresented:Binding<Bool>,isFullScreenCover:Bool){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
        self._isPresented = isPresented
        _isFullScreenCover = State(wrappedValue: isFullScreenCover)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : RecurringLaborContractViewModel
    @Binding var isPresented:Bool
    @State var isFullScreenCover:Bool
    //Form
    @State var laborContract:ReccuringLaborContract
    var body: some View {
        VStack{
            if isFullScreenCover {
                Button(action: {
                    isPresented.toggle()
                }, label: {
                    Image(systemName: "xmark")
                        .modifier(DismissButtonModifier())
                })
            }
            Text("Edit Recurring Labor Contract")
        }
    }
}
//
//#Preview {
//    EditLaborContract(dataService: MockDataService(), laborContract: MockDataService.mockLaborContracts.first!)
//}
