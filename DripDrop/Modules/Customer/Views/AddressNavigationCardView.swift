//
//  AddressNavigationCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/30/23.
//

import SwiftUI

struct AddressNavigationCardView: View {
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
                        Text("\(address.streetAddress)")
                    }
                    .padding(5)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                })
        }
    }

}

