//
//  ChemReadingRecap.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/1/24.
//

import SwiftUI

struct ChemReadingRecap: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var stopDataVM : StopDataViewModel
    
    @EnvironmentObject var VM : ServiceStopDetailViewModel

    @State var templates: [SavedReadingsTemplate]
    @State var BOW: BodyOfWater
    
    init(dataService:any ProductionDataServiceProtocol,templates:[SavedReadingsTemplate],BOW:BodyOfWater) {
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
        _templates = State(wrappedValue: templates)
        _BOW = State(wrappedValue: BOW)
    }
    
    var body: some View {
        VStack{
                ForEach(templates) { template in
                    HStack{
                        if let stopData = VM.serviceLocationStopData.first(where: {$0.bodyOfWaterId == self.BOW.id}), let reading = reading(for: template, in: stopData)  {
                            if Double(reading.amount ?? "0") ?? 1_000 > (template.highWarning ?? 1_000) {
                                Text(formattedAmount(reading.amount, unit: reading.UOM))
                                    .foregroundStyle(Color.poolRed)
                            } else  if Double(reading.amount ?? "0") ?? 0 < (template.lowWarning ?? 0) {
                                Text(formattedAmount(reading.amount, unit: reading.UOM))
                                    .foregroundStyle(Color.poolRed)
                                } else {
                                    Text(formattedAmount(reading.amount, unit: reading.UOM))
                                }
                        } else {
                            Text(" - ")
                          
                        }
                    }
                }
            
        }
    }

    private func reading(for template: SavedReadingsTemplate, in stopData: StopData) -> Reading? {
        let templateKeys = [
            template.id,
            template.readingsTemplateId,
            template.name
        ]

        return stopData.readings.first { reading in
            guard itemMatchesBodyOfWater(reading.bodyOfWaterId) else { return false }

            return templateKeys.contains { key in
                matches(key, reading.templateId) ||
                matches(key, reading.universalTemplateId) ||
                matches(key, reading.name)
            }
        }
    }

    private func itemMatchesBodyOfWater(_ bodyOfWaterId: String) -> Bool {
        let itemId = normalizedKey(bodyOfWaterId)
        let selectedId = normalizedKey(BOW.id)

        return itemId.isEmpty || itemId == selectedId
    }

    private func matches(_ lhs: String?, _ rhs: String?) -> Bool {
        let left = normalizedKey(lhs)
        let right = normalizedKey(rhs)

        return !left.isEmpty && left == right
    }

    private func normalizedKey(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func formattedAmount(_ amount: String?, unit: String?) -> String {
        let value = (amount ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let unit = (unit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else { return "-" }
        guard !unit.isEmpty else { return value }

        return "\(value) \(unit)"
    }
}

struct ChemReadingRecap_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ChemReadingRecap(
            dataService: dataService,
            templates: [],
            BOW: BodyOfWater(
                id: "",
                name: "",
                gallons: "",
                material: "",
                customerId: "",
                serviceLocationId: "",
                lastFilled: Date(),
                isActive: true
            )
        )
    }
}
