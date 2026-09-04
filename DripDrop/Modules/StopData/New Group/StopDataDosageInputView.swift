//
//  StopDataDosageInputView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct StopDataDosageInputView: View {
    @Binding var stopDataList:[StopData]
    var template:SavedDosageTemplate
    var bodyOfWaterId:String
    @State var input:String = ""
    @Binding var selectedId:String
    let selectedIdList:[String]

    @Binding var stopData:StopData
    var serviceStopId:String
    var serviceDate:Date
    let observations:[String]
    let gallons:Int
    @State var prediction:String = ""
    @FocusState var chemicalInput:Bool
    @State private var isSyncingInput = false

    var body: some View {
        /*
         // Old View
        ZStack{
            HStack{
                if input == "" {
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 5)
                } else {
                    Rectangle()
                        .fill(Color.poolGreen)
                        .frame(width: 5)
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
            
            VStack{
                if selectedId == template.dosageTemplateId {
                    HStack{
                        Text(template.name ?? "Template Name")
                            .font(.footnote)
                        Spacer()
                    }
                    VStack{
                        Text(prediction)
                        ScrollView(.horizontal,showsIndicators: false){
                            HStack(spacing: 0){
                                TextField("Input", text: $input)
                                    .modifier(TextFieldModifier())
                                    .modifier(OutLineButtonModifier())
                                    .focused($chemicalInput)
                                ForEach(template.amount ?? [],id:\.self){ amount in
                           
                                    Button(action: {
                                        input = amount
                                    }, label: {
                                        let suffix = amount.suffix(3)
                                        
                                        var endCharecter:String? = nil
                                        if suffix == ".00" {
                                            if let dosage = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))")
                                                        .modifier(SubmitButtonModifier())
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))")
                                                        .modifier(ListButtonModifier())
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))")
                                                    .modifier(ListButtonModifier())
                                            }

                                        } else if suffix == ".25" {
                                            if let dosage = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))¼")
                                                        .modifier(SubmitButtonModifier())
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))¼")
                                                        .modifier(ListButtonModifier())
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))¼")
                                                    .modifier(ListButtonModifier())
                                            }
                                        } else if suffix == ".50" {
                                            if let dosage = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))½")
                                                        .modifier(SubmitButtonModifier())
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))½")
                                                        .modifier(ListButtonModifier())
                                                }
                                            } else {
                                                Text("\(String(amount.dropLast(3)))½")
                                                    .modifier(ListButtonModifier())
                                            }
                                        } else if suffix == ".75" {
                                            if let dosage = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))¾")
                                                        .modifier(SubmitButtonModifier())
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))¾") .modifier(ListButtonModifier())
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))¾") .modifier(ListButtonModifier())
                                            }
                                        } else {
                                            if let dosage = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(amount)")
                                                        .modifier(SubmitButtonModifier())
                                                } else {
                                                    Text("\(amount)") 
                                                        .modifier(ListButtonModifier())
                                                }
                                            } else {
                                                Text("\(amount)") 
                                                    .modifier(ListButtonModifier())
                                            }
                                        }
                                    })
                                    .padding(.horizontal,8)
                                    
                                }
                            }
                        }
                    }
                } else {
                    if input == "" {
                        HStack{
                            Text(template.name ?? "")
                            if let reading = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .modifier(ListButtonModifier())
                    } else {
                        HStack{
                            Text(template.name ?? "")
                            if let reading = stopData.dosages.first(where: {$0.universalTemplateId == template.dosageTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .modifier(AddButtonModifier())
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 28, bottom: 5, trailing: 0))
        }
        */
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "drop.degreesign")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusTint)
                    .frame(width: 34, height: 34)
                    .background(statusTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name ?? "Dosage")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !templateUOM.isEmpty {
                        Text(templateUOM)
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
                    if !prediction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Label(prediction, systemImage: "sparkles")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(template.amount ?? [], id: \.self) { amount in
                                Button {
                                    input = amount
                                } label: {
                                    amountChip(amount, isSelected: currentDosage?.amount == amount)
                                }
                                .buttonStyle(.plain)
                            }

                            dosageInputField
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
        .onAppear(perform: {
            loadStopDataFromListIfAvailable(for: bodyOfWaterId)
            syncInput(from: stopData)
            updatePrediction(readings: stopData.readings, observations: observations)
        })

        .onTapGesture {
            selectedId = template.dosageTemplateId
        }
        .onChange(of: bodyOfWaterId, perform: { id in
            loadStopDataFromListIfAvailable(for: id)
            syncInput(from: stopData)
            updatePrediction(readings: stopData.readings, observations: observations)
        })
        .onChange(of: stopData, perform: { data in
            syncInput(from: data)
            updatePrediction(readings: data.readings, observations: observations)
        })
        .onChange(of: stopData.readings, perform: { change in
            updatePrediction(readings: change, observations: observations)
        })
        .onChange(of: observations, perform: { change in
            updatePrediction(readings: stopData.readings, observations: change)
        })
        .onChange(of: input, perform: { change in
            guard !isSyncingInput, !chemicalInput else { return }

            advanceSelectedInput()
            upsertDosage(amount: change)
        })
        .onChange(of: chemicalInput, perform: { change in
            if !change {
                upsertDosage(amount: input)
            }
        })
    }
}

