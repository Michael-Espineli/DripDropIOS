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


    var body: some View {
        /*
         //Old View
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
                                .focused($chemicalInput)
                                .modifier(TextFieldModifier())
                                .modifier(OutLineButtonModifier())
                            ForEach(template.amount,id:\.self){ amount in
                                Button(action: {
                                    input = amount
                                }, label: {
                                    if let reading = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
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
                            if let reading = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .modifier(ListButtonModifier())
                    } else {
                        HStack{
                            Text(template.name)
                            if let reading = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                                Text(" - \(reading.amount ?? "")")
                            }
                        }
                        .modifier(SubmitButtonModifier())
                    }
                }
                
            }
            .padding(EdgeInsets(top: 0, leading: 28, bottom: 5, trailing: 0))
        }
         */
        ZStack {

            // MARK: - Left Status Indicator
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(input == "" ? Color.gray.opacity(0.25) : Color.poolGreen)
                    .frame(width: 6)
                Spacer()
            }
            .padding(.leading, 12)

            VStack {

                if selectedId == template.readingsTemplateId {

                    HStack {
                        Text(template.name)
                            .font(.footnote.weight(.semibold))
                        Spacer()
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(template.amount, id: \.self) { amount in
                                Button(action: {
                                    input = amount
                                }, label: {
                                    if let reading = stopData.readings.first(where: {
                                        $0.universalTemplateId == template.readingsTemplateId &&
                                        $0.bodyOfWaterId == bodyOfWaterId
                                    }) {
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
                            TextField("Input", text: $input)
                                .focused($chemicalInput)
                                .modifier(TextFieldModifier())
                                .modifier(OutLineButtonModifier())
                        }
                    }

                } else {
                    if input == "" {
                        HStack {
                            Text(template.name)
                                .font(.footnote.weight(.medium))

                            if let reading = stopData.readings.first(where: {
                                $0.universalTemplateId == template.readingsTemplateId &&
                                $0.bodyOfWaterId == bodyOfWaterId
                            }) {
                                Text("• \(reading.amount ?? "")")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .modifier(ListButtonModifier())

                    } else {

                        HStack {
                            Text(template.name)
                                .font(.footnote.weight(.medium))

                            if let reading = stopData.readings.first(where: {
                                $0.universalTemplateId == template.readingsTemplateId &&
                                $0.bodyOfWaterId == bodyOfWaterId
                            }) {
                                Text("• \(reading.amount ?? "")")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    }
                }
            }
            .padding(.leading, 30)
            .padding(.vertical, 10)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.listColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.05))
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

        .onChange(of: stopData, perform: { datum in
            if let reading = datum.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                input = reading.amount ?? ""
            } else {
                input = ""
            }
        })
        .onAppear(perform: {
            if let reading = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                input = reading.amount ?? ""
            } else {
                input = ""
            }
        })
        .onChange(of: bodyOfWaterId, perform: { id in
            if let reading = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId && $0.bodyOfWaterId == bodyOfWaterId}) {
                input = reading.amount ?? ""
            } else {
                input = ""
            }
            
        })
        .onTapGesture {
            selectedId = template.readingsTemplateId
        }
        .onChange(of: selectedId, perform: { change in
            chemicalInput = false
        })
        .onChange(of: input, perform: { change in
            if !chemicalInput {
                if let dosage = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId}) {
                    if let index = selectedIdList.firstIndex(where: {$0 == selectedId}) {
                        let totalIndex = selectedIdList.count - 1
                        if index == totalIndex {
                            selectedId = ""
                        } else {
                            let newIndex = index + 1
                            selectedId = selectedIdList[newIndex]
                        }
                    }
                    stopData.readings.removeAll(where: {$0.universalTemplateId == template.readingsTemplateId})
                    stopData.readings.append(Reading(id: UUID().uuidString,
                                                     templateId: template.id,
                                                     universalTemplateId: template.readingsTemplateId,
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
                                                     templateId: template.id,
                                                     universalTemplateId: template.readingsTemplateId,
                                                     dosageType: template.chemType,
                                                     name: template.name,
                                                     amount: change,
                                                     UOM: template.UOM,
                                                     bodyOfWaterId: bodyOfWaterId))
                }
            }
        })
        .onChange(of: chemicalInput, perform: { change in
            if !change {
                if let dosage = stopData.readings.first(where: {$0.universalTemplateId == template.readingsTemplateId}) {
                    stopData.readings.removeAll(where: {$0.universalTemplateId == template.readingsTemplateId})
                    stopData.readings.append(Reading(id: UUID().uuidString,
                                                     templateId: template.id,
                                                     universalTemplateId: template.readingsTemplateId,
                                                     dosageType: template.chemType,
                                                     name: template.name,
                                                     amount: input,
                                                     UOM: template.UOM,
                                                     bodyOfWaterId: bodyOfWaterId))
                } else {
                    stopData.readings.append(Reading(id: UUID().uuidString,
                                                     templateId: template.id,
                                                     universalTemplateId: template.readingsTemplateId,
                                                     dosageType: template.chemType,
                                                     name: template.name,
                                                     amount: input,
                                                     UOM: template.UOM,
                                                     bodyOfWaterId: bodyOfWaterId))
                }
            }
        })
    }
}
