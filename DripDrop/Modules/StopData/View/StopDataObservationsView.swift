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
        HStack(alignment: .top, spacing: 0) {
            if selectedObservations.count < 1 {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 6)
                    .cornerRadius(3)
            } else {
                Rectangle()
                    .fill(Color.poolGreen)
                    .frame(width: 6)
                    .cornerRadius(3)
            }
            VStack {
                VStack {
                    HStack(spacing: 8) {
                        TextField("Custom", text: $input)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.systemBackground)))
                        Button(action: {
                            if input != "" {
                                stopData.observation.append(input)
                                stopData.observation.removeDuplicates()
                                input = ""
                            }
                        }, label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.poolGreen))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        })
                    }

                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(observationOptions, id: \.self) { observation in
                            Button(action: {
                                if stopData.observation.contains(observation) {
                                    stopData.observation.removeAll(where: { $0 == observation })
                                } else {
                                    stopData.observation.append(observation)
                                    stopData.observation.removeDuplicates()
                                }
                            }, label: {
                                if stopData.observation.contains(observation) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("\(observation)")
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.poolGreen))
                                    .foregroundStyle(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "circle")
                                        Text("\(observation)")
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.gray.opacity(0.4)))
                                    .foregroundStyle(Color.primary)
                                }
                            })
                        }
                        ForEach(stopData.observation, id: \.self) { observation in
                            if !observationOptions.contains(where: { $0 == observation }) {
                                Button(action: {
                                    if stopData.observation.contains(observation) {
                                        stopData.observation.removeAll(where: { $0 == observation })
                                    }
                                }, label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("\(observation)")
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.poolGreen))
                                    .foregroundStyle(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                })
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            }
            .padding(12)
        }
    }
}
