//
//  StopDataDosageInputView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct StopDataDosageInputView: View {
    @Binding var stopDataList:[StopData]
    var template:DosageTemplate
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
    var body: some View {
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
                if selectedId == template.id {
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
                                    .cornerRadius(8)
                                    .background(Color.gray.opacity(0.5)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(8))
                                    .keyboardType(.decimalPad)
                                ForEach(template.amount ?? [],id:\.self){ amount in
                           
                                    Button(action: {
                                        input = amount
                                    }, label: {
                                        let suffix = amount.suffix(3)
                                        
                                        var endCharecter:String? = nil
                                        if suffix == ".00" {
                                            if let dosage = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))")
                                                        .padding(8)
                                                        .background(Color.poolGreen)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))")
                                                        .padding(8)
                                                        .background(Color.gray)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))")
                                                    .padding(8)
                                                    .background(Color.gray)
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(8)
                                            }

                                        } else if suffix == ".25" {
                                            if let dosage = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))¼")
                                                        .padding(8)
                                                        .background(Color.poolGreen)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))¼")
                                                        .padding(8)
                                                        .background(Color.gray)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))¼")
                                                    .padding(8)
                                                    .background(Color.gray)
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(8)
                                            }
                                        } else if suffix == ".50" {
                                            if let dosage = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))½")
                                                        .padding(8)
                                                        .background(Color.poolGreen)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))½")
                                                        .padding(8)
                                                        .background(Color.gray)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))½")
                                                    .padding(8)
                                                    .background(Color.gray)
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(8)
                                            }
                                        } else if suffix == ".75" {
                                            if let dosage = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(String(amount.dropLast(3)))¾")
                                                        .padding(8)
                                                        .background(Color.poolGreen)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                } else {
                                                    Text("\(String(amount.dropLast(3)))¾")
                                                        .padding(8)
                                                        .background(Color.gray)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                }
                                            } else {
                                                
                                                Text("\(String(amount.dropLast(3)))¾")
                                                    .padding(8)
                                                    .background(Color.gray)
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(8)
                                            }
                                        } else {
                                            if let dosage = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                                if dosage.amount == amount {
                                                    Text("\(amount)")
                                                        .padding(8)
                                                        .background(Color.poolGreen)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                } else {
                                                    Text("\(amount)")
                                                        .padding(8)
                                                        .background(Color.gray)
                                                        .foregroundColor(Color.white)
                                                        .cornerRadius(8)
                                                }
                                            } else {
                                                
                                                Text("\(amount)")
                                                    .padding(8)
                                                    .background(Color.gray)
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(8)
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
                            if let reading = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .padding(5)
                        .background(Color.gray)
                        .foregroundColor(Color.white)
                        .cornerRadius(5)
                        .padding(5)
                    } else {
                        HStack{
                            Text(template.name ?? "")
                            if let reading = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .padding(5)
                        .background(Color.poolGreen.opacity(0.5))
                        .foregroundColor(Color.white)
                        .cornerRadius(5)
                        .padding(5)
                    }

                }
            }
            .padding(EdgeInsets(top: 0, leading: 30, bottom: 5, trailing: 0))
            
            
        }
        .onAppear(perform: {
            if stopDataList.contains(where: {$0.bodyOfWaterId == bodyOfWaterId}){
                stopData = stopDataList.first(where: {$0.bodyOfWaterId == bodyOfWaterId })!
                if let reading = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == bodyOfWaterId}) {
                    input = reading.amount ?? ""
                } else {
                    input = ""

                }
               
            }
            prediction = getChemicalDosages(gallons:gallons,dosageTempalte: template, readings: stopData.readings, observations: observations)
        })

        .onTapGesture {
            selectedId = template.id
        }
        .onChange(of: bodyOfWaterId, perform: { id in
            if stopDataList.contains(where: {$0.bodyOfWaterId == id}){
                stopData = stopDataList.first(where: {$0.bodyOfWaterId == id })!
                if let reading = stopData.dosages.first(where: {$0.templateId == template.id && $0.bodyOfWaterId == id}) {
                    input = reading.amount ?? ""
                } else {
                    input = ""

                }
               
            }
        })
        .onChange(of: input, perform: { change in
            if let dosage = stopData.dosages.first(where: {$0.templateId == template.id}) {
                if let index = selectedIdList.firstIndex(where: {$0 == selectedId}) {
                    let totalIndex = selectedIdList.count - 1
                    if index == totalIndex {
                        selectedId = ""
                    } else {
                        let newIndex = index + 1
                        selectedId = selectedIdList[newIndex]
                    }
                }
                stopData.dosages.removeAll(where: {$0.templateId == template.id})
                stopData.dosages.append(Dosage(id: UUID().uuidString,
                                               templateId: template.id,
                                               name: template.name,
                                               amount: change,
                                               UOM: template.UOM,
                                               rate: template.rate,
                                               linkedItem: template.linkedItemId,
                                               bodyOfWaterId: bodyOfWaterId))
            } else {
                if let index = selectedIdList.firstIndex(where: {$0 == selectedId}) {
                    let totalIndex = selectedIdList.count - 1
                    if index == totalIndex {
                        selectedId = ""
                    } else {
                        let newIndex = index + 1
                        selectedId = selectedIdList[newIndex]
                    }
                }
                stopData.dosages.append(Dosage(id: UUID().uuidString,
                                               templateId: template.id,
                                               name: template.name,
                                               amount: change,
                                               UOM: template.UOM,
                                               rate: template.rate,
                                               linkedItem: template.linkedItemId,
                                               bodyOfWaterId: bodyOfWaterId))
            }
            
            
        })
        .onChange(of: stopData.readings, perform: { change in
            prediction = getChemicalDosages(gallons:gallons,dosageTempalte: template, readings: change, observations: observations)

        })
            .onChange(of: observations, perform: { change in
                prediction = getChemicalDosages(gallons:gallons,dosageTempalte: template, readings: stopData.readings, observations: change)
            })
    }
}

private extension StopDataDosageInputView {
    func getChemicalDosages(gallons:Int,dosageTempalte:DosageTemplate,readings:[Reading]?,observations:[String])->  String {
        
        return recommendationChems(gallons: Double(gallons), dosageTemplate: dosageTempalte, readingList: readings ?? [], hasAlgea: observations.contains(where: {$0 == "Algea"}))
        
    }
}
