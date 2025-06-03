//
//  JobTemplateCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateCardView: View {
    var template:JobTemplate
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    Image(systemName: template.typeImage ?? "questionmark")
                    Spacer()
                    Text("\(template.name)")
                    Spacer()
                    if let locked = template.locked {
                        Image(systemName: locked ? "lock.fill" : "lock.open.fill")
                    }
                }
                
                HStack{
                    Spacer()
                    Text("\(template.type ?? "")")
                        .font(.footnote)
                }
                Rectangle()
                    .fill(Color[template.color ?? ""])
                    .frame(height: 1)
            }
            .modifier(ListButtonModifier())
        }
    }
}

struct JobTemplateCardView_Previews: PreviewProvider {
    static var previews: some View {
        JobTemplateCardView(template:JobTemplate(id: "",
                                                 name: "",
                                                 type: "Repair",
                                                 typeImage:"gear",
                                                 dateCreated: Date(),
                                                 rate: "150",
                                                 color: "red"))
    }
}
