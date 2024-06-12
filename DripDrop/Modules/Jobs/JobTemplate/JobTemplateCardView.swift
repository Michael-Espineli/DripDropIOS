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
                }
                HStack{
                    Spacer()
                    Text("\(template.type ?? "")")
                        .font(.footnote)
                }
                .padding()
            }
            .padding(5)
            .background(Color.blue)
            .cornerRadius(10)
            .foregroundColor(Color.white)
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
