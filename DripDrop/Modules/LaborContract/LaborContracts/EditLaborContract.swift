//
//  EditLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//

import SwiftUI

struct EditLaborContract: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:RepeatingLaborContract,isPresented:Binding<Bool>,isFullScreenCover:Bool){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
        self._isPresented = isPresented
        _isFullScreenCover = State(wrappedValue: isFullScreenCover)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : LaborContractViewModel
    @Binding var isPresented:Bool
    @State var isFullScreenCover:Bool
    //Form
    @State var laborContract:RepeatingLaborContract
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
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}
//
//#Preview {
//    EditLaborContract(dataService: MockDataService(), laborContract: MockDataService.mockLaborContracts.first!)
//}
