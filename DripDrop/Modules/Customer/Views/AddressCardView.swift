//
//  AddressCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct AddressCardView: View {
    let address : Address
    var body: some View {
        ZStack{
            Button(action: {

                let address = "\(address.streetAddress) \(address.city) \(address.state) \(address.zip)"
                
                let urlText = address.replacingOccurrences(of: " ", with: "?")
                
                let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                
                if UIApplication.shared.canOpenURL(url!) {
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
            }, label: {
                HStack{
                    Image(systemName: "house.fill")
                    VStack{
                        Text("\(address.streetAddress)")
                        HStack{
                            Text("\(address.state)")
                            Text("\(address.city)")
                            Text("\(address.zip)")
                        }
                    }
                }
                .padding(5)
                .background(Color.gray)
                .foregroundColor(Color.white)
                .cornerRadius(8)
            })
        }
    }

}
