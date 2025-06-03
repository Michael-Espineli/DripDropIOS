//
//  UploadXLSXFileForDataBaseItem.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/1/24.
//

import SwiftUI

struct UploadXLSXFileForDataBaseItem: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    init(dataService: any ProductionDataServiceProtocol,selectedDocumentUrl:URL){
        _dataBaseVM = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
        _selectedDocumentUrl = State(wrappedValue: selectedDocumentUrl)
        _customerFileVM = StateObject(wrappedValue: CustomerFileManager(dataService: dataService))

    }
    @StateObject private var dataBaseVM : ReceiptDatabaseViewModel
    @StateObject private var storeVM = StoreViewModel()
    @StateObject private var customerFileVM : CustomerFileManager
    @State var selectedDocumentUrl:URL
    
    @State var workSheetName:String = ""
    @State var pathName:String = ""
    @State var fileName:String = ""
    @State var fileExtension = "extension"
    @State var isLoading = false
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var vender:Vender = Vender(id: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))

    var body: some View {
        ZStack{
            VStack{
                Text("\(selectedDocumentUrl)")
                Picker("", selection: $workSheetName) {
                    Text("Pick WorkSheet")
                    ForEach(customerFileVM.listOfWorkSheets,id:\.self) {
                        Text($0).tag($0)
                    }
                }
                .disabled(isLoading)
                .padding()
                Picker("", selection: $vender) {
                    Text("Pick a Store")
                    ForEach(storeVM.stores){ store in
                        Text(store.name ?? "").tag(store)
                    }
                }
                Button(action: {
                    Task{
                        if vender.id == "" {
                            print("Vender is False")
                            return
                        }
                        if let company = masterDataManager.currentCompany {
                            isLoading = true
                            do {
                                try await dataBaseVM.uploadXlsxFileTo(pathName: pathName, fileName: fileName, companyId: company.id, workSheetName: workSheetName, vender: vender)
                                alertMessage = "Successfully Uploaded All Items"
                                showAlert = true
                                print(alertMessage)
                            } catch {
                                alertMessage = "Failed to upload items"
                                showAlert = true
                                print(alertMessage)
                            }
                            
                            isLoading = false
                        } else {
                            print("No Company")
                        }
                    }
                }, label: {
                    Text("Upload")
                })
                .disabled(isLoading || vender.id == "")
                .padding()
            }
            if isLoading {
                ProgressView()
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            isLoading = true
            do{
                try? await storeVM.getAllStores(companyId: masterDataManager.currentCompany!.id)
                self.fileName = selectedDocumentUrl.lastPathComponent
                self.fileExtension = selectedDocumentUrl.pathExtension
                let fullPath = selectedDocumentUrl.relativePath
                print("fullPath > \(fullPath)")
                self.pathName = fullPath
                let n = fullPath.replacingOccurrences(of: "." + fileExtension, with: "")

                print(self.pathName)
                try await customerFileVM.getWorkSheetsInXslxFile(pathName: pathName, fileName: fileName, companyId: masterDataManager.currentCompany!.id)
            } catch {
                print("Erroor")
            }
            isLoading = false
        }
    }
}

