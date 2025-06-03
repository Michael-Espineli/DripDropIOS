//
//  JobTaskTypePicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import SwiftUI

struct JobTaskTypePicker: View {
    @Binding var taskType: JobTaskType
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                ForEach(JobTaskType.allCases, id:\.self){ type in
                    Text(type.rawValue).tag(type)
                        .modifier(ListButtonModifier())
                }
                .padding(8)
            }
            .padding(16)
        }
    }
}

//#Preview {
//    JobTaskTypePicker()
//}
