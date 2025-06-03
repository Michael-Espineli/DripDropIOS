//
//  EquipmentStatusPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/25/25.
//



import SwiftUI
@MainActor
final class EquipmentStatusPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
struct EquipmentStatusPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : EquipmentStatusPickerViewModel
    @Binding var status : EquipmentStatus
    
    init(dataService:any ProductionDataServiceProtocol,status:Binding<EquipmentStatus>){
        _VM = StateObject(wrappedValue: EquipmentStatusPickerViewModel(dataService: dataService))
        
        self._status = status
    }
    
    @State var search:String = ""
    @State var customers:[Customer] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ForEach(EquipmentStatus.allCases){ datum in
                    Button(action: {
                        status = datum
                        dismiss()
                    }, label: {
                        HStack{
                            Spacer()
                                Text("\(datum.rawValue)")
                            Spacer()
                        }
                        .padding(.horizontal,8)
                        .foregroundColor(Color.basicFontText)
                    })
                    Divider()
                }
            }
        }
    }
}
