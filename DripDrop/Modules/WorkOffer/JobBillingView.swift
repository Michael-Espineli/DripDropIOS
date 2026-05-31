//
//  JobBillingView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import SwiftUI

struct JobBillingView: View {

    let job: Job
    let plannedLaborCents: Int
    let actualPayrollCents: Int
    let plannedMaterialCostCents: Int
    let actualMaterialCostCents: Int
    let plannedMaterialPriceCents: Int
    let billablePurchasedMaterialPriceCents: Int

    let operationStatus: JobOperationStatus?
    let billingStatus: JobBillingStatus?

    let invoiceDate: Date?
    let invoiceRef: String
    let invoiceType: JobInvoiceType?
    let invoiceNotes: String

    let onSendEstimate: () -> Void
    let onMarkEstimateAccepted: () -> Void
    let onMarkInvoiced: () -> Void
    let onMarkNotInvoiced: () -> Void
    let onGoToMaterials: () -> Void
    let onGoToActual: () -> Void

    private var currentBillingStatus: JobBillingStatus {
        billingStatus ?? job.billingStatus
    }

    private var estimatedRevenueCents: Int {
        if job.rate > 0 {
            return job.rate
        }

        return plannedLaborCents + plannedMaterialPriceCents
    }

    private var plannedCostCents: Int {
        plannedLaborCents + plannedMaterialCostCents
    }

    private var actualCostCents: Int {
        actualPayrollCents + actualMaterialCostCents
    }

    private var projectedProfitCents: Int {
        estimatedRevenueCents - plannedCostCents
    }

