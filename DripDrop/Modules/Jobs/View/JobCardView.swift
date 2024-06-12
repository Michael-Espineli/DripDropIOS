//
//  JobCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI

struct JobCardView: View {
    let job:Job
    var body: some View {
        HStack{
            Text("\(job.id)")

            VStack{
                HStack{
                    Text("\(job.customerName)")
                    Text("\(job.type)")
                }
                HStack{
                    Text("\(job.operationStatus.rawValue)")
                    Text("\(job.billingStatus.rawValue)")
                }
                HStack{
                    Text("Rate: \(job.rate, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    Text("Profit: \(job.profit, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    Text("\(shortDate(date:job.dateCreated))")
                }
            }
        }
    }
}
