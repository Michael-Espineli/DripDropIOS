//
//  RateSheetDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import SwiftUI

struct RateSheetDetailView: View {
    let rateSheet:RateSheet
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct RateSheetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RateSheetDetailView(rateSheet: RateSheet(id: "", templateId: "", rate: 0, dateImplemented: Date(), status: .active))
    }
}
