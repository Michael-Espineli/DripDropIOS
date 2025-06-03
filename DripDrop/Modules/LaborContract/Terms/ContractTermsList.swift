//
//  ContractTermsList.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/25.
//

import SwiftUI

struct ContractTermsList: View {
    let contractTerms : [ContractTerms]
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Terms")
                    .fontWeight(.bold)
                ForEach(contractTerms,id:\.self){ datum in
                    let index = contractTerms.firstIndex(of: datum)
                    HStack{
                        Text("\((index ?? 0) + 1):")
                        Text(datum.description)
                        Spacer()
                    }
                }
            }
            .padding(8)
        }
    }
}

#Preview {
    ContractTermsList(contractTerms: [])
}
