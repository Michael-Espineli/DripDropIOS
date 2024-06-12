//
//  StopDataTableView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/23/24.
//

import SwiftUI

struct StopDataTableView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @State var stopData:[StopData]
    let readingTemplates : [ReadingsTemplate]
    let dosageTemplates : [DosageTemplate]
    
    @State var readingTemplateCounter:[String:Int] = [:]
    @State var dosageTemplateCounter:[String:Int] = [:]
    
    var body: some View {
        VStack(spacing:0){
            if stopData.isEmpty {
                Text("No Data Yet")
            } else {
                title
                content
            }
        }
        .onChange(of: stopData, perform: { datum in
            print("")
            print(" Change Stop Data Count - \(datum.count)")
            
        })
        .onAppear(perform: {
            print("")
            for template in dosageTemplates {
                dosageTemplateCounter[template.id] = 0

            }
            for template in readingTemplates {
                readingTemplateCounter[template.id] = 0
            }
            print(" Stop Data Count - \(stopData.count)")
            for data in stopData {
                print(" Data \(data.serviceStopId)")
                for reading in data.readings {
                    print(" - \(reading.name)")
                    var total:Int = readingTemplateCounter[reading.templateId] ?? 0
                    total += 1
                    print(" - \(total)")
                    readingTemplateCounter[reading.templateId] = total
                }
                for dosage in data.dosages {
                    print(" - \(dosage.name)")
                    var total:Int = dosageTemplateCounter[dosage.templateId] ?? 0
                    total += 1
                    print(" - \(total)")
                    dosageTemplateCounter[dosage.templateId] = total
                }
            }
            print("Reading Template Counter \(readingTemplateCounter.count)")
            for temp in readingTemplateCounter {
                print(" - \(temp)")
            }
            print("Dosage Template Counter \(dosageTemplateCounter.count)")
            for temp in dosageTemplateCounter {
                print(" - \(temp)")
            }
            print("")
        })
    }
}

#Preview {
    StopDataTableView(stopData: [], readingTemplates: [], dosageTemplates: [])
}
extension StopDataTableView {
    var title: some View {
        HStack{
            Text("00-00-00")
                .foregroundColor(Color.clear)
                .overlay(
                    Text("Date")
                        .font(.footnote)
                )
            readingsTemplates
            dosagesTemplates
            Text("S0000000")
                .foregroundColor(Color.clear)
                .overlay(Text("Stop Id"))
            Spacer()
        }
    }
    var content: some View {
        VStack{
            ForEach(stopData) { data in
                                Rectangle()
                    .frame(height: 1)
                HStack{
                    Text("00-00-00")
                        .foregroundColor(Color.clear)
                        .overlay( Text(shortDate(date:data.date)))
                    
                    HStack{
                        ForEach(readingTemplates){ template in
                            if readingTemplateCounter[template.id] != 0 {
                                if let reading:Reading = data.readings.first(where: {$0.templateId == template.id}) {
                                    let amount:String = reading.amount ?? "0"
                                    if ((Double(amount) ?? 0) >= (template.highWarning ?? 0)) || ((Double(amount) ?? 0) <= (template.lowWarning ?? 0)) {
                                        Text("\(longestWord(str: template.name))")
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .font(.footnote)
                                            .frame(width: 60)
                                            .foregroundColor(Color.clear)
                                            .overlay(
                                                Text(amount == "0" ? "-" : "\(amount)")
                                                    .foregroundStyle(Color.red)
                                            )
                                    } else {
                                        Text("\(longestWord(str: template.name))")
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .font(.footnote)
                                            .frame(width: 60)
                                            .foregroundColor(Color.clear)
                                            .overlay(
                                                Text(amount == "0" ? "-" : "\(amount)")
                                                    .foregroundStyle(Color.green)
                                            )
                                    }
                                } else {
                                    Text("\(longestWord(str: template.name))")
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(.footnote)
                                        .frame(width: 60)
                                        .foregroundColor(Color.clear)
                                        .overlay(
                                            Text("-")
                                        )
                                }
                            }
                        }
                    }
                    
                    HStack{
                        ForEach(dosageTemplates){ dosage in
                            if dosageTemplateCounter[dosage.id] != 0 {
                                let name:String = dosage.name ?? ""
                                if let dosage:Dosage = data.dosages.first(where: {$0.templateId == dosage.id}) {
                                    Text("\(longestWord(str: name))")
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(.footnote)
                                        .frame(width: 60)
                                        .foregroundColor(Color.clear)
                                        .overlay(
                                            Text(dosage.amount == "0" ? "-":"\(dosage.amount ?? "0")")
                                        )
                                } else {
                                    Text("\(longestWord(str: name))")
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(.footnote)
                                        .frame(width: 60)
                                        .foregroundColor(Color.clear)
                                        .overlay(
                                            Text("-")
                                        )
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        print("Show Detail View For Service Stop \(data.serviceStopId)")
                    }, label: {
                        Text("S0000000")
                            .font(.footnote)
                            .foregroundColor(Color.clear)
                            .overlay(Text("\(data.serviceStopId)"))
                    })
                    Spacer()
                    
                }
            }
        }
    }
    var readingsTemplates: some View {
        HStack{
            ForEach(readingTemplates){ template in
                if readingTemplateCounter[template.id] != 0 {
                    
                    Text("\(template.name)")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.footnote)
                        .frame(width: 60)
                }
            }
        }
    }
    var dosagesTemplates: some View {
        HStack{
            ForEach(dosageTemplates){ template in
                if dosageTemplateCounter[template.id] != 0 {
                    Text("\(template.name ?? "")")
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.footnote)
                        .frame(width: 60)
                }
            }
        }
    }
}
