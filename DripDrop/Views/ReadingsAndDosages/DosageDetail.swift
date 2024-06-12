//
//  DosageDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI

struct DosageDetail: View {
    @StateObject var settingsVM = SettingsViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var dosageTemplate:DosageTemplate? = nil
    var body: some View {
        ScrollView{
            content
        }
        .padding(10)

        .task {
            //Set local dosage Template equal to globally selected dosage template
            dosageTemplate = masterDataManager.selectedDosageTemplate
            
        }
        //Watch the globally selected dosage template for changes, to update screen to reflect that
        .onChange(of: masterDataManager.selectedDosageTemplate, perform: { template in
            dosageTemplate = template
        })
    }
}

struct DosageDetail_Previews: PreviewProvider {
    static var previews: some View {
        DosageDetail()
    }
}
extension DosageDetail {
    var content: some View {
        VStack{
            if let template = dosageTemplate {
                ZStack{
                    Text("\(template.name ?? "name")")
                    HStack{
                        Spacer()
                        Button(action: {
                            print("Edit Dosage Detail View")
                        }, label: {
                            Image(systemName: "square.and.pencil")
                        })
                    }
                }
                VStack{
                    Text("\(template.UOM ?? "UOM")")
                    Text("Rate: \(Double(template.rate ?? "0") ?? 0, format: .currency(code: "USD").precision(.fractionLength(0)))")

                }
                        ScrollView(.horizontal){
                            HStack{

                            Button(action: {
                                
                            }, label: {
                                Image(systemName: "plus.app.fill")
                                    .foregroundColor(Color.accentColor)
                                    .font(.headline)
                            })
                        ForEach(template.amount ?? ["no Amounts Added"],id: \.self){ amount in
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
