//
//  UploadXLSXFileForCustomer.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/31/23.
//

import SwiftUI

struct UploadXLSXFileForCustomer: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var customerFileVM = CustomerFileManager(dataService: ProductionDataService())
    @State var selectedDocumentUrl:URL
    
    @State var workSheetName:String = ""
    @State var pathName:String = ""
    @State var fileName:String = ""
    @State var fileExtension = "extension"
    @State var isLoading = false
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    var body: some View {
        ZStack{
            VStack{
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Go Back")
                        .modifier(DismissButtonModifier())
                })
                Text("\(selectedDocumentUrl)")
                Picker("", selection: $workSheetName) {
                    Text("Pick WorkSheet")
                    ForEach(customerFileVM.listOfWorkSheets,id:\.self) {
                        Text($0).tag($0)
                    }
                }
                .disabled(isLoading)
                .padding()
                if customerFileVM.isLoading ?? false {
                    Text("\(customerFileVM.loadingText ?? "Loading...") \(String(customerFileVM.currentCustomer ?? 0)) / \(String(customerFileVM.totalCustomer ?? 0))")
                }
                Button(action: {
                    Task{
                        
                        if let company = masterDataManager.currentCompany {
                            isLoading = true
                            do {
                                try await customerFileVM.uploadXlsxFileTo(pathName: pathName, fileName: fileName, companyId: company.id, workSheetName: workSheetName)
                                alertMessage = "Successfully Uploaded All Customers"
                                showAlert = true
                                print(alertMessage)
                            } catch {
                                alertMessage = "Failed to upload"
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
                .disabled(isLoading)
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

