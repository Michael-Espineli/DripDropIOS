//
//  SimpleCompanyInfoView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/15/25.
//

import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions
import PhotosUI
import CoreLocation
import MapKit

@MainActor
final class SimpleCompanyInfoViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    @Published private(set) var postedCompany : Company? = nil
    @Published private(set) var updatedCompany : Company? = nil
    @Published var companyName : String = ""
    @Published var companyEmail : String = ""
    @Published var companyPhoneNumber : String = ""
    @Published var yelpURL : String = ""
    @Published var webURL : String = ""
    @Published var services : [String] = []
    @Published var serviceZipCodes : [String] = []
    @Published var zipCode : String = ""
    @Published private(set) var placemark: CLPlacemark? = nil


    @Published private(set) var edit : Bool = false
    @Published private(set) var externalAccountLink: URL? = nil

    @Published private(set) var totalActiveCustomers: Float = 1
    @Published private(set) var currentActiveCustomers: Float = 0
    @Published var industryTypes:[String] = ["Pool Cleaning","Green To Blue","Filter Cleaning","Salt Cell Cleaning","Leak Detection","Pool Building","Commercial","Residential"]
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    func onLoad(companyId:String) async throws {
        
        self.totalActiveCustomers = 50
        self.currentActiveCustomers = 25
    }
    func editCompany(_ company:Company){
        self.edit = true
        self.companyName = company.name
        self.companyEmail = company.email
        self.companyPhoneNumber = company.phoneNumber
        self.services = company.services
        self.serviceZipCodes = company.serviceZipCodes
        self.yelpURL = company.yelpURL
        self.webURL = company.websiteURL
        
    }
    func saveChanges(_ company: Company?){
        Task{
            do {
                //Verify Data
                guard let company = company else {
                    print("No Company Found")
                    return
                }
                if companyName == ""{
                    self.alertMessage = "No Company Name"
                    self.showAlert = true
                    print(alertMessage)
                    return
                }
                if companyEmail == ""{
                    self.alertMessage = "No Company Email"
                    self.showAlert = true
                    print(alertMessage)
                    return
                    
                }
                if companyPhoneNumber == ""{
                    if companyPhoneNumber != company.phoneNumber{
                        
                        self.alertMessage = "No Company Phone Number"
                        self.showAlert = true
                        print(alertMessage)
                        return
                    }
                }
                if services == []{
                    
                    self.alertMessage = "No Services Selected"
                    self.showAlert = true
                    print(alertMessage)
                    return
                    
                }
                if serviceZipCodes == []{
                    self.alertMessage = "No Zip Codes Selected"
                    self.showAlert = true
                    print(alertMessage)
                    return
                }
                if webURL == ""{
                    if webURL != company.websiteURL{
                        self.alertMessage = "Web URL Empty"
                        self.showAlert = true
                        print(alertMessage)
                        return
                    }
                }
                if yelpURL == ""{
                    if yelpURL != company.yelpURL{
                        self.alertMessage = "Yelp URL Empty"
                        self.showAlert = true
                        print(alertMessage)
                        return
                    }
                }
                if companyName != company.name{
                    try await dataService.updateCompanyName(companyId: company.id, name: companyName)
                }
                if companyEmail != company.email{
                    try await dataService.updateCompanyEmail(companyId: company.id, email: companyEmail)
                    
                }
                if companyPhoneNumber != company.phoneNumber{
                    try await dataService.updateCompanyPhoneNumber(companyId: company.id, phoneNumber: companyPhoneNumber)
                    
                }
                if services != company.services{
                    try await dataService.updateCompanyServicesOffered(companyId: company.id, servicesOffered: services)
                    
                }
                if serviceZipCodes != company.serviceZipCodes{
                    try await dataService.updateCompanyZipCodes(companyId: company.id, serviceZipCodes: serviceZipCodes)
                    
                }
                if webURL != company.websiteURL{
                    try await dataService.updateCompanyWebUrl(companyId: company.id, websiteUrl: webURL)
                    
                }
                if yelpURL != company.yelpURL{
                    try await dataService.updateCompanyYelpURl(companyId: company.id, yelpURL: yelpURL)
                    
                }
                self.updatedCompany = Company(
                    id: company.id,
                    ownerId: company.ownerId,
                    ownerName: company.ownerName,
                    name: companyName,
                    dateCreated: company.dateCreated,
                    email: companyEmail,
                    phoneNumber: companyPhoneNumber,
                    verified: company.verified,
                    serviceZipCodes: serviceZipCodes,
                    services: services,
                    accountType: company.accountType,
                    paidUntil: company.paidUntil,
                    status: company.status,
                    stripeConnectAccountId: company.stripeConnectAccountId,
                    stripeConnectAccountStatus: company.stripeConnectAccountStatus,
                    yelpURL: yelpURL,
                    websiteURL: webURL
                )
                self.edit = false
            } catch {
                print(error)
            }
        }
    }
    func cancelChanges(){
        self.edit = false
    }
    func setUpStripeAccount(company:Company,user:DBUser) {
        Task{
            do {
                guard let stripeConnectAccountId = company.stripeConnectAccountId, !stripeConnectAccountId.isEmpty else{
                    return
                }
                
                print("--createStripeAccountLink--")
                let data:[String:Any] = [
                    "companyId": company.id,
                    "accountId": stripeConnectAccountId,
                    "stripeVersion": "2023-10-16",
                ]
                let result = try await Functions.functions().httpsCallable("createStripeAccountLink").call(data)
                guard let json = result.data as? [String: Any] else {
                    
                      print("Failed to Parse JSON")
                  return
                }
                guard let accountLink = json["accountLink"] as? String else {
                  // Handle error
                    print("Failed to Get Account Link")
                  return
                }
                guard let url = URL(string: accountLink) else {
                    // Handle error
                      print("Failed to Make URL")
                    return
                  }
                    
                self.externalAccountLink = url
            } catch {
                print(error)
            }
        }
    }
    func getCityFromZip() async throws {
        let geoCoder = CLGeocoder()
        if zipCode != "" && zipCode.count == 5 {
            let placemarkList = try await geoCoder.geocodeAddressString(zipCode)
            if !placemarkList.isEmpty {
                self.placemark = placemarkList.first!
            }
        }
    }
    func addZipToList() async throws {
        //Validate
        if zipCode.count == 5 {
            serviceZipCodes.append(zipCode)
            self.zipCode = ""
            self.placemark = nil
        }
    }

}
struct SimpleCompanyInfoView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: SimpleCompanyInfoViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : SimpleCompanyInfoViewModel
    
    @StateObject private var companyVM = CompanyViewModel()
    @State private var selectedPhoto:PhotosPickerItem? = nil
