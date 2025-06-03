//
//  EditDataBaseItemView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/23/23.
//

import SwiftUI
import Combine

struct EditDataBaseItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    init(dataService: any ProductionDataServiceProtocol,dataBaseItem:DataBaseItem){
        _viewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
        _settingsVM = StateObject(wrappedValue: SettingsViewModel(dataService: dataService))
        _dataBaseItem = State(wrappedValue: dataBaseItem)

    }
    @StateObject private var viewModel : ReceiptDatabaseViewModel
    @StateObject var settingsVM : SettingsViewModel

    @State var dataBaseItem:DataBaseItem
    
    @State var name:String = ""
    @State var rate:String = ""
    @State var storeName:String = ""
    @State var storeId:String = ""
    @State var category:DataBaseItemCategory = .misc
    @State var subCategory:DataBaseItemSubCategory = .misc
    
    @State var description:String = ""
    @State var dateUpdated:Date = Date()
    
    @State var sku:String = ""
    @State var billable:Bool = false
    @State var color:String = ""
    @State var size:String = ""
    
    //Optional
    @State var UOM:UnitOfMeasurment = .unit
    @State var sellPrice:String = ""
    @State var tracking:String = ""
    @State var trackingName:String = ""

    @State var template:DosageTemplate = DosageTemplate(id: "", name: "", amount: [], UOM: "", rate: "", linkedItemId: "", strength: 0, editable: false, chemType: "", order: 1)
    
    @State var showDosagePicker:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    HStack{
                        if name != dataBaseItem.name || rate != String(dataBaseItem.rate) || storeName != dataBaseItem.storeName || storeId != dataBaseItem.venderId || category != dataBaseItem.category || description != dataBaseItem.description || dateUpdated != dataBaseItem.dateUpdated || sku != dataBaseItem.sku || billable != dataBaseItem.billable || color != dataBaseItem.color || size != dataBaseItem.size || subCategory == dataBaseItem.subCategory || UOM == dataBaseItem.UOM || sellPrice == String(dataBaseItem.sellPrice ?? 0) || tracking == dataBaseItem.tracking ?? ""{
                            Button(action: {
                                Task{
                                    if let company = masterDataManager.currentCompany {
                                        do {
                                            try await viewModel.updateDataBaseItem(dataBaseItem: dataBaseItem, companyId: company.id, name: name, rate: Double(rate)!, category: category, description: description, sku: sku, billable: billable, color: color, size: size,sellPrice: Double(sellPrice)!,UOM: UOM, subCategory: subCategory, tracking: tracking) //DEVELOPER REMOVE EXPLICIT
                                            dismiss()
                                        } catch {
                                            print("Error Uploading Data Base Item")
                                        }
                                    }
                                }
                            }, label: {
                                Text("Save Changes")
                                    .modifier(SubmitButtonModifier())

                            })
                        }
                        Spacer()
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonTextModifier())
                        })
                        .modifier(DismissButtonModifier())
                    }
                    .padding(.vertical,8)
                    HStack{
                        Text("Name: ")
                        TextField(
                            "Name",
                            text: $name
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    }
                    HStack{
                        Text("Sku: ")
                        TextField(
                            "Sku",
                            text: $sku
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    }
                    HStack{
                        Text("Store: ")
                        Text("\(storeName)")
                        
                    }
                    HStack{
                        Picker("", selection: $category) {
                            Text("Pick tech").tag("Tech")
                            ForEach(DataBaseItemCategory.allCases,id:\.self) { UOM in
                                Text(UOM.rawValue).tag(UOM)
                            }
                        }
                        subCategoryPicker

                    }
                    HStack{
                        Text("Color: ")
                        TextField(
                            "Color",
                            text: $color
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    }
                    HStack{
                        Text("UOM: ")
                        Picker("", selection: $UOM) {
                            Text("Pick tech").tag("Tech")
                            ForEach(UnitOfMeasurment.allCases,id:\.self) { UOM in
                                Text(UOM.rawValue).tag(UOM)
                            }
                        }
                        Text("Size: ")
                        TextField(
                            "size",
                            text: $size
                        )
                        .keyboardType(.decimalPad)
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    }
                    HStack{
                        Text("Rate : $")
                        TextField("#", text: $rate)
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            .onReceive(Just(rate)) { newValue in
                                let filtered = newValue.filter { ".0123456789".contains($0) }
                                if filtered != newValue {
                                    self.rate = filtered
                                }
                                if filtered.numberOfOccurrencesOf(string: ".") > 1{
                                    self.rate = ""
                                }
                            }
                        Text("Billable")
                        Button(action: {
                            if billable {
                                billable = false
                                
                            }else {
                                billable = true
                            }
                        }, label: {
                            if billable {
                                Image(systemName: "checkmark.square")
                            }else {
                                Image(systemName: "square")
                            }
                        })
                    }
                    if billable {
                        HStack{
                            Text("Sell Price : $")
                            TextField("#", text: $sellPrice)
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .onReceive(Just(rate)) { newValue in
                                    let filtered = newValue.filter { ".0123456789".contains($0) }
                                    if filtered != newValue {
                                        self.rate = filtered
                                    }
                                    if filtered.numberOfOccurrencesOf(string: ".") > 1{
                                        self.rate = ""
                                    }
                                }
                        }
                    }
                    HStack{
                        Text("Tracking: \(template.name ?? "")")
                        Spacer()
                        Button(action: {
                            self.showDosagePicker.toggle()
                        }, label: {
                            if tracking == "" {
                                Text("Contect To tracking")
                            } else {
                                Text("Change")
                            }
                        })
                    }
                    .sheet(isPresented: $showDosagePicker, onDismiss: {
                        print("On Dismiss")
                        
                        tracking = template.id
                        print("Tracking ID: \(template.id)")
                    }, content: {
                        DosageTemplatePicker(template: $template)
                    })
                    HStack{
                        Text("Description: ")
                        TextField(
                            "Description",
                            text: $description,
                            axis: .vertical
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                    }
                    
                }
                .padding(.horizontal,16)
            }
        }
        .onAppear(perform:{
            
            name = dataBaseItem.name
            rate = String(dataBaseItem.rate)
            storeName = dataBaseItem.storeName
            storeId = dataBaseItem.venderId
            category = dataBaseItem.category
            description = dataBaseItem.description
            dateUpdated = dataBaseItem.dateUpdated
            sku = dataBaseItem.sku
            billable = dataBaseItem.billable
            color = dataBaseItem.color
            size = dataBaseItem.size
            
            subCategory = dataBaseItem.subCategory
            UOM = dataBaseItem.UOM
            sellPrice = String(dataBaseItem.sellPrice ?? 0)
            tracking = dataBaseItem.tracking ?? ""
            
        })
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await settingsVM.getDosageTemplates(companyId: company.id)
                    if let trackingId = dataBaseItem.tracking {
                        if trackingId != "" {
                            if let dosageTemplate = settingsVM.dosageTemplates.first(where: {$0.id == trackingId}) {
                                template = dosageTemplate
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension EditDataBaseItemView {
    var subCategoryPicker : some View {
        VStack{
            Picker("", selection: $subCategory) {
                Text("Pick tech").tag("Tech")
                ForEach(DataBaseItemSubCategory.allCases,id:\.self) { UOM in
                    Text(UOM.rawValue).tag(UOM)
                }
            }
//            switch category {
//            case .pvc:
//                Picker("", selection: $subCategory) {
//                    Text("Pick Sub Category").tag(DataBaseItemSubCategoryPVC.misc)
//                    ForEach(DataBaseItemSubCategoryPVC.allCases,id:\.self) { UOM in
//                        Text(UOM.rawValue).tag(DataBaseItemSubCategoryPVC(rawValue: UOM.rawValue))
////                            .tag(UOM)
//                    }
//                }
//            
//            case .galvanized:
//                Text("")
//            case .chems:
//                Text("")
//
//            case .useables:
//                Text("")
//
//            case .equipment:
//                Text("")
//
//            case .parts:
//                Text("")
//
//            case .electrical:
//                Text("")
//
//            case .tools:
//                Text("")
//
//            case .misc:
//                Text("")
//
//            }
        }
    }
}
