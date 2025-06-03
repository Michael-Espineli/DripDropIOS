

import SwiftUI
@MainActor
final class VehicalPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private (set) var vehicals:[Vehical] = []
    func onLoad(companyId:String) async throws {
        self.vehicals = try await dataService.getAllVehicals(companyId: companyId)
    }
}
struct VehicalPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : VehicalPickerViewModel
    @Binding var vehical : Vehical
    
    init(dataService:any ProductionDataServiceProtocol,vehical:Binding<Vehical>){
        _VM = StateObject(wrappedValue: VehicalPickerViewModel(dataService: dataService))
        
        self._vehical = vehical
    }
    @State var addVehical:Bool = false

    @State var search:String = ""
    @State var customers:[Customer] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Vehical Picker")
                    .font(.headline)
                Rectangle()
                    .frame(height: 1)
                ForEach(VM.vehicals){ datum in
                    Button(action: {
                        vehical = datum
                        dismiss()
                    }, label: {
                        HStack{
                            if vehical == datum {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.poolGreen)
                            } else {
                                
                                    Image(systemName: "circle")
                                        .foregroundColor(Color.gray)
                            }
                            VStack{
                                HStack{
                                    Spacer()
                                    Text("\(datum.nickName)")
                                    
                                    Spacer()
                                }
                                HStack{
                                    Text("\(datum.year)  \(datum.make) - \(datum.model)")
                                }
                                
                                HStack{
                                    Text("\(datum.color) \(datum.plate) \(datum.vehicalType.rawValue)")
                                }
                            }
                            .padding(.horizontal,8)
                            .foregroundColor(Color.basicFontText)
                            .modifier(ListButtonModifier())
                        }
                    })
                    Rectangle()
                        .frame(height: 1)
                }
                Button(action: {
                    addVehical.toggle()
                }, label: {
                    Text("Add Vehical")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $addVehical, onDismiss: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.onLoad(companyId: currentCompany.id)
                            } catch {
                                print("Vehical Picker Error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    AddNewVehical(dataService: dataService)
                })
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id)
                } catch {
                    print("Vehical Picker Error")
                    print(error)
                }
            }
        }
    }
}
