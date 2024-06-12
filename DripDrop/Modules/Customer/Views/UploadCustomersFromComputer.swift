//
//  UploadCustomersFromComputer.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//


import SwiftUI

struct UploadCustomersFromComputer: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject private var customerVM : CustomerViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        
    }
    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var customerFileVM = CustomerFileManager()


    @State var pathName = ""
    @State var fileName = ""
    @State var isLoading: Bool = false
    @State var fileType = "XLSX"
    @State var workSheetName = ""

  var body: some View {
      ZStack {

          VStack{
              VStack{
                  
                  Picker("What is your favorite color?", selection: $fileType) {
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
              Button(action: {
                  Task{
                      if let company = masterDataManager.selectedCompany {
                          isLoading = true
                          switch fileType{
                          case "CSV":
                              try? await customerVM.uploadCsvFileTo(pathName: pathName, fileName: fileName, companyId: company.id)
                          case "XLSX":
                              try? await customerFileVM.uploadXlsxFileTo(pathName: pathName, fileName: fileName, companyId: company.id, workSheetName: workSheetName)
                          default:
                              isLoading = false
                              return
                              
                          }
                          
                          isLoading = false
                      }
                  }

              }, label: {
                  Text("Upload Data Base Items")
              })
              if isLoading{
                  ProgressView()
                  Text("\(customerVM.loadingText ?? "")")
                  Text(String(customerVM.currentCustomer ?? 0))

              }
              Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