#if os(iOS)
    @State private var displayImage:UIImage? = nil
#endif

    @State private var displayURL:URL? = nil
    @State private var urlDisplayString:String? = nil
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators:false){
                if VM.edit {
                    editProfile
                } else {
                    profile
                }
            }
            .fontDesign(.monospaced)
            .padding(8)
        }
        .navigationTitle(VM.edit ? "Edit Company Info" : masterDataManager.currentCompany?.name ?? "")
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await companyVM.loadCurrentCompany(companyId: company.id)
                    try await VM.onLoad(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: selectedPhoto, perform: { newValue in
            if let newValue {
                Task{
                print("Save Profile")
                    //Developer Fix Later
//                    companyVM.saveProfileImage(user: user, companyId: companyVM.company?.id ?? user.favoriteCompanyId, item: newValue)
                }
            }
        })
        .onChange(of: VM.zipCode, perform: { newValue in
            Task{
                try? await VM.getCityFromZip()
                print(newValue)
            }
        })
        
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

//struct CompanyProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        @State var showSignInView: Bool = false
//        CompanyProfileView()
//    }
//}
extension SimpleCompanyInfoView {
    var editProfile: some View {
        VStack {
            HStack{
                Button(action: {
                    VM.cancelChanges()
                }, label: {
                    Text("Cancel")
                        .modifier(DeleteButtonModifier())
                })
                Spacer()
                
                Button(action: {
                    VM.saveChanges(masterDataManager.currentCompany)
                }, label: {
                    Text("Save")
                        .modifier(BlueButtonModifier())
                })
            }
            
            //Company Info
            VStack{
                VStack{
                    HStack{
                        Text("Name:")
                            .bold()
                        Spacer()
                    }
                    TextField(
                        "Name",
                        text: $VM.companyName
                    )
                    .modifier(PlainTextFieldModifier())
                    .submitLabel(.next)
                }
                
                VStack{
                    HStack{
                        Text("Email:")
                            .bold()
                        Spacer()
                    }
                    TextField(
                        "Email",
                        text: $VM.companyName
                    )
                    .modifier(PlainTextFieldModifier())
                    .submitLabel(.next)
                }
                
                VStack{
                    HStack{
                        Text("Phone Number:")
                            .bold()
                        Spacer()
                    }
                    TextField(
                        "Phone Number",
                        text: $VM.companyPhoneNumber
                    )
                    .modifier(PlainTextFieldModifier())
                    .submitLabel(.next)
                }
                .keyboardType(.phonePad)

            }
            
            Rectangle()
                .frame(height: 1)
                //Service Info
            VStack{
                HStack{
                    Text("Services Offered:")
                        .bold()
                    Spacer()
                }
                VStack{
                    VStack(alignment: .leading) {
                        ForEach(VM.industryTypes,id:\.self) { type in
                            Button(action: {
                                if !VM.services.contains(type) {
                                    VM.services.append(type)
                                } else {
                                    
                                    VM.services.remove(type)
                                }
                            }, label: {
                                Text(type)
                                    .font(.headline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                                    .background(VM.services.contains(type) ? Color.poolBlue : Color.white)
                                    .clipShape(Capsule())
                                    .foregroundColor(VM.services.contains(type) ? Color.white : Color.poolBlue)
                            })
                        }
                    }
                }
                VStack{
                    Text("Regions Serviced:")
                    HStack{
                        TextField("Zip Code:", text: $VM.zipCode, prompt: Text("Zip Code"))
                            .modifier(PlainTextFieldModifier())
                        Button(action: {
                            Task{
                                try? await VM.addZipToList()
                            }
                        }, label: {
                            Text("Add")
                                .modifier(AddButtonModifier())
                        })
                    }
                    HStack{
                        if let placemark = VM.placemark, let address = placemark.postalAddress{
                            Text(" \(address.city), \(address.state)")
                        }
                        Spacer()
                    }
                    HStack{
                        Text("Selected: ")
                            .fontWeight(.bold)
                        ScrollView(.horizontal,showsIndicators: false) {
                            HStack{
                                
                                ForEach(VM.serviceZipCodes,id:\.self) { zip in
                                    HStack{
                                        Text(zip)
                                        
                                        Button(action: {
                                            if VM.serviceZipCodes.contains(zip) {
                                                VM.serviceZipCodes.remove(zip)
                                            } else {
                                                VM.serviceZipCodes.append(zip)
                                            }
                                        }, label: {
                                            Image(systemName: "xmark")
                                        })
                                    }
                                    .font(.headline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                                    .background(VM.serviceZipCodes.contains(zip) ? Color.poolBlue : Color.white)
                                    .clipShape(Capsule())
                                    .foregroundColor(VM.serviceZipCodes.contains(zip) ? Color.white : Color.poolBlue)
                                }
                            }
                        }
                    }
                    if let placemark = VM.placemark , let location = placemark.location{
                        MiniMapView(coordinates: location.coordinate)
                    } else {
                        Text("No Mini Map")
                    }
                }
            }
            Rectangle()
                .frame(height: 1)
            //Social Media And Links
            VStack{
                Text("Social Media And Links:")
                    .font(.headline)
                    .padding(.top,16)
                
                VStack{
                    HStack{
                        Text("Yelp URL:")
                        Spacer()
                        PasteButton(payloadType: String.self) { strings in
                            guard let first = strings.first else { return }
                            VM.yelpURL = first
                        }
                    }
                    TextField(
                        "Yelp URL",
                        text: $VM.yelpURL
                    )
                    .modifier(PlainTextFieldModifier())
                    .submitLabel(.next)
                }
                VStack{
                    HStack{
                        Text("Web URL:")
                        Spacer()
                        PasteButton(payloadType: String.self) { strings in
                            guard let first = strings.first else { return }
                            VM.yelpURL = first
                        }
                    }
                    TextField(
                        "Web URL",
                        text: $VM.webURL
                    )
                    .modifier(PlainTextFieldModifier())
                    .submitLabel(.next)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
    }
    var profile: some View {
        VStack {
            if let company = VM.updatedCompany {
                HStack{
                    image
                    Spacer()
                    
                    Button(action: {
                        VM.editCompany(company)
                    }, label: {
                        Text("Edit")
                            .modifier(BlueButtonModifier())
                    })
                }
                SimpleCompanySubView(company: company)
                
//                Rectangle()
//                    .frame(height: 1)
//                VStack{
//                    Text("Company Stats")
//                        .font(.headline)
//                        .padding(.top,16)
//                    Divider()
//                    HStack{
//                        Text("Clients Under Contract:")
//                        Spacer()
//                    }
//                    HStack{
//                        Text("Monthly Profit:")
//                        Spacer()
//                    }
//                    HStack{
//                        Text("Monthly Revenue:")
//                        Spacer()
//                    }
//                    
//                }
                Rectangle()
                    .frame(height: 1)
                VStack{
                    HStack{
                        Spacer()
                        Text("Subscription")
                            .font(.headline)
                        Spacer()
                        NavigationLink(value: Route.editCompanySubscription(dataService: dataService), label: {
                            Text("Manage")
                                .modifier(RedLinkModifier())
                        })
                    }
                    .padding(.top,16)
                    Divider()
                    HStack{
                        Text("Account Type: \(company.accountType.rawValue)") //Starter → Commercial → Enterprise
                        Spacer()
                    }
                    
                    HStack{
                        Text("Active Customers: \(String(format: "%.0f", VM.currentActiveCustomers))/\(String(format: "%.0f", VM.totalActiveCustomers))")
                        Spacer()
                    }
                    ProgressView(value: VM.currentActiveCustomers, total: VM.totalActiveCustomers)
                    
                    HStack{
                        Text("Account Paid Until: \(fullDate(date:company.paidUntil))")
                        Spacer()
                    }
                    HStack{
                        Text("Modify Billing Settings")
                        Spacer()
                    }
                }
                Rectangle()
                    .frame(height: 1)
                    //Stripe Connected Account Status
                VStack{
                    Text("Stripe Connected Account")
                        .font(.headline)
                        .padding(.top,16)
                    HStack{
                        Text("Account Status:")
                        Spacer()
                        if let url = VM.externalAccountLink {
                            Link("Set Up", destination: url)
                                .modifier(YellowButtonModifier())
                        } else {
                            switch company.stripeConnectAccountStatus {
                            case .connected:
                                Text("Connected")
                                    .modifier(BlueButtonModifier())
                            case .failed:
                                Text("Failed")
                                    .modifier(DismissButtonModifier())
                            case .notStarted:
                                Button(action: {
                                    if let user = masterDataManager.user{
                                        VM.setUpStripeAccount(company: company, user: user)
                                    } else {
                                        print("no User")
                                    }
                                }, label: {
                                    Text("Not Started")
                                        .modifier(YellowButtonModifier())
                                })
                            }
                        }
                    }
                }
                
            } else {
                if let company = masterDataManager.currentCompany {
                    HStack{
                        image
                        Spacer()
                        
                        Button(action: {
                            VM.editCompany(company)
                        }, label: {
                            Text("Edit")
                                .modifier(BlueButtonModifier())
                        })
                    }
                    SimpleCompanySubView(company: company)
                    //Update 4.1
//                    Rectangle()
//                        .frame(height: 1)
//                    VStack{
//                        Text("Company Stats")
//                            .font(.headline)
//                            .padding(.top,16)
//                        Divider()
//                        HStack{
//                            Text("Clients Under Contract:")
//                            Spacer()
//                        }
//                        HStack{
//                            Text("Monthly Profit:")
//                            Spacer()
//                        }
//                        HStack{
//                            Text("Monthly Revenue:")
//                            Spacer()
//                        }
//                        
//                    }
                    
                    Rectangle()
                        .frame(height: 1)
                    VStack{
                        HStack{
                            Spacer()
                            Text("Subscription")
                                .font(.headline)
                            Spacer()
                            NavigationLink(value: Route.editCompanySubscription(dataService: dataService), label: {
                                Text("View More")
                                    .modifier(RedLinkModifier())
                            })
                        }
                        .padding(.top,16)
                        Divider()
                        HStack{
                            Text("Account Type: \(company.accountType.rawValue)") //Starter → Commercial → Enterprise
                            Spacer()
                        }
                        HStack{
                            Text("Active Customers: \(String(format: "%.0f", VM.currentActiveCustomers))/\(String(format: "%.0f", VM.totalActiveCustomers))")
                            Spacer()
                        }
                        ProgressView(value: VM.currentActiveCustomers, total: VM.totalActiveCustomers)
                        
                        HStack{
                            Text("Account Paid Until: \(fullDate(date:company.paidUntil))")
                            Spacer()
                        }
                        HStack{
                            Text("Modify Billing Settings")
                            Spacer()
                        }
                    }
                    Rectangle()
                        .frame(height: 1)
                        //Stripe Connected Account Status
                    VStack{
                        Text("Stripe Connected Account")
                            .font(.headline)
                            .padding(.top,16)
                        Divider()
                        HStack{
                            Text("Account Status:")
                            Spacer()
                            if let url = VM.externalAccountLink {
                                Link("Set Up", destination: url)
                                    .modifier(YellowButtonModifier())
                            } else {
                                switch company.stripeConnectAccountStatus {
                                case .connected:
                                    Text("Connected")
                                        .modifier(BlueButtonModifier())
                                case .failed:
                                    Text("Failed")
                                        .modifier(DismissButtonModifier())
                                case .notStarted:
                                    Button(action: {
                                        if let user = masterDataManager.user{
                                            VM.setUpStripeAccount(company: company, user: user)
                                        } else {
                                            print("no User")
                                        }
                                    }, label: {
                                        Text("Not Started")
                                            .modifier(YellowButtonModifier())
                                    })
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    var image: some View {
        ZStack{
            Circle()
                .fill(Color.gray)
                .frame(maxWidth:100 ,maxHeight:100)
            if let urlString = companyVM.imageUrlString,let url = URL(string: urlString){
                AsyncImage(url: url){ image in
                    image
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:95 ,maxHeight:95)
                        .cornerRadius(75)
                } placeholder: {
                    Image(systemName:"person.circle")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:95 ,maxHeight:95)
                        .cornerRadius(75)
                }
            } else {
                Image(systemName:"person.circle")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(Color.white)
                    .frame(maxWidth:95 ,maxHeight:95)
                    .cornerRadius(75)
            }
            if let currentCompany = masterDataManager.currentCompany {
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared(), label: {
                            ZStack{
                                Circle()
                                    .fill(.blue)
                                    .frame(maxWidth:30 ,maxHeight:30)
                                
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth:20 ,maxHeight:20)
                            }
                        })
                    }
                }
                .padding(16)
                
            }
        }
        .frame(maxWidth: 150,maxHeight:150)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
    }
}
