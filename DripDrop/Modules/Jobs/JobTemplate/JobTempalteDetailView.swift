//
//  JobTemplateDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateDetailView: View {
    var template:JobTemplate
    var body: some View {
        ZStack{
            ScrollView{
                VStack{
                    ZStack{
                        Rectangle()
                            .fill(Color[template.color ?? "blue"])
                            .frame(height: 4)
                        HStack{
                            Image(systemName: template.typeImage ?? "questionmark")
                            Spacer()
                            Text("\(template.name)")
                                .font(.title)
                            Spacer()
                        }
                    }
                    Text("\(template.type ?? "")")
                    Text("\(fullDate(date:template.dateCreated) )")
                    Text("\(template.rate ?? "")")
                    Text("\(template.type ?? "")")
                    Text("\(template.color ?? "")")
                }
            }
        }
    }
}

struct JobTemplateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        JobTemplateDetailView(template:JobTemplate(id: "",
                                                 name: "",
                                                 type: "Repair",
                                                 typeImage:"gear",
                                                 dateCreated: Date(),
                                                 rate: "150",
                                                 color: "red"))
    }
}
