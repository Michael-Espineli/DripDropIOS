//
//  CustomRecurringStopSettingsView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI

struct CustomRecurringStopSettingsView: View {
    @Binding var customEvery:Int
    @Binding var customFrequency:String
    @Binding var selectedDays:[String]
    @State var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    var body: some View {
        
        VStack{
            HStack{
                Picker("Every", selection: $customEvery) {
                    ForEach(1...100, id: \.self) {
                        Text(String($0)).tag($0)
                    }
                }
                #if os(iOS)
                .pickerStyle(.wheel)
                #endif
                Picker("Appearance", selection: $customFrequency) {
                    Text("Daily").tag("Daily")
                    Text("Weekly").tag("Weekly")
                    Text("Monthly").tag("Monthly")
                    Text("Yearly").tag("Yearly")
                }
#if os(iOS)
.pickerStyle(.wheel)
#endif
                
            }
        }
    }
}
    extension CustomRecurringStopSettingsView {
        var daySelector: some View {
            VStack{
                ScrollView(.horizontal,showsIndicators: false){
                    HStack{
                        ForEach(days,id:\.self){ day in
                            Button(action: {
                                if selectedDays.contains(day) {
                                    selectedDays.removeAll(where: {$0 == day})
                                    print(selectedDays)
                                } else {
                                    selectedDays.append(day)
                                    print(selectedDays)
                                }
                            }, label: {
                                if selectedDays.contains(day) {
                                    Text("\(day)")
                                        .padding(5)
                                        .background(Color.green)
                                        .cornerRadius(5)
                                        .foregroundColor(Color.white)
                                } else {
                                    Text("\(day)")
                                        .padding(5)
                                        .background(Color.blue)
                                        .cornerRadius(5)
                                        .foregroundColor(Color.white)
                                }
                            })
                        }
                    }
                }
            }
        }
    }
