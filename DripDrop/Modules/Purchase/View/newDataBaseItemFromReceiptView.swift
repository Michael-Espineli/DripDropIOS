//
//  newDataBaseItemFromReceiptView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/22/23.
//

import SwiftUI
@MainActor
final class NewDataBaseItemFromReceiptViewModel:ObservableObject{
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
    @Published var sellPrice:String = ""

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


struct newDataBaseItemFromReceiptView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : NewDataBaseItemFromReceiptViewModel

    init(dataService: any ProductionDataServiceProtocol,newItemView:Binding<Bool>,id:String){
        _VM = StateObject(wrappedValue: NewDataBaseItemFromReceiptViewModel(dataService: dataService))
        self._newItemView = newItemView
        _id = State(wrappedValue: id)
    }
    @State var id:String
    @Binding var newItemView:Bool
    @FocusState private var focusedField: NewDataBaseFormLabels?

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    HStack{
                        Spacer()
                        Button(action: {
                            newItemView = false
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonModifier())
                        })
                    }
                    HStack{
                        Text("Name")
                        TextField(
                            "Name...",
                            text: $VM.name
                        )
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .name)
                             .submitLabel(.next)
                    }
                    HStack{
                        Text("Sku")
                        TextField(
                            "Sku...",
                            text: $VM.sku
                        )
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .sku)
                             .submitLabel(.next)
                    }
                    HStack{
                        Text("Rate")
                        TextField(
                            "Rate...",
                            text: $VM.rate
                        )
                        .keyboardType(.decimalPad)
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .rate)
                             .submitLabel(.next)
                    }
                    HStack{
                        Text("Sell Price")
                        TextField(
                            "Sell Price...",
                            text: $VM.sellPrice
                        )
                        .keyboardType(.decimalPad)
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .sellPrice)
                             .submitLabel(.next)
                    }
                    HStack{
                        Text("Store")
                        
                        Picker("", selection: $VM.store) {
                            Text("Pick store")
                            ForEach(VM.stores) {
                                
                                Text($0.name ?? "no Name").tag($0)
                                
                            }
                        }
                    }
                }
                //DEVELOPER MAKE THESE CATEGORIES CHANGEABLE
                VStack{
                    Picker("", selection: $VM.category) {
                        Text("Pick tech").tag("Tech")
                        ForEach(DataBaseItemCategory.allCases,id:\.self) { UOM in
                            Text(UOM.rawValue).tag(UOM)
                        }
                    }
                    HStack{

                        Picker("", selection: $VM.subCategory) {
                            Text("Pick tech").tag("Tech")
                            ForEach(DataBaseItemSubCategory.allCases,id:\.self) { UOM in
                                Text(UOM.rawValue).tag(UOM)
                            }
                        }
                    }
                    HStack{
                        Text("UOM: ")
                        Picker("", selection: $VM.UOM) {
                            Text("Pick tech").tag("Tech")
                            ForEach(UnitOfMeasurment.allCases,id:\.self) { UOM in
                                Text(UOM.rawValue).tag(UOM)
                            }
                        }
                    }
                    HStack{
                        Text("Size")
                        TextField(
                            "Size...",
                            text: $VM.size
                        )
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .size)
                             .submitLabel(.next)
                    }
                    HStack{
                        Text("Color")
                        TextField(
                            "Color...",
                            text: $VM.color
                        )
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .color)
                             .submitLabel(.next)
                    }
  
                    HStack{
                        Text("Description")
                        TextField(
                            "Description",
                            text: $VM.description
                        )
                        .modifier(TextFieldModifier())
                        .focused($focusedField, equals: .description)
                        .submitLabel(.done)
                    }
                    Toggle("Billable", isOn: $VM.billable)
                }
                Button(action: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                let id = UUID().uuidString
                                try await VM.addDataBaseItem(
                                    companyId: company.id
                                )
                                newItemView = false
                            } catch {
                                print(error)
                            }
                        }
                    }
                },
                       label: {
                    Text("Submit")
                        .modifier(SubmitButtonModifier())
                })
                
            }
            .padding(.init(top: 16, leading: 16, bottom: 0, trailing: 16))
            .onSubmit {
                switch focusedField {
                case .name:
                    focusedField = .sku
                case .sku:
                    focusedField = .rate
                    
                case .rate:
                    focusedField = .sellPrice
                    
                case .sellPrice:
                    focusedField = .size
                    
                case .size:
                    focusedField = .color
                    
                case .color:
                    focusedField = .description
                    
                case .description:
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                let id = UUID().uuidString
                                try await VM.addDataBaseItem(
                                    companyId: company.id
                                )
                                newItemView = false
                            } catch {
                                print(error)
                            }
                        }
                    }
                default:
                    focusedField = .description
                }
            }
        }
        .onAppear(perform: {
            VM.sku = id
        })
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
        .navigationTitle("Add Item To Data Base")
    }
}

