//
//  JobWorkflowHealthView.swift
//  DripDrop
//

import SwiftUI

struct JobWorkflowHealthView: View {
    let report: JobWorkflowHealthReport
    let onNavigate: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if report.sortedIssues.isEmpty {
                emptyHealthyState
            } else {
                VStack(spacing: 10) {
                    ForEach(report.sortedIssues) { issue in
                        JobWorkflowHealthIssueRow(
                            issue: issue,
                            onNavigate: onNavigate
                        )
                    }
                }
            }
        }
        .jobWorkflowHealthCard()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workflow Health")
                    .font(.headline.weight(.semibold))

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if report.needsAttentionCount > 0 {
                Text("\(report.needsAttentionCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.red, in: Capsule())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var summaryText: String {
        if report.isHealthy {
            return "No major workflow issues found."
        }

        return "\(report.criticalCount) critical • \(report.warningCount) warning • \(report.infoCount) info"
    }

    private var emptyHealthyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.green)

            Text("Everything looks good.")
                .font(.subheadline.weight(.semibold))

            Text("No workflow issues were found for this job.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobWorkflowHealthIssueRow: View {
    let issue: JobWorkflowHealthIssue
    let onNavigate: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: issue.severity.systemImage)
                    .foregroundStyle(issue.severity.tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(issue.title)
                        .font(.subheadline.weight(.semibold))

                    Text(issue.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack {
                Label(issue.category.rawValue, systemImage: issue.category.systemImage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if let destinationTab = issue.destinationTab,
                   let actionTitle = issue.actionTitle {
                    Button {
                        onNavigate(destinationTab)
                    } label: {
                        Text(actionTitle)
                            .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension View {
    func jobWorkflowHealthCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}