//
//  DataBaseItemPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/26/25.
//
@MainActor
final class DataBaseItemPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var dataBaseItems: [DataBaseItem] = []
    @Published var filteredDataBaseItems: [DataBaseItem] = []
    @Published var searchTerm: String = ""
    
    func onLoad(companyId:String) async throws {
        self.filteredDataBaseItems = try await dataService.getAllDataBaseItems(companyId: companyId)
        self.dataBaseItems = filteredDataBaseItems
    }
    func searchFunction() {
        if searchTerm != "" {
            var filteredItems:[DataBaseItem] = []
            for item in dataBaseItems {
                if item.name.lowercased().contains(searchTerm.lowercased()) || item.sku.lowercased().contains(searchTerm.lowercased()) || item.description.lowercased().contains(searchTerm.lowercased()) || item.color.lowercased().contains(searchTerm.lowercased()) || item.category.rawValue.lowercased().contains(searchTerm.lowercased()) {
                    filteredItems.append(item)
                }
            }
            self.filteredDataBaseItems = filteredItems
        } else {
            self.filteredDataBaseItems = dataBaseItems
        }
    }
}
import SwiftUI

struct DataBaseItemPicker: View {
    init(
        dataService:any ProductionDataServiceProtocol,
        DBItem:Binding<DataBaseItem>,
        category:DataBaseItemCategory
    ){
        _VM = StateObject(wrappedValue: DataBaseItemPickerViewModel(dataService: dataService))
        self._DBItem = DBItem
        _category = State(wrappedValue: category)
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : DataBaseItemPickerViewModel
    @State var category : DataBaseItemCategory
    @Binding var DBItem : DataBaseItem
    
    @State var showAddNew : Bool = false

        var body: some View {
        VStack{
            dataBaseList
            searchBar
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id)
                }
            } catch {
                print("Error")
                print(error)
            }
        }
        .onChange(of: VM.searchTerm, perform: { term in
            VM.searchFunction()
        })
    }
}
extension DataBaseItemPicker {
    var searchBar: some View {
        HStack{
            TextField(
                text: $VM.searchTerm,
                label: {
                    Text("Search: ")
                })
            .modifier(TextFieldModifier())
            .modifier(OutLineButtonModifier())
            Button(action: {
                VM.searchTerm = ""
            }, label: {
                Image(systemName: "xmark")
            })
        }
        .modifier(ListButtonModifier())
        .modifier(OutLineButtonModifier())
        .padding(8)
    }
    var dataBaseList: some View {
        ScrollView{
            ForEach(VM.filteredDataBaseItems){ datum in
                Button(action: {
                    DBItem = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Text("\(datum.name)")
                        Spacer()
                    }
                })
                .modifier(ListButtonModifier())
            }
            Button(action: {
                showAddNew.toggle()
            }, label: {
                HStack{
                    Spacer()
                    Text("Add New Item")
                    Spacer()
                }
                .modifier(BlueButtonModifier())
            })
            .sheet(isPresented: $showAddNew, onDismiss: {
                
            }, content: {
                AddNewDatabaseItem(dataService: dataService)
            })
        }
    }
}