private extension StopDataDosageInputView {
    var isExpanded: Bool {
        selectedId == template.dosageTemplateId
    }

    var trimmedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasValue: Bool {
        !trimmedInput.isEmpty
    }

    var currentDosage: Dosage? {
        dosage(in: stopData)
    }

    var displayValue: String {
        guard hasValue else { return "-" }
        return formattedDosageAmount(trimmedInput)
    }

    var templateUOM: String {
        (template.UOM ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var statusTint: Color {
        if hasValue { return Color.poolGreen }
        if isExpanded { return Color.poolBlue }
        return Color.secondary.opacity(0.75)
    }

    var dosageInputField: some View {
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
        Text(formattedDosageAmount(amount))
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

    func loadStopDataFromListIfAvailable(for bodyOfWaterId: String) {
        guard let matchingStopData = stopDataList.first(where: { $0.bodyOfWaterId == bodyOfWaterId }) else { return }
        stopData = matchingStopData
    }

    func syncInput(from data: StopData) {
        let storedAmount = dosage(in: data)?.amount ?? ""
        guard input != storedAmount else { return }

        isSyncingInput = true
        input = storedAmount
        DispatchQueue.main.async {
            isSyncingInput = false
        }
    }

    func updatePrediction(readings: [Reading], observations: [String]) {
        prediction = getChemicalDosages(
            gallons:gallons,
            dosageTempalte: template,
            readings: readings.filter { itemMatchesBodyOfWater($0.bodyOfWaterId) },
            observations: observations
        )
    }

    func dosage(in data: StopData) -> Dosage? {
        data.dosages.first(where: dosageMatchesCurrentBodyOfWater)
    }

    func dosageMatchesCurrentBodyOfWater(_ dosage: Dosage) -> Bool {
        itemMatchesBodyOfWater(dosage.bodyOfWaterId) && dosageMatchesTemplate(dosage)
    }

    func dosageMatchesTemplate(_ dosage: Dosage) -> Bool {
        let templateKeys = [
            template.id,
            template.dosageTemplateId,
            template.name ?? ""
        ]

        return templateKeys.contains { key in
            matches(key, dosage.templateId) ||
            matches(key, dosage.universalTemplateId) ||
            matches(key, dosage.name)
        }
    }

    func upsertDosage(amount: String) {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        stopData.dosages.removeAll(where: dosageMatchesCurrentBodyOfWater)

        guard !trimmedAmount.isEmpty else { return }

        stopData.dosages.append(Dosage(
            id: UUID().uuidString,
            templateId: template.id,
            universalTemplateId: template.dosageTemplateId,
            name: template.name,
            amount: trimmedAmount,
            UOM: template.UOM,
            rate: template.rate,
            linkedItem: template.linkedItemId,
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

    func formattedDosageAmount(_ amount: String) -> String {
        let suffix = amount.suffix(3)

        if suffix == ".00" {
            return String(amount.dropLast(3))
        } else if suffix == ".25" {
            return "\(String(amount.dropLast(3)))¼"
        } else if suffix == ".50" {
            return "\(String(amount.dropLast(3)))½"
        } else if suffix == ".75" {
            return "\(String(amount.dropLast(3)))¾"
        }

        return amount
    }

    func getChemicalDosages(gallons:Int,dosageTempalte:SavedDosageTemplate,readings:[Reading]?,observations:[String])->  String {
        
        return recommendationChems(gallons: Double(gallons), dosageTemplate: dosageTempalte, readingList: readings ?? [], hasAlgea: observations.contains(where: {$0 == "Algea"}))
        
    }
}
