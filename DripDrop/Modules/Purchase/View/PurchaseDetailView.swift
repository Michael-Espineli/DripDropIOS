//
//  PurchaseDetailView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/16/23.
//

import SwiftUI

struct PurchaseDetailView: View {
    @EnvironmentObject var customerEnviromentalObject: CustomerViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var customerVM : CustomerViewModel
    @StateObject private var jobVM : JobViewModel
    @State private var purchase : PurchasedItem

    
    init(purchase:PurchasedItem,dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _purchase = State(wrappedValue: purchase)
        
    }
    @StateObject private var storeVM = StoreViewModel()
    @StateObject private var vm = PurchasesViewModel()
    
    
    
    @State var showEditNotesView:Bool = false
    @State var customerList:[Customer] = []
    @State var workOrderList:[Job] = []
    
    @State var loading = false
    @State var showStoreInfo = false
    
    @State var customerSearchTerm = ""
    @State var WOSearchTerm = ""
    
    @State var notes = ""
    @State var invoiced:Bool = false
    @State var displayCustomerName = ""
    @State var displayJobName = ""

    @State var selectedCustomerPicker:Bool = false
    @State var selectedJobPicker:Bool = false

    @State var customerEntity:Customer = Customer(id: "", firstName: "", lastName: "", email: "", billingAddress: Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0), active: true, displayAsCompany: false, hireDate: Date(), billingNotes: "")
    @State var jobEntity:Job = Job(id: "",
                                         type: "",
                                         dateCreated: Date(),
                                         description: "",
                                   operationStatus: .estimatePending,
                                   billingStatus: .draft,
                                         customerId: "",
                                         customerName: "",
                                         serviceLocationId: "",
                                         serviceStopIds: [],
                                         adminId: "",
                                         adminName: "",
                                         jobTemplateId: "",
                                         installationParts: [],
                                         pvcParts: [],
                                         electricalParts: [],
                                         chemicals: [],
                                         miscParts: [],
                                         rate: 0,
                                         laborCost: 0)
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack{
            ScrollView{
                if !UIDevice.isIPhone {
                    HStack{
                        Spacer()
                        Button(action: {
                            masterDataManager.selectedPurchases = nil
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonTextModifier())
                        })
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(5)
                    }
                }
                purchaseView
                search
            }
        }
        .task{
            notes = purchase.notes
            displayCustomerName = purchase.customerName
            displayJobName = purchase.jobId
            invoiced = purchase.invoiced
            do {
                if let company = masterDataManager.selectedCompany {
          
                    try await storeVM.getSingleStore(companyId: company.id, storeId: purchase.venderId)
                } else {
                    print("No Customer")
                }
            } catch {
                print("Error")
            }
        }
        
        
        .onChange(of: notes){ note in
            Task{
                if let company = masterDataManager.selectedCompany{
                    do {
                        try await vm.updateNotes(currentItem: purchase, notes: note, companyId: company.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        .onChange(of: masterDataManager.selectedPurchases){ item in
            if let item = item {
                notes = item.notes
                displayCustomerName = item.customerName
                invoiced = item.invoiced
                customerSearchTerm = ""
            }
        }
        .onChange(of: jobEntity, perform: { job in
            Task{
                if let company = masterDataManager.selectedCompany{
                    do {
                        if job.id == "" {return}
                        try await vm.updateReceiptWorkOrder(currentItem: purchase, workOrderID:job.id , companyId: company.id)
                        try await jobVM.addPurchaseItemsToWorkOrder(workOrder: job, companyId: company.id, ids: [purchase.id])
                    } catch {
                        print("")
                        print("Error Purchase Detail View")
                        print(error)
                        print("")
                    }
                }
            }
        })
        .onChange(of: customerEntity){ customer in
            Task{
                do {
                    if let company = masterDataManager.selectedCompany {
                        try await vm.updateReceiptCustomer(currentItem: purchase, newCustomer: customer, companyId: company.id)
                        displayCustomerName = customer.firstName  + " " + customer.lastName

                    } else {
                        print("No Customer")
                    }
                } catch {
                    print("Error")
                }
            }
        }
    }
}

extension PurchaseDetailView{
    
    var purchaseView: some View {
        ZStack{
            if UIDevice.isIPhone {
                VStack{
                    info
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                    money
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                }
            } else {
                HStack{
                    info
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                    money
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                }
            }
            if loading {
                ProgressView()
            }
        }
    }
    var info: some View {
        ZStack{
                VStack(alignment: .leading){
                    
                    VStack(alignment: .leading){
                        Divider()
                        HStack{
                            Text("Store : ")
                            Text(purchase.venderName)
                                .textSelection(.enabled)
                            Button(action: {
                                showStoreInfo = true
                            }, label: {
                                Image(systemName: "info.circle")
                            })
                            .sheet(isPresented: $showStoreInfo, content: {
                                VStack{
                                    HStack{
                                        Spacer()
                                        Button(action: {
                                            showStoreInfo = false
                                        }, label: {
                                            Image(systemName: "xmark")
                                                .modifier(DismissButtonTextModifier())
                                        })
                                        .modifier(DismissButtonModifier())
                                    }
                                    Text("Store Info")
                                    HStack{
                                        Text("Store Name : ")
                                        Text(storeVM.store?.name ?? "...Loading")
                                    }
                                    Text(storeVM.store?.address.streetAddress ?? "")
                                    HStack{
                                        Text(storeVM.store?.address.city ?? "")
                                        Text(" ")
                                        Text(storeVM.store?.address.state ?? "")
                                        Text(" ")
                                        Text(storeVM.store?.address.zip ?? "")
                                    }
                                }
                                .background(Color.green)
                                .cornerRadius(10)
                                
                            })
                        }
                        HStack{
                            Text("Name :")
                            Text(purchase.name)
                                .textSelection(.enabled)
                        }
                        
                        HStack{
                            Text("Sku :")
                            Text(purchase.sku)
                                .textSelection(.enabled)
                        }
                        HStack{
                            Text("Invoice Num : ")
                            Text(purchase.invoiceNum)
                                .textSelection(.enabled)
                        }
                        
                        HStack{
                            Text("Tech Name :")
                            Text(purchase.techName)
                                .textSelection(.enabled)
                        }
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Text("Notes: ")
                            TextEditor(text: $notes)
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .frame(height: 100)
                            
                        }
                    }
                    Spacer()
                }
            
        }
    }
    var money: some View {
        ZStack{
                VStack{
                    HStack{
                        VStack(alignment: .leading){
                            Text("Price : \(purchase.price, format: .currency(code: "USD"))")
                            
                            Text("Quantity : \(purchase.quantityString)")
                            Text("Price After Tax : \(purchase.totalAfterTax, format: .currency(code: "USD"))")
                            
                            Text(fullDate(date:purchase.date))
                            Text("Billable : \(purchase.billable ? "Yes" : "No")")
                            
                        }
                        Spacer()
                    }
                    HStack{
                        Text("Invoiced : ")
                        Button(action: {
                            if invoiced {
                                Task{
                                    try? await vm.updateReciptBillingStatus(currentItem: purchase, newBillingStatus: false, companyId: masterDataManager.selectedCompany!.id)
                                    try? await vm.getSinglePurchasedItem(itemId: purchase.id, companyId: masterDataManager.selectedCompany!.id)
                                    //                                    self.purchasedItem  = vm.purchasedItem!
                                    invoiced = false
                                }
                            } else {
                                Task{
                                    try? await vm.updateReciptBillingStatus(currentItem: purchase, newBillingStatus: true, companyId: masterDataManager.selectedCompany!.id)
                                    try? await vm.getSinglePurchasedItem(itemId: purchase.id, companyId: masterDataManager.selectedCompany!.id)
                                    //                                    self.purchasedItem  = vm.purchasedItem!
                                    invoiced = true
                                }
                            }
                        }, label: {
                            if invoiced {
                                Image(systemName: "checkmark.square")
                            }else {
                                Image(systemName: "square")
                            }
                        })
                    }
                    Spacer()
                }
            
        }
    }
    var search: some View {
        ZStack{
            if UIDevice.isIPhone {
                VStack{
                    searchForJob
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                    searchForCustomer
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                }
            } else {
                HStack{
                    searchForJob
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                    searchForCustomer
                        .padding(5)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(5)
                        .padding(5)
                }
            }
        }
    }
    var searchForJob: some View {
        VStack{
            HStack{
                Text("Job Name : ")
                if displayJobName == "" {
                    
                    Button(action: {
                        selectedJobPicker.toggle()
                    }, label: {
                        Text("Selected Job")
                            .foregroundColor(Color.white)
                            .padding(5)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                    })
                    Spacer()

                } else {
                    Text(displayJobName)
                    Spacer()
                    Button(action: {
                        selectedJobPicker.toggle()
                    }, label: {
                        Image(systemName: "gobackward")
                            .foregroundColor(Color.black)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                        })
                }
            }
            .sheet(isPresented: $selectedJobPicker,onDismiss: {
                
            }, content: {
                JobPickerScreen(dataService: dataService, job: $jobEntity)
            })
        }
    }
    var searchForCustomer: some View {
            VStack{
                HStack{
                    Text("Customer Name : ")
                    if displayCustomerName == "" {
                        
                        Button(action: {
                            selectedCustomerPicker.toggle()
                        }, label: {
                            Text("Selected Customer")
                                .foregroundColor(Color.white)
                                .padding(5)
                                .background(Color.poolBlue)
                                .cornerRadius(5)
                        })
                        Spacer()
                    } else {
                        Text(displayCustomerName)
                        Spacer()
                        Button(action: {
                            selectedCustomerPicker.toggle()
                        }, label: {
                            Image(systemName: "gobackward")
                                .foregroundColor(Color.black)
                                .padding(5)
                                .background(Color.accentColor)
                                .cornerRadius(5)
                            })
                    }
                }
                .sheet(isPresented: $selectedCustomerPicker, content: {
                    CustomerPickerScreen(dataService: dataService, customer: $customerEntity)
                })
            }
        
    }
    
}
