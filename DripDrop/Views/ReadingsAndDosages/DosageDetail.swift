//
//  DosageDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI

struct DosageDetail: View {
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var dosageTemplate:SavedDosageTemplate?
    @State var isSaved:Bool = false
    var body: some View {
        ScrollView{
            content
        }
        .padding(8)
        .navigationTitle("\(dosageTemplate?.name ?? "name")")
        .task {
            //Set local dosage Template equal to globally selected dosage template
            if !UIDevice.isIPhone {
                dosageTemplate = masterDataManager.selectedDosageTemplate
            }
        }
        
        //Watch the globally selected dosage template for changes, to update screen to reflect that
        .onChange(of: masterDataManager.selectedDosageTemplate, perform: { template in
            if !UIDevice.isIPhone {
                dosageTemplate = template
            }
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
                            isSaved.toggle()

                        }, label: {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
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
                Text("No Dosage Template Selected")
            }
        }
    }
}
