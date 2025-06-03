//
//  ShoppingListItemStatusPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/27/25.
//

import SwiftUI

struct ShoppingListItemStatusPicker: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init(dataService:any ProductionDataServiceProtocol,status:Binding<ShoppingListStatus>){
        self._status = status
    }
    @Binding var status : ShoppingListStatus
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ForEach(ShoppingListStatus.allCases){ datum in
                    Button(action: {
                        status = datum
                        dismiss()
                    }, label: {
                        HStack{
                            Spacer()
                                Text("\(datum.rawValue)")
                            Spacer()
                        }
                        .padding(.horizontal,8)
                        .foregroundColor(Color.basicFontText)
                    })
                    Divider()
                }
            }
        }
    }
}

//#Preview {
//    ShoppingListItemStatusPicker()
//}
