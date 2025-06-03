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
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var receiptFileVM =  ReceiptFileViewModel()
    @State var receipt: Receipt
    @State var activeReceipt: Receipt? = nil

    @State var showDocumentpicker:Bool = false
    @State private var pickerType:FilePickerType? = nil
    @State private var selectedPickerType:FilePickerType? = nil

    @State var selectedImage:UIImage? = nil
    @State var selectedDocumentUrl:URL? = nil
    @State var selectedContact:CNContact? = nil

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if UIDevice.isIPhone {
                    ScrollView{
                        LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                            Section(content: {
                                
                                listOfItems
                                    .padding(.leading,20)
                                
                            }, header: {
                                receiptInfo
                            })
                        })
                        .padding(.top,20)
                        .clipped()
                    }
                } else {
                    HStack{
                        receiptInfo
                            .padding(5)
                        Divider()
                        //                search
                        listOfItems
                            .border(.gray, width: 2)
                            .padding(5)
                    }
                    Spacer()
                }
            }
            .padding(5)
        }
        ZStack{
            VStack{

                
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

                }
                Spacer()
            }
        }
        .task{
            activeReceipt = receipt
        }
        .onChange(of: masterDataManager.selectedReceipt, perform: { receipt in
            if let receipt {
                activeReceipt = receipt
            }
        })
        .onChange(of: selectedImage, perform: { image in
            if let company = masterDataManager.currentCompany {
                
                if image != nil {
                    receiptFileVM.saveReceiptPhoto(companyId: company.id, receipt: receipt, receiptPhoto: image!)
                }
            }
        })
        .onChange(of: selectedDocumentUrl, perform: { url in
            if let company = masterDataManager.currentCompany {
                if url != nil {
                    receiptFileVM.saveReceiptFile(companyId: company.id, receipt: receipt, documentUrl: url!)
                }
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
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    
                }, label: {
                    Text("Edit")
                    .modifier(EditButtonModifier())
                })
            })
        }
    }
}


extension ReceiptDetailView {
    var receiptInfo: some View {
        VStack(alignment: .leading){
            if let activeReceipt {
                Text("Purchase Date: \(fullDate(date:activeReceipt.date))")

                Text("Refrence: \(activeReceipt.invoiceNum)")
                Text("Vender: \(activeReceipt.storeName ?? "")")
                Text("Tech: \(activeReceipt.tech ?? "")")

                Text("\(activeReceipt.id)")
                Text("Number Of Items: \(String(activeReceipt.numberOfItems))")
                Text("Cost $\(String(format:"%2.f",activeReceipt.cost))")
                Text("Cost After Tax $\(String(format:"%2.f",activeReceipt.costAfterTax))")
            }
            images
        }
    }
    var listOfItems : some View{
        VStack{
            if let activeReceipt {
                Text("List Of Items")
                    ScrollView(.horizontal, content: {
                        ForEach(activeReceipt.purchasedItemIds ?? [],id:\.self){ id in
                            Text("\(id)")
                        }
                    })
                
            }
        }
    }
    var images: some View {
        ScrollView(.horizontal){
            HStack{
                //DEVELOPER EXAMPLE OF A PICKER CONTACT FILE AND PHOTO
                Button(action: {
                    showDocumentpicker.toggle()
                }, label: {
                    Image(systemName: "plus.app")
                        .font(.title)
                        .modifier(AddButtonModifier())
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
                HStack{
                    ForEach(receipt.pdfUrlList ?? [],id: \.self){ receiptUrl in
                        VStack{
                            ImageDisplayPopUp(urlString: receiptUrl)
                            HStack{
                                Spacer()
                                Button(action: {
                                    print("Add Remove PDF URL Logic")
                                }, label: {
                                    Image(systemName: "trash.fill")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                        }
                        .frame(maxWidth: 150)
                    }
                }
            }
        }
    }
}
#endif
