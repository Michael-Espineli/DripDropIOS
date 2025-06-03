//
//  EditDataBaseItemFromReceiptView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/29/23.
//





import SwiftUI
@MainActor
final class EditDataBaseItemFromReceiptViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var stores:[Vender] = []

    @Published var name:String = ""
    @Published var rate:String = ""
    @Published var store:Vender = Vender(id: "",address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))

    @Published var storeId:String = ""
    @Published var storeName:String = ""

    @Published var category:DataBaseItemCategory = .misc
    @Published var subCategory:DataBaseItemSubCategory = .misc
    @Published var UOM:UnitOfMeasurment = .unit

    @Published var description:String = ""
    @Published var color:String = ""
    @Published var size:String = ""

    @Published var dateUpdated:Date = Date()
    @Published var billable:Bool = true

    @Published var sku:String = ""
    func onLoad(companyId:String) async throws {
        self.stores = try await dataService.getAllStores(companyId: companyId)
    }
    func addDataBaseItem(companyId:String) async throws{
        guard let rateDouble = Double(rate) else {
            throw FireBasePublish.unableToPublish
        }
        let dataBaseItem = DataBaseItem(
            id: "comp_sett_db_" + UUID().uuidString,
            name: name,
            rate: rateDouble,
            storeName: storeName,
            venderId: storeId,
            category: category,
            subCategory: subCategory,
            description: description,
            dateUpdated: dateUpdated,
            sku: sku,
            billable: billable,
            color: color,
            size: size,
            UOM: UOM
        )
        try await DatabaseManager.shared.uploadDataBaseItem(companyId: companyId, dataBaseItem: dataBaseItem)
        //Clear
    }
}
struct EditDataBaseItemFromReceiptView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : EditDataBaseItemFromReceiptViewModel

    init(dataService: any ProductionDataServiceProtocol,newItemView:Binding<Bool>){
        _VM = StateObject(wrappedValue: EditDataBaseItemFromReceiptViewModel(dataService: dataService))
        self._newItemView = newItemView
    }
    @Binding var newItemView:Bool
    
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    newItemView = false
                }, label: {
                    Image(systemName: "xmark")
                })
            }
            ScrollView{
                HStack{
                    Text("name")
                    TextField(
                        "012345",
                        text: $VM.name
                    ).padding()

                    Text("sku")
                    TextField(
                        "sku",
                        text: $VM.sku
                    ).padding()
                }
                HStack{
                    Text("rate")
                    TextField(
                        "rate",
                        text: $VM.rate
                    ).padding()
                    Toggle("Billable", isOn: $VM.billable)

                }
                Picker("", selection: $VM.category) {
                    Text("Pick Category").tag("Tech")
                    ForEach(DataBaseItemCategory.allCases,id:\.self) { UOM in
                        Text(UOM.rawValue).tag(UOM)
                    }
                }
                HStack{

                    Picker("", selection: $VM.subCategory) {
                        Text("Pick Sub-Category").tag("Sub")
                        ForEach(DataBaseItemSubCategory.allCases,id:\.self) { UOM in
                            Text(UOM.rawValue).tag(UOM)
                        }
                    }
                }
                HStack{
                    Text("UOM: ")
                    Picker("", selection: $VM.UOM) {
                        Text("Pick UOM").tag("Tech")
                        ForEach(UnitOfMeasurment.allCases,id:\.self) { UOM in
                            Text(UOM.rawValue).tag(UOM)
                        }
                    }
                }
                HStack{
                    Text("Store: ")
                    
                    Picker("", selection: $VM.store) {
                        Text("Pick store")
                        ForEach(VM.stores) {
                            
                            Text($0.name ?? "no Name").tag($0)
                            
                        }
                    }
                }
                HStack{
                    Text("Size: ")
                    TextField(
                        "Size...",
                        text: $VM.size
                    ).padding()
                }
                HStack{
                    Text("Color: ")
                    TextField(
                        "Color...",
                        text: $VM.color
                    ).padding()
                }
                HStack{
                    Text("Description: ")
                    TextField(
                        "Description...",
                        text: $VM.description
                    ).padding()
                }
                
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.addDataBaseItem(companyId: currentCompany.id)
                                newItemView = false
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Text("Submit")
                        .modifier(SubmitButtonModifier())

                })
                
            }
        }
        .padding(.init(top: 40, leading: 8, bottom: 0, trailing: 8))
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id)
                } catch {
                    print(error)
                }
            }
        }
        .navigationTitle("Add Item To DataBase")
    }
    
}

