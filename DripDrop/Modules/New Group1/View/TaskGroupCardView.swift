//
//  TaskGroupCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import SwiftUI

struct TaskGroupCardView: View {
    @State var taskGroup : JobTaskGroup
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Text("\(taskGroup.name)")
                    .font(.headline)
                Spacer()
            }
            HStack{
                Text("\(String(taskGroup.numberOfTasks))")
                    .font(.footnote)
                Text("\(taskGroup.description)")
                    .font(.footnote)
            }
        }
        .modifier(ListButtonModifier())
        .padding(8)
    }
}

//#Preview {
//    TaskGroupCardView()
//}
