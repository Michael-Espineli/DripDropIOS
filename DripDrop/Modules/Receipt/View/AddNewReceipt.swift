    //
    //  AddNewReceipt.swift
    //  Pool-Sec-Mac-V2
    //
    //  Created by Michael Espineli on 7/22/23.
    //
import UIKit
import SwiftUI
import Darwin
import ContactsUI
@MainActor
final class AddNewReceiptViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var stores: [Vender] = []
    
    @Published private(set) var iamgeUrl: URL? = nil
    @Published private(set) var imageUrlString: String? = nil
    
    @Published var invoiceNum:String = ""
    @Published var date:Date = Date()
    @Published var storeId:String = ""
    @Published var storeName:String = ""
    
    @Published var companyUserId:String = ""
    @Published var companyUserName:String = ""
    
    @Published var quantity:String = ""
    
    @Published var linequantity = ""
    @Published var linename = ""
    @Published var linerate = ""
    @Published var linetotal = ""
    
    @Published var lineItems:[LineItem] = []
    
    @Published private(set) var dataServiceDataBaseItems: [DataBaseItem] = []
    @Published var displayItems: [DataBaseItem] = []
    
    @Published var pickerSelection: String = ""
    @Published var searchTerm: String = ""
    @Published var showingAlert = false
    
    @Published var alertMessage:String = ""
    @Published var receiptScreen:String = "receipt"
    
    
    @Published var showNewItem = false
    @Published var addItemToReceipt = false
    
    @Published var editLineItem = false
    @Published var editDataBaseItem = false
    @Published var showAddFileLogic = false
    
    @Published var pdfUrlStringList:[String] = []
    @Published var pdfUrlList:[URL] = []
    
    @Published var showDocumentpicker:Bool = false
    
    @Published var pickerType:FilePickerType? = nil
    @Published var selectedPickerType:FilePickerType? = nil
    
    @Published var selectedImage:UIImage? = nil
    @Published var selectedDocumentUrl:URL? = nil
    
    @Published var subTotal:Double = 0
    @Published var tax:Double = 0
    @Published var total:Double = 0
    @Published var lineItem:LineItem = LineItem(
        id: UUID().uuidString,
        receiptId:"",
        invoiceNum: "",
        storeId:"",
        storeName: "",
        techId: "",
        techName: "",
        itemId: "",
        name: "",
        price: 0.00,
        quantityString:"",
        date: Date(),
        billable: true,
        invoiced: false,
        customerId: "",
        customerName: "",
        sku: "",
        notes:""
    )
    @Published var store:Vender = Vender(
        id: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        )
    )
    
    @Published var companyUser:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor
    )
    
    func onLoad(companyId:String) async throws {
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId,status: "Active")
            //If First
        
        self.stores = try await dataService.getAllStores(companyId: companyId)
            //If First
    }
    func onDisapper() async throws {
        dataService.removeListenerForAllCustomers()
        print("Listener Cancelled")
    }
    func onStoreChange(companyId:String) async throws {
        dataService.removeListenerForAllCustomers()
        print("Listener Cancelled")
        dataService.addListenerForAllCustomers(companyId: companyId,storeId: storeId) { [weak self] items in
            self!.dataServiceDataBaseItems = items
            self!.displayItems = items
            
        }
    }
    func deleteLineItem(at offsets: IndexSet) {
        lineItems.remove(atOffsets: offsets)
    }
    func addNewReceipt(
        companyId:String
    ) async throws{
            //----------------------------------------
        if store.id == "" {
            alertMessage = "Please Select Store"
            print(alertMessage)
            showingAlert = true
            return
            
        }
        if companyUser.id == "" {
            alertMessage = "Please Select Tech"
            print(alertMessage)
            showingAlert = true
            return
            
        }
        if lineItems.count == 0 {
            alertMessage = "Please Add Items to Receive"
            print(alertMessage)
            showingAlert = true
            return
            
        }
            //----------------------------------------
            //Adds all the line items inside of the receipt which are of type purchased item. to their own dayabase
        var totalCost:Double = 0
        var totalCostAfterTax:Double = 0
        var totalNumberOfItems:Int = 0
        var listOfPurchasedItems:[String] = []
        let receiptId = "comp_rece_" + UUID().uuidString
        
        for item in lineItems {
                //get the info from the database about the item ID
            let dbItem = try await DatabaseManager.shared.getDataBaseItem(companyId:companyId,dataBaseItemId: item.itemId)
            let purchaseItemId = UUID().uuidString
            var pushItem = PurchasedItem(id: purchaseItemId,
                                         receiptId: receiptId,
                                         invoiceNum: invoiceNum,
                                         venderId: store.id,
                                         venderName: store.name ?? "",
                                         techId: companyUser.userId,
                                         techName: companyUser.userName,
                                         itemId: item.itemId,
                                         name: dbItem.name,
                                         price: Double(dbItem.rate),
                                         quantityString: item.quantityString,
                                         date: date,
                                         billable: item.billable,
                                         invoiced: item.invoiced,
                                         customerId: "",
                                         customerName: "",
                                         sku: item.sku,
                                         notes: item.notes,
                                         jobId: "",
                                         billingRate: item.sellPrice)
            
            totalCost = totalCost + Double(dbItem.rate)
            listOfPurchasedItems.append(purchaseItemId)
            totalNumberOfItems = totalNumberOfItems + 1
            let timesPurchased:Int = dbItem.timesPurchased ?? 0
            let quantity:Int = Int(item.quantityString) ?? 0
            let newTimesPurcahsed = timesPurchased + quantity
            
            print("New timesPurchased \(newTimesPurcahsed)")
            let newItem:DataBaseItem = DataBaseItem(
                id: dbItem.id,
                name: dbItem.name,
                rate: dbItem.rate,
                storeName: dbItem.storeName,
                venderId: dbItem.venderId,
                category: dbItem.category,
                subCategory: dbItem.subCategory,
                description: dbItem.description,
                dateUpdated: dbItem.dateUpdated,
                sku: dbItem.sku,
                billable: dbItem.billable,
                color: dbItem.color,
                size: dbItem.size,
                UOM: dbItem.UOM,
                tracking: dbItem.tracking,
                sellPrice: dbItem.sellPrice,
                timesPurchased: newTimesPurcahsed
            )
            try await DatabaseManager.shared.updateDataBaseItemtimesPurchased(companyId: companyId, dataBaseItem: newItem)
            try await PurchasedItemsManager.shared.uploadPurchaseItem(companyId: companyId, purchaseItem: pushItem)
        }
        totalCostAfterTax = totalCost * 1.085
        var pdfUrlList:[String] = []
        
        let receipt = Receipt(
            id: receiptId,
            invoiceNum: invoiceNum,
            date: date,
            storeId: store.id,
            storeName: store.name ?? "",
            tech: companyUser.userName,
            techId: companyUser.userId,
            purchasedItemIds: [],
            numberOfItems: 0,
            cost: 0,
            costAfterTax: 0
        )
        
        for documentUrl in pdfUrlStringList {
            if documentUrl.contains(".pdf"){
                    //FOR PDF
                    //FOR ALL OTHER IMAGES
                if let url = URL(string: documentUrl) {
                    guard url.startAccessingSecurityScopedResource() else { // Notice this line right here
                        return
                    }
                    
                    let data  = try Data(contentsOf:url)
                    print("Converted Photo Picker Item to Data")
                    let (path,name) = try await ReceiptFileManager.shared.savePdf(companyId: companyId, receipt: receipt, data: data)
                    print("SUCCESS 2")
                    print("Path \(path)")
                    print("Name \(name)")
                    let url  = try await ReceiptFileManager.shared.getUrlForReceipt(path: path)
                    pdfUrlList.append(url.absoluteString)
                }
            } else if documentUrl.contains(".jpeg"){
                    //FOR JPEG
                    //FOR ALL OTHER IMAGES
                if let url = URL(string: documentUrl) {
                    guard url.startAccessingSecurityScopedResource() else { // Notice this line right here
                        return
                    }
                    
                    let data  = try Data(contentsOf:url)
                    print("Converted Photo Picker Item to Data")
                    let (path,name) = try await ReceiptFileManager.shared.saveImage(companyId: companyId, receipt: receipt, data: data)
                    print("SUCCESS 2")
                    print("Path \(path)")
                    print("Name \(name)")
                    let url  = try await ReceiptFileManager.shared.getUrlForReceipt(path: path)
                    pdfUrlList.append(url.absoluteString)
                }
            } else {
                    //FOR ALL OTHER IMAGES
                if let url = URL(string: documentUrl) {
                    guard url.startAccessingSecurityScopedResource() else { // Notice this line right here
                        return
                    }
                    
                    let data  = try Data(contentsOf:url)
                    print("Converted Photo Picker Item to Data")
                    let (path,name) = try await ReceiptFileManager.shared.saveImage(companyId: companyId, receipt: receipt, data: data)
                    print("SUCCESS 2")
                    print("Path \(path)")
                    print("Name \(name)")
                    let url  = try await ReceiptFileManager.shared.getUrlForReceipt(path: path)
                    pdfUrlList.append(url.absoluteString)
                }
            }
        }
        
        //Reset
        self.lineItems = []
        self.invoiceNum = ""
        self.storeId = ""
        self.companyUserId = ""
        
    }
