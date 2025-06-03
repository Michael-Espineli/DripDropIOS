//
//  SheetTester.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/22/24.
//

import SwiftUI

struct SheetTester: View {
    @State var showSheet:Bool = false
    var body: some View {
        VStack{
            Text("I am not a sheet")
            Button(action: {
                showSheet.toggle()
            }, label: {
                Text("Show Sheet")
                    .padding(5)
                    .background(Color.poolBlue)
                    .cornerRadius(5)
                    .padding(5)
            })
        }
            .sheet(isPresented: $showSheet, content: {
                Text("I am a sheet")
            })
    }
}

#Preview {
    SheetTester()
}
