//
//  ToDoCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//

import SwiftUI

struct ToDoCardView: View {
    let toDo : ToDo
    var body: some View {
        HStack{
            Text("\(toDo.id)")
            Spacer()
            VStack{
                HStack{
                    Text("\(toDo.title)")
                }
                HStack{
                    Text("\(toDo.status.title())")
                    Text("\(fullDate(date:toDo.dateCreated))")

                }
            }
        }
        .padding(.leading)
    }
}

struct ToDoCardView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoCardView(toDo:  ToDo(id: "4", title: "Check the Dude Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""))
    }
}
