//
//  ChemDosageRecap.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/1/24.
//



import SwiftUI

struct ChemDosageRecap: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var stopDataVM : StopDataViewModel
    
    @EnvironmentObject var VM : ServiceStopDetailViewModel

    @State var templates: [SavedDosageTemplate]
    @State var BOW: BodyOfWater
    init(dataService:any ProductionDataServiceProtocol,templates:[SavedDosageTemplate],BOW:BodyOfWater) {
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _stopDataVM = StateObject(wrappedValue: StopDataViewModel(dataService: dataService))
        _templates = State(wrappedValue: templates)
        _BOW = State(wrappedValue: BOW)
    }


    var body: some View {
        VStack{
                ForEach(templates) { template in
                    HStack{
                        if let stopData = VM.serviceLocationStopData.first(where: {$0.bodyOfWaterId == self.BOW.id}), let dosage = dosage(for: template, in: stopData) {
                            Text(formattedAmount(dosage.amount, unit: dosage.UOM))
                            
                        } else {
                            Text(" - ")
                        }
                    }
                }
            
        }
    }

    private func dosage(for template: SavedDosageTemplate, in stopData: StopData) -> Dosage? {
        let templateKeys = [
            template.id,
            template.dosageTemplateId,
            template.name ?? ""
        ]

        return stopData.dosages.first { dosage in
            guard itemMatchesBodyOfWater(dosage.bodyOfWaterId) else { return false }

            return templateKeys.contains { key in
                matches(key, dosage.templateId) ||
                matches(key, dosage.universalTemplateId) ||
                matches(key, dosage.name)
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

struct ChemDosageRecap_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        ChemDosageRecap(
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
