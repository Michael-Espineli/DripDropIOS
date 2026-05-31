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
                    Image(systemName: "questionmark")
                    Spacer()
                    Text("\(template.name)")
                    Spacer()
                }
                
                HStack{
                    Spacer()
                    Text("")
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
        JobTemplateCardView(template: JobTemplate(companyId: "", name: "", createdByUserId: ""))
        
    }
}
