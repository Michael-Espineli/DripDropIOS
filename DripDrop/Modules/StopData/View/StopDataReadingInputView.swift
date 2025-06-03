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
                if selectedId == template.readingsTemplateId {
                    
                    HStack{
                        Text(template.name)
                            .font(.footnote)
                        Spacer()
                    }
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack(spacing: 8){

                            TextField("Input", text: $input)
                                .modifier(TextFieldModifier())
                                .modifier(OutLineButtonModifier())
                            ForEach(template.amount,id:\.self){ amount in
                                Button(action: {
                                    input = amount
                                }, label: {
                                    if let reading = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                        if reading.amount == amount {
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
                                })
                            }
                        }
                    }
                } else {
                    if input == "" {
                        HStack{
                            Text(template.name)
                            if let reading = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .modifier(ListButtonModifier())
                    } else {
                        HStack{
                            Text(template.name)
                            if let reading = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .modifier(SubmitButtonModifier())
                    }
                }
                
            }
            .padding(EdgeInsets(top: 0, leading: 28, bottom: 5, trailing: 0))
        }
        .onChange(of: stopData, perform: { datum in
            if let reading = datum.readings.first(where: {$0.templateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                input = reading.amount ?? ""
            } else {
                input = ""
            }
        })
        .onAppear(perform: {
                    if let reading = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                        input = reading.amount ?? ""
                    } else {
                        input = ""
                    }
            
        })
        .onChange(of: bodyOfWaterId, perform: { id in
                    if let reading = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                        input = reading.amount ?? ""
                    } else {
                        input = ""
                    }
            
        })
        .onTapGesture {
            selectedId = template.readingsTemplateId
        }
        .onChange(of: input, perform: { change in
            if let dosage = stopData.readings.first(where: {$0.templateId == template.readingsTemplateId}) {
                if let index = selectedIdList.firstIndex(where: {$0 == selectedId}) {
                    let totalIndex = selectedIdList.count - 1
                    if index == totalIndex {
                        selectedId = ""
                    } else {
                        let newIndex = index + 1
                        selectedId = selectedIdList[newIndex]
                    }
                }
                stopData.readings.removeAll(where: {$0.templateId == template.readingsTemplateId})
                stopData.readings.append(Reading(id: UUID().uuidString,
                                                 templateId: template.readingsTemplateId,
                                                 dosageType: template.chemType,
                                                 name: template.name,
                                                 amount: change,
                                                 UOM: template.UOM,
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
                stopData.readings.append(Reading(id: UUID().uuidString,
                                                 templateId: template.readingsTemplateId,
                                                 dosageType: template.chemType,
                                                 name: template.name,
                                                 amount: change,
                                                 UOM: template.UOM,
                                                 bodyOfWaterId: bodyOfWaterId))
            }
        })
    }
}