    private var actualProfitCents: Int {
        estimatedRevenueCents - actualCostCents
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                estimateSnapshotCard
                invoiceSnapshotCard
                billingWorkflowCard
                billingReviewCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Billing")
                        .font(.title3.weight(.semibold))

                    Text("\(job.internalId) • \(job.customerName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(currentBillingStatus.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }

            Text("This is the first billing command center. Later this can become full estimate, invoice, payment, and customer-facing billing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobBillingCard()
    }

    private var estimateSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimate Snapshot")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                JobBillingSummaryChip(
                    title: "Revenue",
                    value: JobBillingMoneyFormatter.money(estimatedRevenueCents),
                    systemImage: "dollarsign.circle"
                )

                JobBillingSummaryChip(
                    title: "Planned Cost",
                    value: JobBillingMoneyFormatter.money(plannedCostCents),
                    systemImage: "doc.text"
                )

                JobBillingSummaryChip(
                    title: "Profit",
                    value: JobBillingMoneyFormatter.money(projectedProfitCents),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }

            Divider().opacity(0.2)

            JobBillingDetailRow(
                title: "Job Rate",
                value: JobBillingMoneyFormatter.money(job.rate)
            )

            JobBillingDetailRow(
                title: "Planned Labor",
                value: JobBillingMoneyFormatter.money(plannedLaborCents)
            )

            JobBillingDetailRow(
                title: "Planned Material Cost",
                value: JobBillingMoneyFormatter.money(plannedMaterialCostCents)
            )

            JobBillingDetailRow(
                title: "Planned Material Price",
                value: JobBillingMoneyFormatter.money(plannedMaterialPriceCents)
            )

            JobBillingDetailRow(
                title: "Projected Profit",
                value: JobBillingMoneyFormatter.money(projectedProfitCents),
                valueIsWarning: projectedProfitCents < 0
            )
        }
        .jobBillingCard()
    }

    private var invoiceSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Snapshot")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                JobBillingSummaryChip(
                    title: "Actual Cost",
                    value: JobBillingMoneyFormatter.money(actualCostCents),
                    systemImage: "chart.bar"
                )

                JobBillingSummaryChip(
                    title: "Actual Profit",
                    value: JobBillingMoneyFormatter.money(actualProfitCents),
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                JobBillingSummaryChip(
                    title: "Materials",
                    value: JobBillingMoneyFormatter.money(billablePurchasedMaterialPriceCents),
                    systemImage: "cart"
                )
            }

            Divider().opacity(0.2)

            JobBillingDetailRow(
                title: "Actual Payroll",
                value: JobBillingMoneyFormatter.money(actualPayrollCents)
            )

            JobBillingDetailRow(
                title: "Actual Material Cost",
                value: JobBillingMoneyFormatter.money(actualMaterialCostCents)
            )

            JobBillingDetailRow(
                title: "Billable Purchased Materials",
                value: JobBillingMoneyFormatter.money(billablePurchasedMaterialPriceCents)
            )

            JobBillingDetailRow(
                title: "Actual Profit",
                value: JobBillingMoneyFormatter.money(actualProfitCents),
                valueIsWarning: actualProfitCents < 0
            )

            if let invoiceDate {
                Divider().opacity(0.2)

                JobBillingDetailRow(
                    title: "Invoice Date",
                    value: JobBillingDateFormatter.shortDate(invoiceDate)
                )

                JobBillingDetailRow(
                    title: "Invoice Ref",
                    value: invoiceRef.isEmpty ? "-" : invoiceRef
                )

                JobBillingDetailRow(
                    title: "Invoice Type",
                    value: invoiceType?.rawValue ?? "-"
                )
            }

            if !invoiceNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(invoiceNotes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .jobBillingCard()
    }

    private var billingWorkflowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Billing Workflow")
                .font(.headline.weight(.semibold))

            JobBillingWorkflowStepRow(
                title: "Draft",
                isActive: currentBillingStatus == .draft,
                isComplete: billingStepIndex(currentBillingStatus) >= billingStepIndex(.draft)
            )

            JobBillingWorkflowStepRow(
                title: "Estimate Sent",
                isActive: currentBillingStatus == .estimate,
                isComplete: billingStepIndex(currentBillingStatus) >= billingStepIndex(.estimate)
            )

            JobBillingWorkflowStepRow(
                title: "Accepted",
                isActive: currentBillingStatus == .accepted,
                isComplete: billingStepIndex(currentBillingStatus) >= billingStepIndex(.accepted)
            )

            JobBillingWorkflowStepRow(
                title: "In Progress",
                isActive: currentBillingStatus == .inProgress,
                isComplete: billingStepIndex(currentBillingStatus) >= billingStepIndex(.inProgress)
            )

            JobBillingWorkflowStepRow(
                title: "Invoiced",
                isActive: currentBillingStatus == .invoiced,
                isComplete: billingStepIndex(currentBillingStatus) >= billingStepIndex(.invoiced)
            )

            JobBillingWorkflowStepRow(
                title: "Paid",
                isActive: currentBillingStatus == .paid,
                isComplete: billingStepIndex(currentBillingStatus) >= billingStepIndex(.paid)
            )

            Divider().opacity(0.2)

            Button {
                onSendEstimate()
            } label: {
                JobBillingActionRow(
                    title: "Send Estimate",
                    subtitle: "Mark this job as estimate sent.",
                    systemImage: "paperplane"
                )
            }
            .buttonStyle(.plain)

            Button {
                onMarkEstimateAccepted()
            } label: {
                JobBillingActionRow(
                    title: "Mark Estimate Accepted",
                    subtitle: "Record who accepted and when.",
                    systemImage: "checkmark.circle"
                )
            }
            .buttonStyle(.plain)

            if currentBillingStatus == .invoiced {
                Button {
                    onMarkNotInvoiced()
                } label: {
                    JobBillingActionRow(
                        title: "Mark Not Invoiced",
                        subtitle: "Move this job back to in progress.",
                        systemImage: "arrow.uturn.backward.circle"
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    onMarkInvoiced()
                } label: {
                    JobBillingActionRow(
                        title: "Mark As Invoiced",
                        subtitle: "Record invoice reference and notes.",
                        systemImage: "doc.badge.plus"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .jobBillingCard()
    }

    private var billingReviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Before Billing")
                .font(.headline.weight(.semibold))

            Button {
                onGoToActual()
            } label: {
                JobBillingNavigationRow(
                    title: "Review Actual Work",
                    subtitle: "Check finished service stops and payroll before invoicing.",
                    systemImage: "checkmark.seal"
                )
            }
            .buttonStyle(.plain)

            Button {
                onGoToMaterials()
            } label: {
                JobBillingNavigationRow(
                    title: "Review Materials",
                    subtitle: "Check planned, purchased, billable, and uninvoiced materials.",
                    systemImage: "cart"
                )
            }
            .buttonStyle(.plain)

            if operationStatus != .finished {
                Label(
                    "This job is not marked finished yet.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            }
        }
        .jobBillingCard()
    }

    private func billingStepIndex(_ status: JobBillingStatus) -> Int {
        switch status {
        case .draft:
            return 0
        case .estimate:
            return 1
        case .accepted:
            return 2
        case .inProgress:
            return 3
        case .invoiced:
            return 4
        case .paid:
            return 5
        case .expired:
            return 6
        }
    }
}

// MARK: - Components

struct JobBillingSummaryChip: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.68)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct JobBillingDetailRow: View {
    var title: String
    var value: String
    var valueIsWarning: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(valueIsWarning ? .orange : .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct JobBillingWorkflowStepRow: View {
    var title: String
    var isActive: Bool
    var isComplete: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? .accent : .secondary)

            Text(title)
                .font(.subheadline.weight(isActive ? .semibold : .regular))

            Spacer()

            if isActive {
                Text("Current")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }
}

struct JobBillingActionRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobBillingNavigationRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum JobBillingMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

enum JobBillingDateFormatter {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

private extension View {
    func jobBillingCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
