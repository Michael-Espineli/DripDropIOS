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
                Text("\(invite.status)")
                    .font(.footnote)
                    .foregroundColor(invite.status == "Pending" ? Color.realYellow:Color.green)
            }
            Spacer()
            Text("\(invite.roleName)")
        }
        .padding(10)
    }
}
