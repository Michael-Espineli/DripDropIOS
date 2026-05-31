//
//  JobDashboardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


//
//  JobDashboardView.swift
//  DripDrop
//

import SwiftUI

struct JobDashboardView: View {

    let job: Job
    let summary: JobDashboardSummary
    let healthReport: JobWorkflowHealthReport
    let serviceLocation: ServiceLocation?
    let operationStatus: JobOperationStatus?
    let billingStatus: JobBillingStatus?
    
    let onNavigateToHealthIssue: (String) -> Void
    let onGoToPlan: () -> Void
    let onGoToOffers: () -> Void
    let onGoToSchedule: () -> Void
    let onGoToActual: () -> Void
    let onGoToMaterials: () -> Void
    let onGoToBilling: () -> Void
    let onEditInfo: () -> Void
    let onSendEstimate: () -> Void
    let onMarkAccepted: () -> Void
    let onMarkInvoiced: () -> Void
    let onToggleFinished: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                healthCard
                financialSnapshotCard
                workPipelineCard
                billingAndPayrollCard
                quickActionsCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(job.internalId)
                        .font(.title2.weight(.bold))

                    Text(job.type.isEmpty ? "Job" : job.type)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(job.customerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onEditInfo()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.body.weight(.semibold))
                        .padding(9)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            if let serviceLocation {
                Label(serviceLocation.address.streetAddress, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !job.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(job.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            HStack(spacing: 10) {
                JobDashboardStatusPill(
                    title: operationStatus?.rawValue ?? job.operationStatus.rawValue,
                    systemImage: "flag"
                )

                JobDashboardStatusPill(
                    title: billingStatus?.rawValue ?? job.billingStatus.rawValue,
                    systemImage: "doc.text"
                )
            }
        }
        .jobDashboardCard()
    }
    
    private var healthCard: some View {
        JobWorkflowHealthView(
            report: healthReport,
            onNavigate: onNavigateToHealthIssue
        )
    }
    
    private var financialSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Snapshot")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                JobDashboardSummaryChip(
                    title: "Revenue",
                    value: JobDashboardMoneyFormatter.money(summary.plannedRevenueCents),
                    systemImage: "dollarsign.circle"
                )

                JobDashboardSummaryChip(
                    title: "Planned Cost",
                    value: JobDashboardMoneyFormatter.money(summary.plannedTotalCostCents),
                    systemImage: "doc.text"
                )

