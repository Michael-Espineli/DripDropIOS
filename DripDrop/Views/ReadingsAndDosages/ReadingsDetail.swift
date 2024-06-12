//
//  ReadingsDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI

struct ReadingsDetail: View {
    @StateObject var settingsVM = SettingsViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var readingTemplate:ReadingsTemplate? = nil
    var body: some View {
        ScrollView{
            content
        }
        .padding(10)
        .task {
            //Set local readingTemplate equal to globally selected reading template
            readingTemplate = masterDataManager.selectedReadingsTemplate
            
        }
        //Watch the globally selected reading tempalte for changes, to update screen to reflect that
        .onChange(of: masterDataManager.selectedReadingsTemplate, perform: { template in
            readingTemplate = template
        })
    }
}

struct ReadingsDetail_Previews: PreviewProvider {
    static var previews: some View {
        ReadingsDetail()
    }
}
extension ReadingsDetail {
    var content: some View {
        VStack{
            if let template = readingTemplate {
                ZStack{
                    Text("\(template.name)")
                    HStack{
                        Spacer()
                        Button(action: {
                            print("Edit Reading Detail View")
                        }, label: {
                            Image(systemName: "square.and.pencil")
                        })
                    }
                }
                VStack{
                    Text("\(template.UOM)")

                }
                    ScrollView(.horizontal){
                        HStack{

                        Button(action: {
                            
                        }, label: {
                            Image(systemName: "plus.app.fill")
                                .foregroundColor(Color.accentColor)
                                .font(.headline)
                        })
                        ForEach(template.amount,id: \.self){ amount in
                            Text("\(amount)")
                                .padding(10)
                        }
                    }
                }
            } else {
                Text("No Reading Template Selected")
            }
        }
    }
}