#if os(iOS)
    func saveReceiptPhoto(companyId:String,receipt:Receipt,receiptPhoto:UIImage) {
        Task{
            guard let data = receiptPhoto.pngData() else {
                print("Error Converting Photo Picker Item to Data")
                return
            }
                //            guard let data = try await receiptPhoto.loadTransferable(type: Data.self) else{
                //                print("Error Converting Photo Picker Item to Data")
                //                return
                //            }
            print("Converted Photo Picker Item to Data")
            let (path,name) = try await ReceiptFileManager.shared.saveImage(companyId: companyId, receipt: receipt, data: data)
            print("SUCCESS 2")
            print("Path \(path)")
            print("Name \(name)")
            let url  = try await ReceiptFileManager.shared.getUrlForReceipt(path: path)
            
            try await dataService.updateReceiptPDFPath(companyId: companyId, receiptItemId: receipt.id, path: url.absoluteString)
            self.iamgeUrl = url
            self.imageUrlString = url.absoluteString
        }
    }
    
#endif
    func getLineItemTotal(_ items:[LineItem]){
        var subTotal:Double = 0
        var tax:Double = 0
        
        for item in items {
            subTotal = item.total + subTotal
        }
        self.subTotal = subTotal
        tax = subTotal * 0.085
        self.tax = tax
        self.total = tax + subTotal
    }
    func filterDataBaseList() {
            //very facncy Search Bar
        if searchTerm != "" {
            var filteredListOfCustomers:[DataBaseItem] = []
            for item in dataServiceDataBaseItems {
                let rateString = String(item.rate)
                
                if item.sku.lowercased().contains(
                    searchTerm.lowercased()
                ) || item.name.lowercased().contains(
                    searchTerm.lowercased()
                ) || rateString.lowercased().contains(
                    searchTerm.lowercased()
                ) || item.description.lowercased().contains(
                    searchTerm.lowercased()
                ) {
                    filteredListOfCustomers.append(item)
                }
            }
            
            self.displayItems = filteredListOfCustomers
        } else {
            self.displayItems = dataServiceDataBaseItems
        }
    }
}
struct AddNewReceipt: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject private var VM :  AddNewReceiptViewModel
    
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AddNewReceiptViewModel(dataService: dataService))
    }
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if UIDevice.isIPhone {
                    HStack{
                        Picker("Type", selection: $VM.receiptScreen) {
                            Text("Receipt").tag("receipt")
                            Text("List Of Items").tag("listOfItems")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.bottom,16)
                    ScrollView{
                        VStack{
                            switch VM.receiptScreen {
                            case "listOfItems":
                                listOfItems
                            case "receipt":
                                receipt
                            default:
                                receipt
                            }
                        }
                    }
                } else {
                    HStack{
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonModifier())
                        })
                        Spacer()
                        button
                    }
                    .padding(8)
                    .sheet(isPresented: $VM.addItemToReceipt,
                           content: {
                        ChooseLineItemView(
                            dataService: dataService,
                            lineItems: $VM.lineItems,
                            addNewItem: $VM.addItemToReceipt,
                            store: VM.store,
                            companyUser: VM.companyUser
                        )
                        .presentationDetents([.medium])
                    })
                    ScrollView{
                        receipt
                            .padding(5)
                        listOfItems
                    }
                    Spacer()
                }
            }
            .padding(5)
        }
        
        .task{
            if let company = masterDataManager.currentCompany{
                do {
                    try await VM.onLoad(companyId: company.id)
                } catch {
                    print("Error Gettings Compay Techs")
                    print(error)
                }
            }
        }
        
        .alert(VM.alertMessage, isPresented: $VM.showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .navigationTitle("New Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
        .toolbar{
            button
        }
        .onChange(of: VM.lineItems, perform: { items in
            VM.getLineItemTotal(items)
        })
        .onChange(of: VM.searchTerm) { search in
            print(search)
            VM.filterDataBaseList()
            
        }
        .onChange(of: VM.selectedImage, perform: { image in
            if let image ,let company = masterDataManager.currentCompany {
                print("add Image to Add New Receipt")
                VM.pdfUrlStringList.append("https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/receipts%2FA586EEF5-E431-408A-833E-A8496FDEF408%2FD74F2F01-F865-47BC-AC2D-2BB4B80C5689.jpeg?alt=media&token=90641801-1e41-45b9-b00d-9bc7658cc1d3")
                    //                    receiptFileVM.saveReceiptPhoto(companyId: company.id, receipt: receipt, receiptPhoto: image)
            }
        })
        .onChange(of: VM.selectedDocumentUrl, perform: { url in
            if let url,let company = masterDataManager.currentCompany {
                    //                pdfUrlStringList.append("https://firebasestorage.googleapis.com/v0/b/the-pool-app-3e652.appspot.com/o/receipts%2FA586EEF5-E431-408A-833E-A8496FDEF408%2FD74F2F01-F865-47BC-AC2D-2BB4B80C5689.jpeg?alt=media&token=90641801-1e41-45b9-b00d-9bc7658cc1d3")
                VM.pdfUrlStringList.append(url.absoluteString)
                print("Add Document to Add New Receipt Logic")
                    //                    receiptFileVM.saveReceiptFile(companyId: company.id, receipt: receipt, documentUrl: url)
            }
        })
        .onChange(of: VM.store) {newValue in
            VM.storeName = VM.store.name ?? "something"
            print("Store Changed")
            Task{
                if let company = masterDataManager.currentCompany {
                    do {
                        try await VM.onStoreChange(companyId: company.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        .onDisappear(perform: {
            Task{
                do {
                    try await VM.onDisapper()
                } catch {
                    print(error)
                }
            }
        })
        
    }
}

extension AddNewReceipt {
    var button: some View{
        Button(action: {
            Task{
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.addNewReceipt(companyId: currentCompany.id)
                    } catch {
                        VM.alertMessage = "Failure to upload Receipt"
                        print(VM.alertMessage)
                        VM.showingAlert = true
                        return
                    }
                }
            }
        },
               label: {
            Text("Save")
                .modifier(SubmitButtonModifier())
            
        })
    }
    var receipt: some View {
        VStack{
            DatePicker("Purchase Date: ", selection: $VM.date, in: ...Date(),displayedComponents: .date)
            
            HStack{
                Text("Refrence: ")
                TextField(
                    "Refrence",
                    text: $VM.invoiceNum
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                
                Spacer()
            }
            HStack{
                Text("Vender: ")
                Spacer()
                Picker("", selection: $VM.store) {
                    Text("Pick store").tag(Vender(id: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0)))
                    ForEach(VM.stores) {
                        Text($0.name ?? "no Name").tag($0)
                    }
                }
                Spacer()
            }
            HStack{
                Text("Tech: ")
                Spacer()
                Picker("", selection: $VM.companyUser) {
                    Text("Pick Tech").tag(CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor))
                    ForEach(VM.companyUsers) {
                        Text(($0.userName)).tag($0)
                    }
                }
                Spacer()
            }
            HStack{
                Button(action: {
                    VM.showAddFileLogic.toggle()
                }, label: {
                    HStack{
                        Text("Add File")
                        Image(systemName: "square.and.arrow.up")
                    }
                    .modifier(UploadButtonModifier())
                })
                .confirmationDialog("Select Type", isPresented: self.$VM.showAddFileLogic, actions: {
                    Button(action: {
                        VM.pickerType = .photo
                        VM.selectedPickerType = .photo
                        
                    }, label: {
                        Text("Photo")
                    })
                    Button(action: {
                        VM.pickerType = .file
                        VM.selectedPickerType = .file
                        
                    }, label: {
                        Text("File")
                    })
                })
                Spacer()
            }
            .sheet(item: self.$VM.pickerType,onDismiss: {print("dismiss")}){ item in
                switch item {
                case .photo:
                    NavigationView{
                        ImagePicker(image: self.$VM.selectedImage)
                    }
                case .file:
                    NavigationView{
                        DocumentPicker(filePath: self.$VM.selectedDocumentUrl)
                    }
                default:
                    ZStack{
                        Text("Document Picker")
                        NavigationView{
                            DocumentPicker(filePath: self.$VM.selectedDocumentUrl)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack{
                    ForEach(VM.pdfUrlStringList,id: \.self){ receiptUrl in
                        VStack{
                            ImageDisplayPopUp(urlString: receiptUrl)
                            HStack{
                                Spacer()
                                Button(action: {
                                    VM.pdfUrlStringList.removeAll(where: {$0 == receiptUrl})
                                }, label: {
                                    Image(systemName: "trash.fill")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                        }
                        .frame(maxWidth: 150)
                        
                    }
                }
            })
            HStack{
                Text("SubTotal: \(VM.subTotal, format: .currency(code: "USD").precision(.fractionLength(2)))")
                Text("Tax: \(VM.tax, format: .currency(code: "USD").precision(.fractionLength(2)))")
                Text("Total: \(VM.total, format: .currency(code: "USD").precision(.fractionLength(2)))")
            }
        }
        .background(Color.listColor)
    }
    
    var listOfItems : some View{
        VStack{
            HStack{
                Text("Items")
                    .font(.headline)
            }
            .padding(5)
            
            if VM.lineItems.count == 0 {
                HStack{
                    
                    Spacer()
                    Button(action: {
                        if VM.store.id == "" {
                            VM.alertMessage = "Please Select Store"
                            print(VM.alertMessage)
                            VM.showingAlert = true
                            return
                        }
                        VM.addItemToReceipt = true
                    }, label: {
                        Text("Add First Item To Receipt")
                            .foregroundColor(Color.basicFontText)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                    Spacer()
                }
                Spacer()
            } else {
                HStack{
                    
                    Spacer()
                    Button(action: {
                        if VM.store.id == "" {
                            VM.alertMessage = "Please Select Store"
                            print(VM.alertMessage)
                            VM.showingAlert = true
                            return
                        }
                        VM.addItemToReceipt = true
                    }, label: {
                        Text("Add Another")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                    })
                    Spacer()
                }
                
                ForEach($VM.lineItems){ line in
                    HStack{
                        ReceiptLineItemView(line: line)
                        Button(action: {
                            VM.lineItems.removeAll(where: {$0.id == line.id})
                        }, label: {
                            ZStack{
                                if UIDevice.isIPhone {
                                    Image(systemName: "circlebadge.fill")
                                        .foregroundColor(Color.white)
                                        .font(.title)
                                        .overlay(
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(Color.red)
                                        )
                                } else {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(Color.red)
                                }
                            }
                        })
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    Divider()
                }
                Spacer()
            }
        }
    }
}