                JobDashboardSummaryChip(
                    title: "Actual Cost",
                    value: JobDashboardMoneyFormatter.money(summary.actualTotalCostCents),
                    systemImage: "chart.bar"
                )
            }

            Divider().opacity(0.2)

            JobDashboardDetailRow(
                title: "Planned Stop Labor",
                value: JobDashboardMoneyFormatter.money(summary.plannedServiceStopLaborCents)
            )

            JobDashboardDetailRow(
                title: "Planned Task Labor",
                value: JobDashboardMoneyFormatter.money(summary.plannedTaskLaborCents)
            )

            JobDashboardDetailRow(
                title: "Planned Total Labor",
                value: JobDashboardMoneyFormatter.money(summary.plannedLaborCents)
            )

            JobDashboardDetailRow(
                title: "Actual Payroll",
                value: JobDashboardMoneyFormatter.money(summary.actualPayrollCents)
            )

            JobDashboardDetailRow(
                title: "Labor Difference",
                value: JobDashboardMoneyFormatter.signedMoney(summary.laborDifferenceCents),
                valueIsWarning: summary.laborDifferenceCents > 0
            )

            Divider().opacity(0.2)

            JobDashboardDetailRow(
                title: "Planned Materials",
                value: JobDashboardMoneyFormatter.money(summary.plannedMaterialCostCents)
            )

            JobDashboardDetailRow(
                title: "Actual Materials",
                value: JobDashboardMoneyFormatter.money(summary.actualMaterialCostCents)
            )

            JobDashboardDetailRow(
                title: "Material Difference",
                value: JobDashboardMoneyFormatter.signedMoney(summary.materialDifferenceCents),
                valueIsWarning: summary.materialDifferenceCents > 0
            )

            Divider().opacity(0.2)

            JobDashboardDetailRow(
                title: "Projected Profit",
                value: JobDashboardMoneyFormatter.money(summary.plannedProfitCents),
                valueIsWarning: summary.plannedProfitCents < 0
            )

            JobDashboardDetailRow(
                title: "Actual Profit",
                value: JobDashboardMoneyFormatter.money(summary.actualProfitCents),
                valueIsWarning: summary.actualProfitCents < 0
            )
        }
        .jobDashboardCard()
    }

    private var workPipelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Work Pipeline")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                JobDashboardSummaryChip(
                    title: "Stops",
                    value: "\(summary.serviceStopCount)",
                    systemImage: "calendar"
                )

                JobDashboardSummaryChip(
                    title: "Finished",
                    value: "\(summary.finishedServiceStopCount)",
                    systemImage: "checkmark.seal"
                )

                JobDashboardSummaryChip(
                    title: "Ready",
                    value: "\(summary.acceptedOffersReadyToScheduleCount)",
                    systemImage: "calendar.badge.plus"
                )
            }
            if summary.acceptedOffersReadyToScheduleCount > 0 {
                Button {
                    onGoToSchedule()
                } label: {
                    Label(
                        "\(summary.acceptedOffersReadyToScheduleCount) accepted offer(s) ready to schedule.",
                        systemImage: "calendar.badge.plus"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Button {
                onGoToPlan()
            } label: {
                JobDashboardNavigationRow(
                    title: "Plan Work",
                    subtitle: "Review planned tasks and labor cost.",
                    systemImage: "checklist"
                )
            }
            .buttonStyle(.plain)

            Button {
                onGoToOffers()
            } label: {
                JobDashboardNavigationRow(
                    title: "Work Offers",
                    subtitle: "Offer work to contractors or post to the internal board.",
                    systemImage: "person.crop.circle.badge.plus"
                )
            }
            .buttonStyle(.plain)

            Button {
                onGoToSchedule()
            } label: {
                JobDashboardNavigationRow(
                    title: "Schedule",
                    subtitle: "Review scheduled stops and accepted offers.",
                    systemImage: "calendar.badge.clock"
                )
            }
            .buttonStyle(.plain)

            Button {
                onGoToActual()
            } label: {
                JobDashboardNavigationRow(
                    title: "Actual Work",
                    subtitle: "Compare finished work and payroll to the original plan.",
                    systemImage: "checkmark.seal"
                )
            }
            .buttonStyle(.plain)
        }
        .jobDashboardCard()
    }

    private var billingAndPayrollCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Billing & Payroll")
                .font(.headline.weight(.semibold))

            if summary.payrollNeedsReviewCount > 0 {
                Label(
                    "\(summary.payrollNeedsReviewCount) payroll line item(s) need review.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(10)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                onGoToMaterials()
            } label: {
                JobDashboardNavigationRow(
                    title: "Materials",
                    subtitle: "Review planned and purchased materials.",
                    systemImage: "cart"
                )
            }
            .buttonStyle(.plain)

            Button {
                onGoToBilling()
            } label: {
                JobDashboardNavigationRow(
                    title: "Customer Billing",
                    subtitle: "Estimate, invoice, and payment workflow will live here.",
                    systemImage: "doc.text"
                )
            }
            .buttonStyle(.plain)
        }
        .jobDashboardCard()
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline.weight(.semibold))

            Button {
                onSendEstimate()
            } label: {
                JobDashboardActionRow(
                    title: "Send Estimate",
                    subtitle: "Move this job into estimate status.",
                    systemImage: "paperplane"
                )
            }
            .buttonStyle(.plain)

            Button {
                onMarkAccepted()
            } label: {
                JobDashboardActionRow(
                    title: "Mark Estimate Accepted",
                    subtitle: "Record manual customer approval.",
                    systemImage: "checkmark.circle"
                )
            }
            .buttonStyle(.plain)

            Button {
                onMarkInvoiced()
            } label: {
                JobDashboardActionRow(
                    title: "Mark As Invoiced",
                    subtitle: "Record manual invoice information.",
                    systemImage: "doc.badge.plus"
                )
            }
            .buttonStyle(.plain)

            Button {
                onToggleFinished()
            } label: {
                JobDashboardActionRow(
                    title: job.operationStatus == .finished ? "Mark Not Finished" : "Mark Finished",
                    subtitle: "Update the job operation status.",
                    systemImage: job.operationStatus == .finished ? "arrow.uturn.backward.circle" : "checkmark.seal"
                )
            }
            .buttonStyle(.plain)
        }
        .jobDashboardCard()
    }
}

// MARK: - Components

struct JobDashboardSummaryChip: View {
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

struct JobDashboardStatusPill: View {
    var title: String
    var systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }
}

struct JobDashboardDetailRow: View {
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

struct JobDashboardNavigationRow: View {
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

struct JobDashboardActionRow: View {
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

enum JobDashboardMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }

    static func signedMoney(_ cents: Int) -> String {
        if cents == 0 {
            return "$0.00"
        }

        let prefix = cents > 0 ? "+" : "-"
        return prefix + money(abs(cents))
    }
}

private extension View {
    func jobDashboardCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
