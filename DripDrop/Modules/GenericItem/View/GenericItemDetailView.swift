//
//  GenericItemDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/27/24.
//

import SwiftUI

struct GenericItemDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    var body: some View {
        VStack{
            if let genericItem = masterDataManager.selectedGenericItem {
                Text("\(genericItem.commonName)")
            }
        }
    }
}

struct GenericItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GenericItemDetailView()
    }
}
