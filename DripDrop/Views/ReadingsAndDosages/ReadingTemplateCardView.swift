//
//  ReadingTemplateCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/22/24.
//

import SwiftUI

struct ReadingTemplateCardView: View {
    let template : SavedReadingsTemplate

    var body: some View {
        VStack{
            HStack{
                Text("\(template.name)")
                Spacer()
            }
            .padding(8)
        }
        .modifier(ListButtonModifier())
    }
}

struct ReadingTemplateCardView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingTemplateCardView(template: SavedReadingsTemplate(id: "",readingsTemplateId: "", name: "", amount: [], UOM: "", chemType: "", linkedDosage: "", editable: true, order: 0 , highWarning: 0, lowWarning: 0))
    }
}
