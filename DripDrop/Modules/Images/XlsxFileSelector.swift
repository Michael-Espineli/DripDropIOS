//
//  XlsxFileSelector.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/9/23.
//

import SwiftUI

struct XlsxFileSelector: View {
    @StateObject private var customerFileVM = CustomerFileManager(dataService: ProductionDataService())
    
    @Binding var workSheetName:String
    @Binding var pathName:String
    @Binding var fileName:String
    @State var showFileChooser = false
    @State var fileExtension = "extension"
    @State var isLoading = false

    var body: some View {
        ZStack {
            VStack{
                HStack(spacing: 0){
                    Text(pathName)
//                    Text(".")
//                    Text(fileExtension)

                }
                #if os(macOS)
            Button("Select XLSX File")
            {
                Task{
                    isLoading = true
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK {
                    if panel.url?.pathExtension ?? "<none>" != "xlsx" {return}
                    self.fileName = panel.url?.lastPathComponent ?? "<none>"
                    self.fileExtension = panel.url?.pathExtension ?? "<none>"
                    let fullPath = panel.url?.relativePath ?? "<none>"
                    print("fullPath > \(fullPath)")
                    self.pathName = fullPath
                    let n = fullPath.replacingOccurrences(of: "." + fileExtension, with: "")

                    print(self.pathName)
                    try? await customerFileVM.getWorkSheetsInXslxFile(pathName: pathName, fileName: fileName, companyId: company.id)
                    }
                    isLoading = false
                }
            }
                HStack{
                    if isLoading {
                        ProgressView()
                    }
                }
                Picker("", selection: $workSheetName) {
                    Text("Pick WorkSheet")
                    ForEach(customerFileVM.listOfWorkSheets,id:\.self) {
                        Text($0).tag($0)
                    }
                }
                .disabled(isLoading)
                .padding()
                #endif
        }
      }
    }
}
