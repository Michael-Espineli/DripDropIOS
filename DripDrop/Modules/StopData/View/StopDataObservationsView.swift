//
//  StopDataObservationsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct StopDataObservationsView: View {
    var stop: ServiceStop
    @State var observationOptions: [String] = ["Dirt", "No Dirt", "Algea", "No Algea", "Cloudy", "Clear", "Power Out", "Low Water", "High Water"]
    @Binding var selectedObservations: [String]

    @Binding var stopData: StopData

    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    let gridSpacing: CGFloat = 10
    @State var input: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("Custom", text: $input)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }

                Button {
                    addCustomObservation()
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.poolGreen)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(observationOptions, id: \.self) { observation in
                    observationChip(observation)
                }

                ForEach(stopData.observation, id: \.self) { observation in
                    if !observationOptions.contains(where: { $0 == observation }) {
                        observationChip(observation)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.listColor.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .onAppear {
            selectedObservations = stopData.observation
        }
        .onChange(of: stopData.observation) { observations in
            selectedObservations = observations
        }
    }
}

private extension StopDataObservationsView {
    func addCustomObservation() {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        stopData.observation.append(trimmedInput)
        stopData.observation.removeDuplicates()
        input = ""
    }

    func observationChip(_ observation: String) -> some View {
        let isSelected = stopData.observation.contains(observation)

        return Button {
            if isSelected {
                stopData.observation.removeAll(where: { $0 == observation })
            } else {
                stopData.observation.append(observation)
                stopData.observation.removeDuplicates()
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.semibold))

                Text(observation)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.poolGreen : Color(.systemBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.poolGreen : Color.secondary.opacity(0.18), lineWidth: 1)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
