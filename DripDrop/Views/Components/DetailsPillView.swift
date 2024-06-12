//
//  DetailsPillView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct JobDescriptors:Identifiable,Codable{
    var id = UUID().uuidString
    var iconName: String? = nil
    var emoji: String? = nil
    var text : String

}

struct DetailsPillView: View {
    var iconName: String? = "heart.fill"
    var emoji: String? = ""
    var text: String = ""
    var body: some View {
        HStack{
            if let iconName {
                Image(systemName: iconName)
            } else if let emoji {
                Text(emoji)
            }
            Text(text)
        }
        .font(.callout)
        .fontWeight(.medium)
        .padding(.vertical,6)
        .padding(.horizontal,12)
        .foregroundColor(Color.white)
        .background(Color.poolBlue)
        .cornerRadius(32)
    }
}

struct DetailsPillView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsPillView()
    }
}
