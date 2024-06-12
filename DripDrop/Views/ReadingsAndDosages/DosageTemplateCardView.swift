//
//  DosageTemplateCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/22/24.
//

import SwiftUI

struct DosageTemplateCardView: View {
    let template : DosageTemplate
    var body: some View {
        VStack{
            HStack{
                Text("\(template.name ?? "")")
                Spacer()
                Text("\(template.rate ?? "")")
                Text("\(template.UOM ?? "")")
            }
            .padding(20)
        }
        .padding(5)
        .background(Color.gray.opacity(0.75))
        .cornerRadius(5)
        .padding(10)
    }
}

struct DosageTemplateCardView_Previews: PreviewProvider {
    static var previews: some View {
        DosageTemplateCardView(template: DosageTemplate(id: "", name: "", amount: [], UOM: "", rate: "", linkedItemId: "", strength: 0, editable: true, chemType: "", order: 0))
    }
}
