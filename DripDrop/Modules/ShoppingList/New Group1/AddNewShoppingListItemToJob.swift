//
//  AddNewShoppingListItemToJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//

import SwiftUI

struct AddNewShoppingListItemToJob: View {
    let jobId:String
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            form
        }
    }
}

#Preview {
    AddNewShoppingListItemToJob(jobId:"J1234567")
}

extension AddNewShoppingListItemToJob {
    var form: some View {
        VStack{
            Text("Add New Shopping List Item To Job")
        }
    }
}
