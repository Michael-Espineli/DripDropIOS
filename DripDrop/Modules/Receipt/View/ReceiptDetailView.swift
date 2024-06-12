//
//  ReceiptDetailView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/16/23.
//

import SwiftUI
import ContactsUI
#if os(iOS)

import UIKit
enum FilePickerType:Identifiable{
    case photo, file, contact
    var id:Int {
        hashValue
    }
}
struct ReceiptDetailView: View {
    @StateObject var receiptFileVM =  ReceiptFileViewModel()
    @State var receipt: Receipt
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company

    @State var showDocumentpicker:Bool = false
    @State private var pickerType:FilePickerType? = nil
    @State private var selectedPickerType:FilePickerType? = nil

    @State var selectedImage:UIImage? = nil
    @State var selectedDocumentUrl:URL? = nil
    @State var selectedContact:CNContact? = nil

    var body: some View {
        
        ZStack{
            VStack{
                Text(receipt.storeName ?? "")
                Text(receipt.tech ?? "")
                Text(fullDate(date:receipt.date))
                images
                VStack{
                    VStack{
                        if (self.selectedPickerType == .photo && self.selectedImage != nil) {
                            Image(uiImage: self.selectedImage!)
                                .resizable()
                                .frame(width: 200, height: 200)
                        } else  if (self.selectedPickerType == .file && self.selectedDocumentUrl != nil) {
                            Text("Document Selected \(String(describing: self.selectedDocumentUrl))")
                        } else  if (self.selectedPickerType == .contact && self.selectedContact != nil) {
                            Text("Contact Card Selected >> \(self.selectedContact!.givenName) \(self.selectedContact!.familyName)")
                        }
                        
                    }
                    //DEVELOPER EXAMPLE OF A PICKER CONTACT FILE AND PHOTO
                    Button(action: {
                        showDocumentpicker.toggle()
                    }, label: {
                        Text("Select File")
                            .padding(5)
                            .background(Color.gray)
                            .cornerRadius(10)
                    })
                    .confirmationDialog("Select Type", isPresented: self.$showDocumentpicker, actions: {
                        Button(action: {
                            self.pickerType = .photo
                            self.selectedPickerType = .photo
                            
                        }, label: {
                            Text("Photo")
                        })
                        Button(action: {
                            self.pickerType = .file
                            self.selectedPickerType = .file
                            
                        }, label: {
                            Text("File")
                        })
                        //DO NOT DELETE IT IS EXAMPLE FOR CONTACT SELECTOR, I WILL PUT THIS IN THE CUSTOMER PAGE SOON
                        
                        //                    Button(action: {
                        //                        self.pickerType = .contact
                        //                        self.selectedPickerType = .contact
                        //
                        //                    }, label: {
                        //                        Text("Contact")
                        //                    })
                    })
                }
                Spacer()
            }
        }
        .onChange(of: selectedImage, perform: { image in
            if image != nil {
                receiptFileVM.saveReceiptPhoto(companyId: company.id, receipt: receipt, receiptPhoto: image!)
            }
        })
        .onChange(of: selectedDocumentUrl, perform: { url in
            if url != nil {
                receiptFileVM.saveReceiptFile(companyId: company.id, receipt: receipt, documentUrl: url!)
            }
        })
        .sheet(item: self.$pickerType,onDismiss: {print("dismiss")}){ item in
            switch item {
            case .photo:
                NavigationView{
                    ImagePicker(image: self.$selectedImage)
                }
            case .file:
                NavigationView{
                    DocumentPicker(filePath: self.$selectedDocumentUrl)
                }
            case .contact:
                NavigationView{
                    ContactPicker(selectedContact: self.$selectedContact)
                }
            }
        }
    }
}


extension ReceiptDetailView {
    var images: some View {
        ScrollView(.horizontal){
            HStack{
                ForEach(receipt.pdfUrlList ?? [],id: \.self){ receiptUrl in
                    let last4 = receiptUrl.suffix(4)
                    if receiptUrl.contains(".pdf"){
                        NavigationLink(destination: {
                            if let url = URL(string: receiptUrl){
                                
                                PdfDetailView(pdfUrl: url)
                            }
                        }, label: {
                            ZStack{
                                Image(systemName: "doc")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .frame(maxWidth: 150,maxHeight:150)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                        })
                        .padding()
                    } else if receiptUrl.contains(".jpeg"){
                        NavigationLink(destination: {
                            if let url = URL(string: receiptUrl){
                                
                                ImageDisplay(url: url)
                            }
                        }, label: {
                            ZStack{
                                if let url = URL(string: receiptUrl){
                                    
                                    ImageDisplay(url: url)
                                }
                            }
                            .frame(maxWidth: 150,maxHeight:150)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                        })
                        .padding()

                    } else {
                        NavigationLink(destination: {
                            if let url = URL(string: receiptUrl){
                                
                                ImageDisplay(url: url)
                            }
                        }, label: {
                            ZStack{
                                if let url = URL(string: receiptUrl){
                                    
                                    ImageDisplay(url: url)
                                }
                            }
                            .frame(maxWidth: 150,maxHeight:150)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                        })
                        .padding()

                    }
                }
            }
        }

    }

}
#endif
