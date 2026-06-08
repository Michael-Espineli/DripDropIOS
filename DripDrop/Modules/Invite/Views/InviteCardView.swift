//
//  InviteCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct InviteCardView: View {
    var invite:Invite
    var body: some View {
        HStack{
            VStack{
                Text("\(invite.firstName) \(invite.lastName)")
                Text(invite.displayStatus)
                    .font(.footnote)
                    .padding(5)
                    .background(InviteStatusValue.isPending(invite.status) ? Color.realYellow:Color.green)
                    .cornerRadius(20)
                
            }
            Spacer()
            Text("\(invite.roleName)")
        }
        .modifier(ListButtonModifier())
        .padding(10)
    }
}
