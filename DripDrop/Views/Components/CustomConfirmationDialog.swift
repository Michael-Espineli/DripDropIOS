//
//  CustomConfirmationDialog.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/27/24.
//

import SwiftUI

struct CustomConfirmationDialog: View {
    @Environment(\.dismiss) private var dismiss
    let actions: [String:()->()]
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                ForEach(Array(actions.enumerated()),id: \.offset) { key,action in
                    Button(action: {
                        action.value()
//                        print("help")
//                        action()
                        dismiss()
                    }, label: {
                        HStack{
                            Text(action.key.description)
                                .padding(16)
                        }
                        .foregroundColor(Color.basicFontText)
                        .frame(maxWidth: .infinity)
                        .background(Color.poolBlue)
                        .padding(8)

                    })
                    Divider()
                }
            }
        }
    }
}
func action1(){
    print("Preview help")
}
#Preview {
    CustomConfirmationDialog(actions:["Action":action1])

}
