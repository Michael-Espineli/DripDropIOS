//
//  ToDoCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//

import SwiftUI

struct ToDoCardView: View {
    let toDo : ToDo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(toDo.issueKey)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)

                    Text(toDo.priorityLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(priorityColor)

                    if toDo.needsAttention {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                Text(toDo.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !toDo.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(toDo.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    pill(text: toDo.statusLabel, color: statusColor)
                    pill(text: toDo.dueLabel, color: dueColor)
                }

                Text(toDo.detailLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 3)
        }
        .padding(13)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private extension ToDoCardView {
    var statusColor: Color {
        if toDo.needsAttention {
            return .orange
        }

        switch toDo.statusKey {
        case "inprogress":
            return .poolBlue
        case "done", "finished", "complete", "completed":
            return .poolGreen
        default:
            return .gray
        }
    }

    var priorityColor: Color {
        switch toDo.priority.lowercased() {
        case "urgent":
            return .poolRed
        case "high":
            return .orange
        case "low":
            return .poolGreen
        default:
            return .secondary
        }
    }

    var dueColor: Color {
        switch toDo.dueState {
        case .overdue:
            return .poolRed
        case .today:
            return .orange
        case .upcoming:
            return .poolBlue
        case .complete:
            return .poolGreen
        case .none:
            return .gray
        }
    }

    func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct ToDoCardView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoCardView(toDo:  ToDo(id: "todo_12345", title: "Check the Dude Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: "", boardName: "Route Prep", priority: "high", dueAt: Date()))
            .padding()
            .background(Color.listColor)
    }
}
