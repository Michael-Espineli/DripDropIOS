//
//  InviteDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct InviteDetailView: View {
    var invite:Invite
    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    print("Button does not function")  // DEVELOPER
                }, label: {
                    Text("Edit")

                })
                Spacer()
                Button(action: {
                    print("Button does not function") // DEVELOPER

                }, label: {
                    Text("Delete")
                })
            }
            .padding()
            Text("\(invite.firstName) \(invite.lastName)")
            Text("\(invite.status)")
            HStack{
                
                Text("\(invite.id)")
                    .textSelection(.enabled)
                    .foregroundColor(Color.white)
                    .padding(10)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(5)
                #if os(iOS)
                Button(action: {
                    UIPasteboard.general.setValue("\(invite.id)",forPasteboardType: UTType.plainText.identifier)
                }, label: {
                    VStack{
                        
                        Text("Copy")
                        
                        Image(systemName: "square.fill.on.square.fill")
                    }
                })
                #endif
            }
            Spacer()
        }
    }
}
