
//
//  EditShoppingListItem.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/2/26.
//

import SwiftUI
@MainActor
final class EditTaskViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct EditTaskView: View {
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Edit Shopping List Item")
            }
        }
    }
}

#Preview {
    EditShoppingListItem()
}
