//
//  DosageTemplateCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/22/24.
//

import SwiftUI

struct DosageTemplateCardView: View {
    let template : SavedDosageTemplate
    var body: some View {
        VStack{
            HStack{
                Text("\(template.name ?? "")")
                Spacer()
                Text("\(template.rate ?? "")")
                Text("\(template.UOM ?? "")")
            }
            .padding(8)
        }
        .modifier(ListButtonModifier())

    }
}

struct DosageTemplateCardView_Previews: PreviewProvider {
    static var previews: some View {
        DosageTemplateCardView(template: SavedDosageTemplate(id: "",dosageTemplateId: "", name: "", amount: [], UOM: "", rate: "", linkedItemId: "", strength: 0, editable: true, chemType: "", order: 0))
    }
}
