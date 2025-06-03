    //
    //  ServiceLocationDetailView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //


import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ServiceLocationDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published var loadedImages:[DripDropStoredImage] = []
    
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published var selectedBOW:BodyOfWater? = nil
    
    func getAllBodiesOfWaterByServiceLocation(companyId: String,serviceLocation:ServiceLocation) async throws {
        
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: serviceLocation)
        
    }
    func updatePhotoUrl(companyId:String,serviceLocationId:String) {
        Task{
            do {
                var uploadedImages : [DripDropStoredImage] = []
                for photo in selectedDripDropPhotos {
                    let (path,name) = try await dataService.uploadServiceLocationImage(companyId: companyId, serviceLocationId: serviceLocationId, image: photo)
                    let storedImage = DripDropStoredImage(
                        id: UUID().uuidString,
                        description: name,
                        imageURL: path
                    )
                    uploadedImages.append(storedImage)
                    self.loadedImages.append(storedImage)
                    
                }
                try await dataService.updateServiceLocationPhotoURLs(companyId: companyId, serviceLocationId: serviceLocationId, photoUrls: uploadedImages)
                self.selectedDripDropPhotos = []
            } catch {
                print(error)
            }
        }
    }
}
struct ServiceLocationDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService: ProductionDataService
    
        //ViewModels
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    @StateObject var VM : ServiceLocationDetailViewModel
    
        //received Variables
    @State var location:ServiceLocation
    init(dataService:any ProductionDataServiceProtocol,location:ServiceLocation){
        _VM = StateObject(wrappedValue: ServiceLocationDetailViewModel(dataService: dataService))
        
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _location = State(wrappedValue: location)
        
    }
        //Variables for use
    @State var showEditSheet:Bool = false
    @State var showAddSheet:Bool = false
    @State var isLoading:Bool = false
    @State var showLocationSetUp:Bool = false
    @State var scheduleLocationSetUp:Bool = false
    @State var changeContact:Bool = false
    
    @State var notes:String = "Start Up String"
    
    var body: some View {
        ZStack{
            if isLoading {
                ProgressView()
            } else {
                VStack{
                    info
                    photos
                    Rectangle()
                        .frame(height: 4)
                    bodiesOfWater
                }
            }
        }
        .task{
            isLoading = true
            do {
                if let location = masterDataManager.selectedServiceLocation, let currentCompany = masterDataManager.currentCompany {
                    notes = location.notes ?? ""
                    VM.loadedImages = location.photoUrls ?? []
                    
                    try await VM.getAllBodiesOfWaterByServiceLocation(companyId: currentCompany.id, serviceLocation: location)
                    if VM.bodiesOfWater.count != 0 {
                        VM.selectedBOW = VM.bodiesOfWater.first!
                        masterDataManager.selectedBodyOfWater = VM.bodiesOfWater.first!
                        
                    } else {
                        VM.selectedBOW = nil
                        masterDataManager.selectedBodyOfWater = nil
                    }
                }
            } catch{
                print("Error")
            }
            isLoading = false
        }
        .onChange(of: masterDataManager.selectedServiceLocation, perform: { loc in
            Task{
                isLoading = true
                do {
                    if let location = loc, let currentCompany = masterDataManager.currentCompany {
                        notes = location.notes ?? ""
                        VM.loadedImages = location.photoUrls ?? []
                        
                        try await VM.getAllBodiesOfWaterByServiceLocation(companyId: currentCompany.id, serviceLocation: location)
                        if VM.bodiesOfWater.count != 0 {
                            VM.selectedBOW = VM.bodiesOfWater.first!
                            masterDataManager.selectedBodyOfWater = VM.bodiesOfWater.first!
                        } else {
                            VM.selectedBOW = nil
                            masterDataManager.selectedBodyOfWater = nil
                        }
                    }
                } catch{
                    print("Error")
                }
                isLoading = false
            }
        })
        .onChange(of: VM.selectedDripDropPhotos, perform: { photos in
            if let currentCompany = masterDataManager.currentCompany, let location = masterDataManager.selectedServiceLocation {
                VM.updatePhotoUrl(companyId: currentCompany.id, serviceLocationId: location.id)
            }
        })
    }
}
extension ServiceLocationDetailView {
    var edit: some View {
        HStack{
            if let location = masterDataManager.selectedServiceLocation {
                Button(action: {
                    showEditSheet = true
                }, label: {
                    Text("Edit")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $showEditSheet, content: {
                    EditServiceLocationView(dataService: dataService, serviceLocation: location)
                })
            }
        }
    }
    var info: some View {
        HStack{
            VStack(alignment: .leading){
                if let location = masterDataManager.selectedServiceLocation {
                    VStack{
                        HStack{
                            
                            Text("Nick Name:")
                                .bold(true)
                            Text("\(location.nickName)")
                            
                            Spacer()
                            edit
                        }
                    }
                    contactInfo
                    HStack{
                        Text("Address:")
                            .bold(true)
                        Spacer()
                    }
                    HStack{
                        Text("\(location.address.streetAddress)")
                        Spacer()
                    }
                    HStack{
                        Text("\(location.address.city)")
                        Text("\(location.address.state)")
                        Text("\(location.address.zip)")
                        
                    }
                    HStack{
                        Text("Dog Name:")
                            .bold(true)
                        Spacer()
                    }
                    HStack{
                        ForEach(location.dogName ?? [],id:\.self){ dog in
                            Text("\(dog)")
                        }
                    }
                    HStack{
                        Text("Estimated Time:")
                            .bold(true)
                        if let time = location.estimatedTime {
                            Text("\(time)")
                        }
                        Spacer()
                    }
                    HStack{
                        Text("Gate Code:")
                            .bold(true)
                        Text("\(location.gateCode)")
                        Spacer()
                    }
                    
                    HStack{
                        Text("Notes:")
                            .bold(true)
                        if let notes = location.notes {
                            Text("\(notes)")
                            TextField(
                                "Description",
                                text: $notes,
                                axis: .vertical
                            )
                            .submitLabel(.done)
                            .padding(5)
                            .background(Color.gray.opacity(0.5))
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(5)
                        }
                        Spacer()
                    }
                    
                }
            }
            
        }
        .padding(8)
        .background(Color.gray.opacity(0.5))
        .cornerRadius(8)
    }
    var contactInfo: some View {
        VStack{
            HStack{
                Button(action: {
                    changeContact.toggle()
                }, label: {
                    Text("Change")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $changeContact, content: {
                    if let location = masterDataManager.selectedServiceLocation {
                        
                        ChangeServiceLocationContact(dataService: dataService, serviceLocation: location)
                            .presentationDetents([.medium,.large])
                    }
                })
                Spacer()
                Text("Main Contact")
                    .bold(true)
                Spacer()
                
            }
            Divider()
            ContactInfo(contact: location.mainContact)
            Divider()
        }
    }
    var photos: some View {
        VStack{
            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
            if !VM.selectedDripDropPhotos.isEmpty {
                HStack{
                    Text("Loading Images...")
                    ProgressView()
                }
            }
            if VM.loadedImages.isEmpty {
                Text("No Images")
            } else {
                DripDropStoredImageRow(images: VM.loadedImages)
            }
        }
    }
    var bodiesOfWater: some View {
        VStack{
            Divider()
            Text("Bodies Of Water Detail View")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    
                    if VM.bodiesOfWater.count == 0 {
                        HStack{
                            Button(action: {
                                scheduleLocationSetUp.toggle()
                            }, label: {
                                Text("Schedule Set Up Time")
                                    .modifier(AddButtonModifier())
                            })
                            .sheet(isPresented: $scheduleLocationSetUp, content: {
                                if let customer = masterDataManager.selectedCustomer {
                                        //                                CustomerLocationSetUpSchedule(customer: customer, location: location)
                                    AddNewJobView(dataService: dataService)
                                }
                            })
                            Spacer()
                            Button(action: {
                                showLocationSetUp.toggle()
                            }, label: {
                                Text("Show Location Set Up")
                                    .modifier(AddButtonModifier())
                            })
                            .sheet(isPresented: $showLocationSetUp, content: {
                                if let location = masterDataManager.selectedServiceLocation {
                                        //                                ServiceLocationStartUpViewInField(dataService: dataService, customerId: customer.id)
                                    
                                    ServiceLocationStartUpView(dataService: dataService, serviceLocation: location, isPresented: $showLocationSetUp) //DEVELOPER MOVE THIS TO A JOB
                                }
                            })
                        }
                    } else {
                        Button(action: {
                            showAddSheet = true
                        }, label: {
                            Image(systemName: "plus.square.on.square")
                                .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $showAddSheet, content: {
                            if let location = masterDataManager.selectedServiceLocation {
                                AddBodyOfWaterView(dataService: dataService, serviceLocation: location)
                            }
                        })
                        ForEach(VM.bodiesOfWater){ BOW in
                            Button(action: {
                                VM.selectedBOW = nil
                                VM.selectedBOW = BOW
                                masterDataManager.selectedBodyOfWater = BOW
                            }, label: {
                                if VM.selectedBOW == BOW {
                                    Text(BOW.name)
                                        .modifier(AddButtonModifier())
                                } else {
                                    Text(BOW.name)
                                        .modifier(ListButtonModifier())
                                }
                                
                                
                            })
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        }
                        
                        
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            
            if let verifiedBodyOfWater = VM.selectedBOW {
                
                BodyOfWaterDetailView(dataService: dataService, bodyOfWater: verifiedBodyOfWater)
            } else {
                if VM.bodiesOfWater.count == 0 {
                    Text("No Bodies Of water Set Up ")
                } else {
                    Text("Please select a Body of Water")
                }
            }
        }
    }
    var map: some View {
        ZStack{
            VStack{
                BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: location.address.latitude, longitude: location.address.longitude))
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
                .padding(EdgeInsets(top: 125, leading: 10, bottom: 0, trailing: 10))
            }
        }
    }
}
struct ServiceLocationDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        @State var showSignInView: Bool = false
        
        ServiceLocationDetailView(
            dataService: dataService,
            location: MockDataService.mockServiceLocation
        )
    }
}


