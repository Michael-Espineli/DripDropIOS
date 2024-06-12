//
//  ReceiptFileSelector.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/23/23.
//



import SwiftUI

struct ReceiptCSVFileSelector: View {
    @Binding var pathName:String
    @Binding var fileName:String

    @State var showFileChooser = false
    @State var fileExtension = "extension"

    var body: some View {
        ZStack {
            VStack{
                HStack{
                    Text(pathName)
                    Text(".")
                    Text(fileExtension)

                }
                #if os(macOS)
            Button("Select CSV File")
            {
                
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK {
                    if panel.url?.pathExtension ?? "<none>" != "csv" {return}
                    self.fileName = panel.url?.lastPathComponent ?? "<none>"
                    self.fileExtension = panel.url?.pathExtension ?? "<none>"
                    let fullPath = panel.url?.relativePath ?? "<none>"
                    self.pathName = fullPath.replacingOccurrences(of: "." + fileExtension, with: "")
//                    self.pathName.remove(at: pathName.startIndex)

                }
            }
                #endif
        }
      }
    }
}
