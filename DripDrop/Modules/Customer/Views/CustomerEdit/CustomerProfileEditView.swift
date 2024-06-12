//
//  CustomerProfileEditView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/18/23.
//
import SwiftUI
import MapKit

struct CustomerProfileEditView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var customerVM : CustomerViewModel
    @State var customer:Customer

    init(dataService:any ProductionDataServiceProtocol,customer:Customer){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
    }
    
    
    @State var showDeleteAlert:Bool = false
    @State var showAlert:Bool = false
    @State var active:Bool = false

    @State var alertMessage:String = ""
    //Customer info
    @State var firstName:String = ""
    @State var lastName:String = ""
    @State var companyName:String = ""
    @State var rate:Double = 0
    @State var email:String = ""

    @State var notes:String = ""
    @State var contactNotes:String = ""
    @State var phoneNumber:String = ""
    
    @State var fireCategory:String = ""
    @State var fireReason:String = ""

    //Billing Address

    @State var billingAddressStreetAddress:String = ""
    @State var billingAddressCity:String = ""
    @State var billingAddressState:String = ""
    @State var billingAddressZip:String = ""
    /*
    //Service Location

    @State var serviceLocationAddressStreetAddress:String = ""
    @State var serviceLocationAddressCity:String = ""
    @State var serviceLocationAddressState:String = ""
    @State var serviceLocationAddressZip:String = ""
    
    @State var serviceLocationMainContactName:String = ""
    @State var serviceLocationMainContactPhoneNumber:String = ""
    @State var serviceLocationMainContactEmail:String = ""
    @State var serviceLocationMainContactNotes:String = ""
    
    @State var serviceLocationMainContactGateCode:String = ""
    @State var serviceLocationMainContactNickName:String = ""
*/
    @State var estimatedTime:String = ""
    @State var dogName:String = ""
    
    //bool
    @State var displayAsCompany:Bool = false
    
    var body: some View {
        ZStack{
            ScrollView(showsIndicators: false){
                HStack{
                    Button(action: {
                        showDeleteAlert.toggle()
                    }, label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                            .font(.title)
                    })
                    Spacer()
                    saveButton
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 5, trailing: 10))
                info
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert(isPresented:$showDeleteAlert) {
            Alert(
                title: Text("Alert"),
                message: Text("Confirm you want to delete Customer"),
                primaryButton: .destructive(Text("Delete")) {
                        print("Deleteing \(customer.firstName) \(customer.lastName)")
                    
                    Task{
                        do {
                                try await customerVM.deleteCustomer(companyId:masterDataManager.selectedCompany!.id,customer:customer)
                                alertMessage = "Successfully Deleted"
                            print(alertMessage)
                                showAlert = true
                            masterDataManager.selectedID = ""
                            masterDataManager.selectedCustomer = nil
                            masterDataManager.selectedCategory = nil
                        } catch {
                            alertMessage = "Failed To Delete Deleted"
                            print(alertMessage)
                            showAlert = true
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .toolbar{
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showDeleteAlert.toggle()
                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color.red)
                        .font(.title)
                })
            }
            ToolbarItem() {
                saveButton
            }
        }
        .onAppear(perform: {
                firstName = customer.firstName
                lastName = customer.lastName
                companyName = customer.company ?? ""
                displayAsCompany = customer.displayAsCompany
                phoneNumber = customer.phoneNumber ?? ""
                email = customer.email
                active = customer.active
            
            billingAddressStreetAddress = customer.billingAddress.streetAddress
            billingAddressCity = customer.billingAddress.city
            billingAddressState = customer.billingAddress.state
            billingAddressZip = customer.billingAddress.zip
            
        })
    }
}
extension CustomerProfileEditView {
    var saveButton: some View {
        Button(action: {
            Task{
                do {
                    if let company = masterDataManager.selectedCompany { 
                        //DEVELPER ADD THE REST OF THE UPDATABLE FIELDS FOR CUSTOMERS
                        //DEVLOPER FIX LATITUDE AND LONGITUDE CALCULATIONS ON ADDRESS UPDATES.
                        try await customerVM.updateCustomerInfoWithValidation(currentCustomer: customer, companyId: company.id, firstName: firstName, lastName: lastName, email: email, phoneNumber: phoneNumber, company: companyName, displayAsCompany: displayAsCompany,billingAddress: Address(streetAddress: billingAddressStreetAddress, city: billingAddressCity, state: billingAddressState, zip: billingAddressZip, latitude: customer.billingAddress.latitude, longitude: customer.billingAddress.longitude))
                        
                    }
                    masterDataManager.selectedID = ""
                    masterDataManager.selectedCustomer = nil
                    dismiss()

                } catch {
                    print("Error")
                }
            }
        }, label: {
          Text("Save")
                .padding(10)
                .background(Color.primary)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(10)
        })
    }
    var info: some View {
        VStack{
                
                VStack{
                    Toggle("Display As Company", isOn: $displayAsCompany)
                    
                    if displayAsCompany {
                        HStack{
                            Text("Company Name")
                                .bold(true)
                            TextField(
                                "Company Name",
                                text: $companyName
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            
                        }
                    } else {
                        HStack{
                            Text("First Name")
                                .bold(true)
                            TextField(
                                "First Name",
                                text: $firstName
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            
                        }
                        HStack{
                            Text("Last Name")
                                .bold(true)
                            TextField(
                                "Last Name",
                                text: $lastName
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            
                        }
                    }
                    HStack{
                        Text("Email")
                            .bold(true)
                        TextField(
                            "Email",
                            text: $email
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        
                    }
                    HStack{
                        Text("Phone Number")
                            .bold(true)
                        TextField(
                            "Phone Number",
                            text: $phoneNumber
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        
                    }
                    HStack{
                        Text("Phone Label: ")
                            .bold(true)
                        Spacer()
                        Text("\(customer.phoneLabel ?? "")")
                        
                    }
                    HStack{
                        Text("Billing Address: ")
                            .bold(true)
                        VStack{
                            HStack{
                                TextField(
                                    "Street Address",
                                    text: $billingAddressStreetAddress
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                TextField(
                                    "City",
                                    text: $billingAddressCity
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                TextField(
                                    "State",
                                    text: $billingAddressState
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                TextField(
                                    "Zip",
                                    text: $billingAddressZip
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                        }
                    }
                    HStack{
                        Text("Active: ")
                            .bold(true)
                        Spacer()
                        Toggle("", isOn: $active)
                    }
                    if active {
                        HStack{
                            Text("Customer Since: ")
                                .bold(true)
                            Spacer()
                            Text("\(fullDate(date:customer.hireDate))")
                            
                        }
                    } else {
                        HStack{
                            Text("Fire Category: ")
                                .bold(true)
                            Spacer()
                            TextField(
                                "Fire Category",
                                text: $fireCategory
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("Fire Reason: ")
                                .bold(true)
                            Spacer()
                            TextField(
                                "Fire Reason",
                                text: $fireReason
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                    }
                }
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 0))
    }
    var image: some View {
        ZStack{
            VStack{
                    BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: customer.billingAddress.latitude, longitude: customer.billingAddress.longitude))
                        .frame(height: 150)
                
            }
            .padding(0)
            VStack{
                ZStack{
                    Circle()
                        .fill(Color.realYellow)
                        .frame(maxWidth:100 ,maxHeight:100)
                    
                    Image(systemName:"person.circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:90 ,maxHeight:90)
                        .cornerRadius(75)
                }
//                .frame(maxWidth: 150,maxHeight:150)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
        }
    }
}
//struct CustomerProfileEditView_Previews: PreviewProvider {
//    static var previews: some View {
//        @State var showSignInView: Bool = false
//
//        CustomerProfileEditView( user: DBUser(id: UUID().uuidString,firstName: "Michael",lastName: "Espineli"), company: Company(id: ""), customer: Customer(id: UUID().uuidString, firstName: "Ron", lastName: "Palace", email: "Email@gmail.com", billingAddress: Address(streetAddress: "6160 Broadmoor Dr ", city: "La Mesa", state: "Ca", zip: "91942", latitude: 32.790086, longitude: -116.991113), active: true, displayAsCompany: false, hireDate: Date(), billingNotes: ""))
//
//    }
//}

