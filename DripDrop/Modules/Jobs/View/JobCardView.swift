//
//  JobCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI

struct JobCardView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    let job:Job
    var body: some View {
        VStack(alignment: .leading){
            switch masterDataManager.mainScreenDisplayType {
            case .compactList:
                compact
            case .preview:
                status
                info
            case .fullPreview:
                status
                info
                monies
            }
        }
        .frame(maxWidth: .infinity )
        .modifier(ListButtonModifier())
        .padding(.horizontal,8)
        .padding(.vertical,4)
    }
    
}
extension JobCardView {
    var compact: some View {
        
        
        VStack{
            HStack{
                Text("\(job.internalId)")
                Text("\(job.customerName)")
                    .lineLimit(1)
            }
            HStack{
                Text("Ops:")
                Text("\(job.operationStatus.rawValue)")
                    .lineLimit(1)
                    .padding(5)
                    .background(getColorOperation(status:job.operationStatus))
                    .foregroundColor(getForgroundColorOperation(status: job.operationStatus))
                    .cornerRadius(5)
                Spacer()
                Text("Billing:")
                Text("\(job.billingStatus.rawValue)")
                    .lineLimit(1)
                    .padding(5)
                    .background(getColorOperation(status:job.operationStatus))
                    .foregroundColor(getForgroundColorOperation(status: job.operationStatus))
                    .cornerRadius(5)
            }
            .font(.footnote)
        }
    }
    var status: some View {
        HStack{
            Text("\(job.internalId )")
            Spacer()
            HStack{
                Text("\(job.operationStatus.rawValue)")
                    .padding(5)
                    .background(getColorOperation(status:job.operationStatus))
                    .foregroundColor(getForgroundColorOperation(status: job.operationStatus))
                    .cornerRadius(5)
                Text("\(job.billingStatus.rawValue)")
                    .padding(5)
                    .background(getColorBilling(status:job.billingStatus))
                    .foregroundColor(getForgroundColorBilling(status:job.billingStatus))
                    .cornerRadius(5)
            }
        }
    }
    var info: some View {
        HStack{
            Text("\(job.customerName)")
            Text("\(job.type)")
        }
    }
    var monies: some View {
        HStack{
            Text("Rate: \(job.rate, format: .currency(code: "USD").precision(.fractionLength(0)))")
            Text("Profit: \(job.profit, format: .currency(code: "USD").precision(.fractionLength(0)))")
            Text("\(shortDate(date:job.dateCreated))")
        }
    }
    
    func getColorOperation(status:JobOperationStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .estimatePending:
            color = Color.poolRed
        case .unscheduled:
            color = Color.orange
        case .scheduled:
            color = Color.yellow
        case .inProgress:
            color = Color.yellow
        case .finished:
            color = Color.poolGreen
        }
        return color
    }
    func getForgroundColorOperation(status:JobOperationStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .estimatePending:
            color = Color.poolWhite
        case .unscheduled:
            color = Color.poolWhite
        case .scheduled:
            color = Color.poolBlack
        case .inProgress:
            color = Color.poolBlack
        case .finished:
            color = Color.poolWhite
        }
        return color
    }
    func getColorBilling(status:JobBillingStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .draft:
            color = Color.poolRed
        case .estimate:
            color = Color.poolBlue
        case .accepted:
            color = Color.poolGreen
        case .inProgress:
            color = Color.poolYellow
        case .invoiced:
            color = Color.poolBlue
        case .paid:
            color = Color.green
        }
        return color
    }
    func getForgroundColorBilling(status:JobBillingStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .draft:
            color = Color.poolWhite
        case .estimate:
            color = Color.poolWhite
        case .accepted:
            color = Color.poolWhite
        case .inProgress:
            color = Color.poolBlack
        case .invoiced:
            color = Color.poolWhite
        case .paid:
            color = Color.poolBlack
        }
        return color
    }
}
