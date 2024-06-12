//
//  mockChart.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI
import Charts
struct mockChart: View {
    let numbers: [Double]
    
    var body: some View {
        Chart {
            ForEach(Array(numbers.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
            }
        }
    }
}

struct mockChart_Previews: PreviewProvider {
    static var previews: some View {
        mockChart(numbers:[0])
    }
}
