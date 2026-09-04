//
//  StopDataReadingInputView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct StopDataReadingInputView: View {
    @Binding var stopDataList:[StopData]
    var template:SavedReadingsTemplate
    var bodyOfWaterId:String
    @State var input:String = ""
    @Binding var selectedId:String
    let selectedIdList:[String]
    @Binding var stopData:StopData
    
    var serviceStopId:String
    var serviceDate:Date
    var customerId:String
    var serviceLocationId:String
    @FocusState var chemicalInput:Bool
    @State private var isSyncingInput = false


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "testtube.2")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusTint)
                    .frame(width: 34, height: 34)
                    .background(statusTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !template.UOM.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(template.UOM)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                if hasValue {
                    Text(displayValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.poolGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.poolGreen.opacity(0.12), in: Capsule())
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(template.amount, id: \.self) { amount in
                                Button {
                                    input = amount
                                } label: {
                                    amountChip(amount, isSelected: currentReading?.amount == amount)
                                }
                                .buttonStyle(.plain)
                            }

                            readingInputField
                        }
                        .padding(.vertical, 1)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.listColor.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isExpanded ? Color.poolBlue.opacity(0.35) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onChange(of: stopData, perform: { datum in
            syncInput(from: datum)
        })
        .onAppear(perform: {
            syncInput(from: stopData)
        })
        .onChange(of: bodyOfWaterId, perform: { id in
            syncInput(from: stopData)
        })
        .onTapGesture {
            selectedId = template.readingsTemplateId
        }
        .onChange(of: selectedId, perform: { change in
            chemicalInput = false
        })
        .onChange(of: input, perform: { change in
            guard !isSyncingInput, !chemicalInput else { return }

            advanceSelectedInput()
            upsertReading(amount: change)
        })
        .onChange(of: chemicalInput, perform: { change in
            if !change {
                upsertReading(amount: input)
            }
        })
    }
}

private extension StopDataReadingInputView {
    var isExpanded: Bool {
        selectedId == template.readingsTemplateId
    }

    var trimmedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasValue: Bool {
        !trimmedInput.isEmpty
    }

    var currentReading: Reading? {
        reading(in: stopData)
    }

    var displayValue: String {
        guard hasValue else { return "-" }
        return trimmedInput
    }

    var statusTint: Color {
        if hasValue { return Color.poolGreen }
        if isExpanded { return Color.poolBlue }
        return Color.secondary.opacity(0.75)
    }

    var readingInputField: some View {
        TextField("Input", text: $input)
            .focused($chemicalInput)
            .keyboardType(.decimalPad)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(width: 88, height: 36)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(chemicalInput ? Color.poolBlue.opacity(0.55) : Color.secondary.opacity(0.18), lineWidth: 1)
            }
    }

    func amountChip(_ amount: String, isSelected: Bool) -> some View {
        Text(amount)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(minWidth: 44, minHeight: 36)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.poolGreen : Color(.systemBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.poolGreen : Color.secondary.opacity(0.18), lineWidth: 1)
            }
    }

    func syncInput(from data: StopData) {
        let storedAmount = reading(in: data)?.amount ?? ""
        guard input != storedAmount else { return }

        isSyncingInput = true
        input = storedAmount
        DispatchQueue.main.async {
            isSyncingInput = false
        }
    }

    func reading(in data: StopData) -> Reading? {
        data.readings.first(where: readingMatchesCurrentBodyOfWater)
    }

    func readingMatchesCurrentBodyOfWater(_ reading: Reading) -> Bool {
        itemMatchesBodyOfWater(reading.bodyOfWaterId) && readingMatchesTemplate(reading)
    }

    func readingMatchesTemplate(_ reading: Reading) -> Bool {
        let templateKeys = [
            template.id,
            template.readingsTemplateId,
            template.name
        ]

        return templateKeys.contains { key in
            matches(key, reading.templateId) ||
            matches(key, reading.universalTemplateId) ||
            matches(key, reading.name)
        }
    }

    func upsertReading(amount: String) {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        stopData.readings.removeAll(where: readingMatchesCurrentBodyOfWater)

        guard !trimmedAmount.isEmpty else { return }

        stopData.readings.append(Reading(
            id: UUID().uuidString,
            templateId: template.id,
            universalTemplateId: template.readingsTemplateId,
            dosageType: template.chemType,
            name: template.name,
            amount: trimmedAmount,
            UOM: template.UOM,
            bodyOfWaterId: bodyOfWaterId
        ))
    }

    func advanceSelectedInput() {
        guard let index = selectedIdList.firstIndex(where: { $0 == selectedId }) else { return }
        let totalIndex = selectedIdList.count - 1

        if index == totalIndex {
            selectedId = ""
        } else {
            selectedId = selectedIdList[index + 1]
        }
    }

    func matches(_ lhs: String?, _ rhs: String?) -> Bool {
        let left = normalizedTemplateKey(lhs)
        let right = normalizedTemplateKey(rhs)

        return !left.isEmpty && left == right
    }

    func itemMatchesBodyOfWater(_ itemBodyOfWaterId: String) -> Bool {
        let itemId = normalizedTemplateKey(itemBodyOfWaterId)
        let selectedId = normalizedTemplateKey(bodyOfWaterId)

        return itemId.isEmpty || itemId == selectedId
    }

    func normalizedTemplateKey(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
