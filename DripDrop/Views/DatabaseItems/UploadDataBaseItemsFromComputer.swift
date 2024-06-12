//
//  UploadDataBaseItemsFromComputer.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/9/23.
//

import SwiftUI

struct UploadDataBaseItemsFromComputer: View {
    @StateObject private var dataBaseVM = ReceiptDatabaseViewModel()
    @StateObject private var storeVM = StoreViewModel()
    @StateObject private var customerFileVM = CustomerFileManager()

    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company

    
    @State var pathName = ""
    @State var fileName = ""
    @State var isLoading: Bool = false
    @State var fileType = "XLSX"
    @State var workSheetName = ""
    @State var vender:Vender = Vender(id: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))
  var body: some View {
      ZStack {
          VStack{
              VStack{
                  Picker("Pick a File", selection: $fileType) {
                      Text("CSV").tag("CSV")
                      Text("XLSX").tag("XLSX")
                  }
                  .pickerStyle(.segmented)
                  switch fileType{
                  case "CSV":
                      ReceiptCSVFileSelector(pathName: $pathName,fileName:$fileName)
                  case "XLSX":
                      XlsxFileSelector(workSheetName: $workSheetName, pathName: $pathName, fileName: $fileName)
                  default:
                      ReceiptCSVFileSelector(pathName: $pathName,fileName:$fileName)
                  }
              }
              Picker("", selection: $vender) {
                  Text("Pick a Store")
                  ForEach(storeVM.stores){ store in
                      Text(store.name ?? "").tag(store)
                  }
              }
              Button(action: {
                  Task{
                      isLoading = true
                      switch fileType{
                      case "CSV":
                          try? await dataBaseVM.uploadCsvFileTo(pathName: pathName, fileName: fileName, companyId: company.id)
                      case "XLSX":
                          try? await dataBaseVM.uploadXlsxFileTo(pathName: pathName, fileName: fileName, companyId: company.id, workSheetName: workSheetName, vender: vender)
                      default:
                          isLoading = false
                          return
                          
                      }
                      
                      isLoading = false
                  }

              }, label: {
                  Text("Upload DataBaseItems")
              })
              .disabled(vender.id == "")
              if isLoading{
                  ProgressView()
                  Text("\(dataBaseVM.loadingText ?? "")")
                  Text("\(String(dataBaseVM.loadingCount ?? 0)) / \(String(dataBaseVM.totalCount ?? 0))")

              }
              Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .task{
        try? await storeVM.getAllStores(companyId: company.id)
    }
  }
}

