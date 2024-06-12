//
//  Managment.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//


import SwiftUI

struct Managment: View {
    
    let data = (1...100).map { "Item \($0)" }

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    let recentActivity: [Route] = []

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    items
                }
            }
        }
        
    }
}

struct Managment_Previews: PreviewProvider {
    static var previews: some View {
        Managment()
    }
}
extension Managment {
    var items: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
        }
    }    
}

