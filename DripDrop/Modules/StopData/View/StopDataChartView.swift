//
//  StopDataChartView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI
import Charts

struct CharReadingAndDosage:Identifiable, Codable,Hashable{
    var id :String
    var date: Date
    var amount: Double
}

struct StopDataReadingChartView: View {
    var stopData:[StopData]
    let readingTemplate: SavedReadingsTemplate
    @State var numbers :[Double] = [1,5,5,8,3,4,6,8,4,6,7,3,9,4,2,5]
    @State var chartMarks: [CharReadingAndDosage] = []
    var maxChartValue: Double {
        chartMarks.map { $0.amount }.reduce(0, +)
    }
    var body: some View {
        VStack{
            Chart {
                RuleMark(y: .value("High", readingTemplate.highWarning ?? 0))
                RuleMark(y: .value("Low", readingTemplate.lowWarning ?? 0))

                  ForEach(chartMarks) { datum in
                      LineMark(
                        x: .value("Index", datum.date),
                        y: .value("Value", datum.amount)
                      )
                      
                      PointMark(
                        x: .value("Index", datum.date),
                        y: .value("Value", datum.amount)
                      )
                  }
              }
        }
        .task {
            chartMarks = changeStopDataToCharReadingAndDosage(template: readingTemplate, stopData: stopData)
        }
    }
    func changeStopDataToCharReadingAndDosage(template:SavedReadingsTemplate,stopData:[StopData])->[CharReadingAndDosage] {
        var chartMarks:[CharReadingAndDosage] = []
        for datum in stopData {
            for reading in datum.readings {
                if reading.templateId == template.readingsTemplateId {
                    chartMarks.append(CharReadingAndDosage(id: UUID().uuidString, date: datum.date, amount: Double(reading.amount ?? "0") ?? 0))
                }
            }
        }
        return chartMarks
    }
}
struct StopDataDosageChartView: View {
    var stopData:[StopData]
    let dosageTemplate:SavedDosageTemplate
    @State var numbers :[Double] = [1,5,5,8,3,4,6,8,4,6,7,3,9,4,2,5]
    @State var chartMarks: [CharReadingAndDosage] = []
    var maxChartValue: Double {
        chartMarks.map { $0.amount }.reduce(0, +)
    }
    var body: some View {
        VStack{
            Chart {
                  ForEach(chartMarks) { datum in
                      LineMark(
                        x: .value("Index", datum.date),
                        y: .value("Value", datum.amount)
                      )
                      
                      PointMark(
                        x: .value("Index", datum.date),
                        y: .value("Value", datum.amount)
                      )
                  }
              }
        }
        .task {
            chartMarks = changeStopDataToCharReadingAndDosage(template: dosageTemplate, stopData: stopData)
        }
    }
    func changeStopDataToCharReadingAndDosage(template:SavedDosageTemplate,stopData:[StopData])->[CharReadingAndDosage] {
        var chartMarks:[CharReadingAndDosage] = []
        for datum in stopData {
            for dosage in datum.dosages {
                if dosage.templateId == template.dosageTemplateId {
                    chartMarks.append(CharReadingAndDosage(id: UUID().uuidString, date: datum.date, amount: Double(dosage.amount ?? "0") ?? 0))
                }
            }
        }
        return chartMarks
    }
    
}

