//
//  ContactInfo.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//

import SwiftUI

struct ContactInfo: View {
    let contact:Contact
    var body: some View {
        VStack{
            HStack{
                Text("Name:")
                    .bold(true)
                Text("\(contact.name)")
                
                Spacer()
            }
            HStack{
                Text("Phone Number:")
                    .bold(true)
                Text("\(contact.phoneNumber)")
                
                Spacer()
            }
            HStack{
                Text("Email:")
                    .bold(true)
                Text("\(contact.email)")
                
                Spacer()
            }
            HStack{
                Text("Notes:")
                    .bold(true)
                if let notes = contact.notes {
                    Text("\(notes)")
                }
                Spacer()
            }
        }
        .modifier(ListButtonModifier())
        .padding(8)
    }
}
//
//#Preview {
//    ContactInfo()
//}
