//
//  ReportCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/17/24.
//

import SwiftUI

struct ReportCardView: View {
    let report:ReportType
    var body: some View {
        HStack{
            Image(systemName: "\(report.systemImage)")
            Spacer()
            Text("\(report.title)")
        }
        .padding(8)
        .modifier(ListButtonModifier())
    }
}
