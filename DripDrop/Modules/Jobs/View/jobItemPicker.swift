//
//  jobItemPicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/13/24.
//


import SwiftUI
@MainActor
final class JobItemPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var dataServiceDataBaseItems: [DataBaseItem] = []
    @Published private(set) var dataBaseItems: [DataBaseItem] = []
    @Published var filterTerm: String = ""
    @Published var quantityStr: String = ""
    @Published var quantity: Double = 0

    @Published var selectedDataBaseItem:DataBaseItem = DataBaseItem(
        id: "",
        name: "",
        rate: 0,
        storeName: "",
        venderId: "",
        category: .misc,
        subCategory: .misc,
        description: "",
        dateUpdated: Date(),
        sku: "",
        billable: true,
        color: "",
        size: "",
        UOM:.ft
    )
    
    func getAllDataBaseItemsByCategory(companyId:String,category:String) async throws{
        self.dataServiceDataBaseItems = try await DatabaseManager.shared.getAllDataBaseItemsByCategory(companyId: companyId, category: category)
        self.dataBaseItems = dataServiceDataBaseItems
    }
    func filterDataBaseList() {
        //very facncy Search Bar
        if filterTerm != "" {
            var filteredListOfCustomers:[DataBaseItem] = []
            for item in dataServiceDataBaseItems {
                let rateString = String(item.rate)
                
                if item.sku.lowercased().contains(
                    filterTerm.lowercased()
                ) || item.name.lowercased().contains(
                    filterTerm.lowercased()
                ) || rateString.lowercased().contains(
                    filterTerm.lowercased()
                ) || item.description.lowercased().contains(
                    filterTerm.lowercased()
                ) {
                    filteredListOfCustomers.append(item)
                }
            }
            
            self.dataBaseItems = filteredListOfCustomers
        } else {
            self.dataBaseItems = dataServiceDataBaseItems
        }
    }
}
struct jobItemPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : JobItemPickerViewModel
    
    @State var category:String
    @Binding var jobDBItems : WODBItem
    
    init(dataService:any ProductionDataServiceProtocol, jobDBItems:Binding<WODBItem>,category:String){
        _VM = StateObject(wrappedValue: JobItemPickerViewModel(dataService: dataService))
        self._jobDBItems = jobDBItems
        _category = State(wrappedValue: category)
    }
    var body: some View {
        VStack{
            if VM.selectedDataBaseItem.id == "" {
                dataBaseList
                searchBar
            } else {
                itemInfo
            }
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    if category != "" {
                        try await VM.getAllDataBaseItemsByCategory(companyId: company.id, category: category)
                    }
                }
            } catch {
                print("Error")

            }
        }
        .onChange(of: VM.filterTerm, perform: { term in
                VM.filterDataBaseList()
        })
    }
}
extension jobItemPicker {
    var itemInfo: some View {
        VStack{
            Button(action: {
                VM.selectedDataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .misc,subCategory: .misc, description: "", dateUpdated: Date(), sku: "", billable: true, color: "", size: "",UOM:.ft)
            }, label: {
                Text("Name: \(VM.selectedDataBaseItem.name) - \(String(VM.selectedDataBaseItem.rate)) - \(String(VM.selectedDataBaseItem.sellPrice ?? 0))")
                    
            })
            TextField(
                text: $VM.quantityStr,
                label: {
                    Text("Quantity: ")
                })
            .keyboardType(.decimalPad)
            Button(action: {
                if let quantity = Double(VM.quantityStr) {
                    let item = WODBItem(
                        id: UUID().uuidString,
                        name: VM.selectedDataBaseItem.name,
                        quantity: quantity,
                        cost: VM.selectedDataBaseItem.rate,
                        genericItemId: VM.selectedDataBaseItem.id
                    )
                    jobDBItems = item
                }
                dismiss()
            },
                   label: {
                Text("Add")
            })
        }
    }
    var searchBar: some View {
        HStack{
            TextField(
                text: $VM.filterTerm,
                label: {
                    Text("Search: ")
                })
            .modifier(SearchTextFieldModifier())
            .padding(8)

        }
        .foregroundColor(Color.white)
        .background(Color.darkGray)
    }
    var dataBaseList: some View {
        ScrollView{
            ForEach(VM.dataBaseItems){ datum in
                Button(action: {
                    VM.selectedDataBaseItem = datum
                }, label: {
                    HStack{
                        Text("\(datum.name)")
                    }
                    .padding(5)
                    .foregroundColor(Color.basicFontText)
                    .frame(maxWidth: .infinity)
                })
             Divider()
            }
        }
    }
}
