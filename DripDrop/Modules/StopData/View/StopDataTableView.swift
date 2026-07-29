//
//  StopDataTableView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/23/24.
//

import SwiftUI

struct StopDataTableView: View {
    @EnvironmentObject var dataService : ProductionDataService
    let stopData:[StopData]
    let readingTemplates : [SavedReadingsTemplate]
    let dosageTemplates : [SavedDosageTemplate]
    let bodyOfWaterId: String?

    init(
        stopData: [StopData],
        readingTemplates: [SavedReadingsTemplate],
        dosageTemplates: [SavedDosageTemplate],
        bodyOfWaterId: String? = nil
    ) {
        self.stopData = stopData
        self.readingTemplates = readingTemplates
        self.dosageTemplates = dosageTemplates
        self.bodyOfWaterId = bodyOfWaterId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if visibleStopData.isEmpty {
                ContentUnavailableView(
                    "No Water History",
                    systemImage: "tablecells",
                    description: Text("No recent readings or dosages recorded.")
                )
                .frame(minWidth: 280)
                .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 6) {
                        tableHeader
                        tableContent
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

#Preview {
    StopDataTableView(stopData: [], readingTemplates: [], dosageTemplates: [])
}
private extension StopDataTableView {
    var selectedBodyOfWaterId: String? {
        let trimmed = bodyOfWaterId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var visibleStopData: [StopData] {
        guard let selectedBodyOfWaterId else { return stopData }

        return stopData.filter { data in
            data.bodyOfWaterId == selectedBodyOfWaterId ||
            data.readings.contains { $0.bodyOfWaterId == selectedBodyOfWaterId } ||
            data.dosages.contains { $0.bodyOfWaterId == selectedBodyOfWaterId }
        }
    }

    var activeReadingTemplates: [SavedReadingsTemplate] {
        readingTemplates.filter { template in
            visibleStopData.contains { data in
                data.readings.contains {
                    readingBelongsToSelectedBodyOfWater($0, in: data) &&
                    readingMatches($0, template: template)
                }
            }
        }
    }

    var activeDosageTemplates: [SavedDosageTemplate] {
        dosageTemplates.filter { template in
            visibleStopData.contains { data in
                data.dosages.contains {
                    dosageBelongsToSelectedBodyOfWater($0, in: data) &&
                    dosageMatches($0, template: template)
                }
            }
        }
    }

    var tableWidth: CGFloat {
        86 + CGFloat(activeReadingTemplates.count * 72) + CGFloat(activeDosageTemplates.count * 72) + 92
    }

    var tableHeader: some View {
        HStack(spacing: 0) {
            headerCell("Date", width: 86, alignment: .leading)

            ForEach(activeReadingTemplates) { template in
                headerCell(shortColumnName(template.name), width: 72)
            }

            ForEach(activeDosageTemplates) { template in
                headerCell(shortColumnName(template.name ?? "Dose"), width: 72)
            }

            headerCell("Stop", width: 92, alignment: .trailing)
        }
        .frame(width: max(tableWidth, 280), alignment: .leading)
        .padding(.vertical, 9)
        .background(Color.poolBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var tableContent: some View {
        VStack(spacing: 6) {
            ForEach(Array(visibleStopData.enumerated()), id: \.element.id) { index, data in
                tableRow(data, rowIndex: index)
            }
        }
    }

    func tableRow(_ data: StopData, rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            valueCell(shortDate(date: data.date), width: 86, alignment: .leading)

            ForEach(activeReadingTemplates) { template in
                let reading = reading(for: template, in: data)
                valueCell(
                    readingAmount(reading),
                    width: 72,
                    isWarning: readingIsOutsideWarning(reading, template: template)
                )
            }

            ForEach(activeDosageTemplates) { template in
                valueCell(dosageAmount(dosage(for: template, in: data)), width: 72)
            }

            stopCell(data)
        }
        .frame(width: max(tableWidth, 280), alignment: .leading)
        .padding(.vertical, 9)
        .background(rowBackground(rowIndex), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func headerCell(_ title: String, width: CGFloat, alignment: Alignment = .center) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 6)
    }

    func valueCell(_ value: String, width: CGFloat, alignment: Alignment = .center, isWarning: Bool = false) -> some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(valueColor(value, isWarning: isWarning))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 6)
    }

    func stopCell(_ data: StopData) -> some View {
        Button {
            print("Show Detail View For Service Stop \(data.serviceStopId)")
        } label: {
            HStack(spacing: 4) {
                Text(abbreviatedStopId(data.serviceStopId))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(Color.poolBlue)
            .frame(width: 92, alignment: .trailing)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
    }

    func rowBackground(_ index: Int) -> Color {
        index.isMultiple(of: 2) ? Color(.systemBackground) : Color.listColor.opacity(0.55)
    }

    func valueColor(_ value: String, isWarning: Bool) -> Color {
        if isWarning { return Color.poolRed }
        if value == "-" { return Color.secondary.opacity(0.5) }
        return Color.primary
    }

    func reading(for template: SavedReadingsTemplate, in data: StopData) -> Reading? {
        data.readings.first {
            readingBelongsToSelectedBodyOfWater($0, in: data) &&
            readingMatches($0, template: template)
        }
    }

    func dosage(for template: SavedDosageTemplate, in data: StopData) -> Dosage? {
        data.dosages.first {
            dosageBelongsToSelectedBodyOfWater($0, in: data) &&
            dosageMatches($0, template: template)
        }
    }

    func readingBelongsToSelectedBodyOfWater(_ reading: Reading, in data: StopData) -> Bool {
        guard let selectedBodyOfWaterId else { return true }
        return reading.bodyOfWaterId == selectedBodyOfWaterId ||
        (reading.bodyOfWaterId.isEmpty && data.bodyOfWaterId == selectedBodyOfWaterId)
    }

    func dosageBelongsToSelectedBodyOfWater(_ dosage: Dosage, in data: StopData) -> Bool {
        guard let selectedBodyOfWaterId else { return true }
        return dosage.bodyOfWaterId == selectedBodyOfWaterId ||
        (dosage.bodyOfWaterId.isEmpty && data.bodyOfWaterId == selectedBodyOfWaterId)
    }

    func readingMatches(_ reading: Reading, template: SavedReadingsTemplate) -> Bool {
        reading.universalTemplateId == template.readingsTemplateId ||
        reading.templateId == template.id ||
        reading.templateId == template.readingsTemplateId
    }

    func dosageMatches(_ dosage: Dosage, template: SavedDosageTemplate) -> Bool {
        dosage.universalTemplateId == template.dosageTemplateId ||
        dosage.templateId == template.id ||
        dosage.templateId == template.dosageTemplateId
    }

    func readingAmount(_ reading: Reading?) -> String {
        let amount = reading?.amount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return amount.isEmpty || amount == "0" ? "-" : amount
    }

    func dosageAmount(_ dosage: Dosage?) -> String {
        let amount = dosage?.amount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return amount.isEmpty || amount == "0" ? "-" : formattedDosageAmount(amount)
    }

    func readingIsOutsideWarning(_ reading: Reading?, template: SavedReadingsTemplate) -> Bool {
        let rawAmount = reading?.amount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard rawAmount != "0", let amount = Double(rawAmount) else { return false }

        if let highWarning = template.highWarning, highWarning > 0, amount >= highWarning {
            return true
        }

        if let lowWarning = template.lowWarning, lowWarning > 0, amount <= lowWarning {
            return true
        }

        return false
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

    func shortColumnName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "-" }

        if trimmed.count <= 8 {
            return trimmed
        }

        let words = trimmed.split(separator: " ")
        if words.count > 1 {
            return words.compactMap(\.first).map(String.init).joined().uppercased()
        }

        return String(trimmed.prefix(8))
    }

    func abbreviatedStopId(_ id: String) -> String {
        if id.count <= 8 {
            return id
        }

        return String(id.suffix(8))
    }
}
