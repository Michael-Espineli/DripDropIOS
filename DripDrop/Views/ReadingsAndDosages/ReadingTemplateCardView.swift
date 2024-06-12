//
//  ReadingTemplateCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/22/24.
//

import SwiftUI

struct ReadingTemplateCardView: View {
    let template : ReadingsTemplate

    var body: some View {
        VStack{
            HStack{
                Text("\(template.name)")
                Spacer()
            }
            .padding(20)
        }
        .padding(5)
        .background(Color.gray.opacity(0.75))
        .cornerRadius(5)
        .padding(10)
    }
}

struct ReadingTemplateCardView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingTemplateCardView(template: ReadingsTemplate(id: "", name: "", amount: [], UOM: "", chemType: "", linkedDosage: "", editable: true, order: 0 , highWarning: 0, lowWarning: 0))
    }
}
