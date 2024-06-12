//
//  AddDataBaseFromComputer.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/23/23.
//


import SwiftUI

struct AddDataBaseFromComputer: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject private var viewModel = ReceiptViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    @State var store:Vender = Vender(id: "", address:Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))
    
    @State var pathName = ""
    @State var fileName = ""
    @State var isLoading: Bool = false

  var body: some View {
      ZStack {
          if isLoading{
              ProgressView()
          }
          VStack{
              ReceiptCSVFileSelector(pathName: $pathName,fileName:$fileName)
              HStack{
                  Text("Store")
                  Picker("", selection: $store) {
                      Text("Pick store")
                      ForEach(storeViewModel.stores) {
                          Text($0.name ?? "no Name").tag($0)
                      }
                  }
              }
              Button(action: {
                  Task{
                      if let company = masterDataManager.selectedCompany {
                          do {
                              isLoading = true
                              try await viewModel.uploadFileTo(companyId: company.id, pathName: pathName,fileName: fileName,storeName: store.name ?? "Store",storeId: store.id)
                              isLoading = false
                          } catch {
                              print(error)
                          }
                      }
                  }

              }, label: {
                  Text("Upload DataBse Items")
              })
              Spacer()
      }
    }
      .task{
          if let company = masterDataManager.selectedCompany {
              do {
                  try await storeViewModel.getAllStores(companyId: company.id)
              } catch {
                  print(error)
              }
          }
      }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

