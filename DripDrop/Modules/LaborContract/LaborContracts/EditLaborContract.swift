//
//  EditLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//

import SwiftUI

struct EditLaborContract: View {
    //Init
    init(
        dataService:any ProductionDataServiceProtocol,
        laborContract:LaborContract,
        isPresented:Binding<Bool>,
        isFullScreenCover:Bool
    ){
        _laborContract = State(wrappedValue: laborContract)
        self._isPresented = isPresented
        _isFullScreenCover = State(wrappedValue: isFullScreenCover)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Binding var isPresented:Bool
    @State var isFullScreenCover:Bool
    //Form
    @State var laborContract:LaborContract
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
            Text("Edit Labor Contract")
        }
    }
}
//
//#Preview {
//    EditLaborContract(dataService: MockDataService(), laborContract: MockDataService.mockLaborContracts.first!)
//}
