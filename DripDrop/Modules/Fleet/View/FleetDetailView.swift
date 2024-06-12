//
//  FleetDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct FleetDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            info
        }
    }
}

struct FleetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FleetDetailView()
    }
}

extension FleetDetailView {
    var info: some View {
        ScrollView{
            if let vehical = masterDataManager.vehical {
                Text("\(vehical.nickName)")
                Text("\(vehical.make)")
                Text("\(vehical.model)")
                Text("\(String(format:  "%.2f", vehical.miles))")
                Text("\(fullDate(date:vehical.datePurchased))")
                Text("\(vehical.color)")

            }
        }
    }
}
