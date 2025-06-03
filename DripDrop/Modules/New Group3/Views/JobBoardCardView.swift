//
//  JobBoardCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

struct JobBoardCardView: View {
    let jobBoard : JobBoard
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    Text(jobBoard.name)
                    Spacer()
                }
                
                Text(jobBoard.permissionType.rawValue)
                    .padding(8)
                    .background(jobBoard.permissionType == .publicAccess ? Color.poolGreen.opacity(0.75) : Color.poolRed.opacity(0.75))
                    .cornerRadius(8)
                Spacer()
                HStack{
                    Text(jobBoard.region)
                }
            }
            .frame(width:150,height: 150)
        }
        .modifier(ListButtonModifier())
    }
}

//#Preview {
//    JobBoardCardView()
//}
