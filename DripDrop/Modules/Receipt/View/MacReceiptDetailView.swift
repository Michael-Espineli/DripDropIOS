//
//  MacReceiptDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
import SwiftUI
import ContactsUI

struct MacReceiptDetailView: View {
    @State var receipt: Receipt
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var showDocumentpicker:Bool = false
//    @State private var pickerType:FilePickerType? = nil
//    @State private var selectedPickerType:FilePickerType? = nil
    
    @State var selectedDocumentUrl:URL? = nil
    
    var body: some View {
        
        ZStack{
            VStack{
                Text(receipt.storeName ?? "")
                Text(receipt.tech ?? "")
                Text(fullDate(date:receipt.date))
                images
//                VStack{
//                    Button(action: {
//                        showDocumentpicker.toggle()
//                    }, label: {
//                        Text("Select File")
//                            .padding(5)
//                            .background(Color.gray)
//                            .cornerRadius(10)
//                    })
//                    .confirmationDialog("Select Type", isPresented: self.$showDocumentpicker, actions: {
//                        Button(action: {
//                            self.pickerType = .photo
//                            self.selectedPickerType = .photo
//
//                        }, label: {
//                            Text("Photo")
//                        })
//                        Button(action: {
//                            self.pickerType = .file
//                            self.selectedPickerType = .file
//
//                        }, label: {
//                            Text("File")
//                        })
//                        DO NOT DELETE IT IS EXAMPLE FOR CONTACT SELECTOR, I WILL PUT THIS IN THE CUSTOMER PAGE SOON
//
//                                            Button(action: {
//                                                self.pickerType = .contact
//                                                self.selectedPickerType = .contact
//
//                                            }, label: {
//                                                Text("Contact")
//                                            })
//                    })
//                }
                Spacer()
            }
        }
    }
}


extension MacReceiptDetailView {
    var images: some View {
        ScrollView(.horizontal){
            HStack{
                ForEach(receipt.pdfUrlList ?? [],id: \.self){ receiptUrl in
                    let last4 = receiptUrl.suffix(4)
                    if receiptUrl.contains(".pdf"){
                        NavigationLink(destination: {
                            if let url = URL(string: receiptUrl){
#if os(iOS)
                                
                                PdfDetailView(pdfUrl: url)
#endif
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
