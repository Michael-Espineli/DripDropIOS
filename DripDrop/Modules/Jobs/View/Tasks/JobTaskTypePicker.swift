//
//  JobTaskTypePicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import SwiftUI

struct JobTaskTypePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var taskType: JobTaskType

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {

                    // Header Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Task Type")
                                .font(.title3.weight(.semibold))
                            Text("Choose one")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                        }
                    }
                    .ddCard()

                    // List Card
                    VStack(spacing: 8) {
                        ForEach(JobTaskType.allCases, id: \.self) { type in
                            Button(action: {
                                taskType = type
                                dismiss()
                            }, label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    Spacer()
                                    if taskType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.subheadline.weight(.semibold))
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.primary.opacity(taskType == type ? 0.10 : 0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.primary.opacity(taskType == type ? 0.18 : 0.10), lineWidth: 1)
                                )
                            })
                            .buttonStyle(.plain)
                        }
                    }
                    .ddCard()

                    Color.clear.frame(height: 20)
                }
                .padding(12)
            }
        }
    }
}

//#Preview {
//    JobTaskTypePicker()
//}
private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}
