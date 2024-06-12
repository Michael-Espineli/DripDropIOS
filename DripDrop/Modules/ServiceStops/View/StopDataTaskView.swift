//
//  StopDataTaskView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/22/23.
//


import SwiftUI

struct StopDataTaskView: View {
    var stop:ServiceStop
    @State var taskOptions:[String] = ["Brush","Net","Vacuum","Empty Baskets"]
    @Binding var selectedTasks:[String]
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    @State var input:String = ""
    var body: some View {
        ZStack{
            HStack{
                if selectedTasks.count < 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 5)
                } else {
                    Rectangle()
                        .fill(Color.poolGreen)
                        .frame(width: 5)
                }
                VStack{
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack{
                            HStack{
                                Button(action: {
                                    selectedTasks.append(input)
                                    selectedTasks.removeDuplicates()
                                    input = ""
                                }, label: {
                                    Image(systemName: "plus")
                                    
                                })
                                TextField("Custom", text: $input)
                            }
                                .padding(5)
                                .background(Color.gray.opacity(0.5)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(10))
                                                        
                            ForEach(taskOptions,id:\.self){ task in
                                Button(action: {
                                    selectedTasks.append(task)
                                    selectedTasks.removeDuplicates()
                                }, label: {
                                    Text("\(task)")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.blue)
                                        .cornerRadius(20)
                                })
                            }
                            
                        }
                    }
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))

                    LazyVGrid(columns: columns) {
                        ForEach(selectedTasks,id:\.self){ task in
                            
                            HStack{
                                Button(action: {
                                    selectedTasks.removeAll(where: {$0 == task})
                                }, label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color.white)
                                })
                                Text("\(task)")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(5)
                            .background(Color.poolGreen)
                            .cornerRadius(20)
                        }
                        //your view with image will come here
                    }
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

                }
                .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))

            }
            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))

        }
    }
}
