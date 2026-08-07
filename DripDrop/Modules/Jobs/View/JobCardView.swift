
//  JobCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI

struct JobCardView: View {

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    let job: Job
    
    @State private var unresolvedCommentCount: Int = 0

    var body: some View {

        HStack(spacing: 0) {

            // Status color bar (match RepairRequestCardView)
            Rectangle()
                .fill(getColorOperation(status: job.operationStatus))
                .frame(width: 5)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            HStack(spacing: 14) {

                // Icon (match RepairRequestCardView)
                ZStack {
                    Circle()
                        .fill(getColorOperation(status: job.operationStatus).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "doc.text")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(getColorOperation(status: job.operationStatus))
                }

                VStack(alignment: .leading, spacing: 6) {

                    // Top row
                    HStack {
                        Text(job.customerName)
                            .foregroundStyle(.primary)
                            .font(.headline)
                            .lineLimit(2)

                        Spacer()

                        // Right-side status chips
                        VStack(spacing: 8) {
                            StatusChip(
                                text: job.operationStatus.rawValue,
                                color: getColorOperation(status: job.operationStatus)
                            )
                            StatusChip(
                                text: job.billingStatus.rawValue,
                                color: getColorBilling(status: job.billingStatus)
                            )
                        }
                    }

                    // Meta row
                    HStack(spacing: 10) {
                        Text("\(job.internalId)")
                        Text("•")
                        Text(shortDate(date: job.dateCreated))
                        Text("•")
                        Text(job.type)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if unresolvedCommentCount > 0 {
                        unresolvedCommentsBadge
                    }

                    // Conditional rows (keep same functionality)
                    switch masterDataManager.mainScreenDisplayType {
                    case .compactList:
                        EmptyView()

                    case .preview:
                        infoRow
                            .padding(.top, 2)

                    case .fullPreview:
                        infoRow
                            .padding(.top, 2)
                        moneyRow
                    }
                }

                Spacer()
            }
            .padding(.leading,8)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .task(id: job.id) {
            await loadUnresolvedCommentCount()
        }
    }
}

extension JobCardView {
    
    var unresolvedCommentsBadge: some View {
        Label(
            "\(unresolvedCommentCount) unresolved \(unresolvedCommentCount == 1 ? "comment" : "comments")",
            systemImage: "text.bubble.fill"
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12), in: Capsule())
        .accessibilityLabel("\(unresolvedCommentCount) unresolved job comments")
    }

    var infoRow: some View {
        HStack(spacing: 12) {
            Label(shortDate(date: job.dateCreated), systemImage: "calendar")
            Spacer()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    var moneyRow: some View {
        HStack {
            Text("Rate \(job.rate, format: .currency(code: "USD").precision(.fractionLength(0)))")
            Spacer()
            Text("Profit \(job.profit, format: .currency(code: "USD").precision(.fractionLength(0)))")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    
    func loadUnresolvedCommentCount() async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }
        
        do {
            let comments = try await dataService.getWorkOrderComments(
                companyId: companyId,
                workOrderId: job.id
            )
            unresolvedCommentCount = comments.filter { !$0.resolved }.count
        } catch {
            print("[JobCardView][loadUnresolvedCommentCount] \(error)")
            unresolvedCommentCount = 0
        }
    }
}

struct StatusChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension JobCardView {
    func getColorOperation(status: JobOperationStatus) -> Color {
        var color: Color = Color.gray
        switch status {
        case .draft, .estimatePending, .waitingForParts:
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

    func getForgroundColorOperation(status: JobOperationStatus) -> Color {
        var color: Color = Color.gray
        switch status {
        case .draft, .estimatePending, .waitingForParts:
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

    func getColorBilling(status: JobBillingStatus) -> Color {
        var color: Color = Color.gray
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
        case .comped:
            color = Color.poolGreen
        case .expired, .rejected:
            color = Color.poolRed
        }
        return color
    }

    func getForgroundColorBilling(status: JobBillingStatus) -> Color {
        var color: Color = Color.gray
        switch status {
        case .draft, .estimate, .accepted, .invoiced, .comped, .expired, .rejected:
            color = Color.poolWhite
        case .inProgress, .paid:
            color = Color.poolBlack
        }
        return color
    }
}
