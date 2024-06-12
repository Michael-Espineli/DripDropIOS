//
//  WorkLogSnapShot.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/13/24.
//

import SwiftUI

struct WorkLogSnapShot: View {
    @StateObject var workLogVM : WorkLogViewModel
    var body: some View {
        VStack{
            Button(action: {
                
            }, label: {
                Text("Clock In")
            })
            .padding(5)
            .background(Color.poolBlue)
            .cornerRadius(5)

        }
    }
}

#Preview {
    WorkLogSnapShot()
}
