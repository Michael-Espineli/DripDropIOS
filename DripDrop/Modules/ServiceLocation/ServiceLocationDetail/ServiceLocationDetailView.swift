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
    func updateNotes(companyId:String,serviceLocationId:String,notes:String) {
        Task{
            do {
                try await dataService.updateServiceLocationNotes(companyId: companyId, serviceLocationId: serviceLocationId, notes: notes)
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
        ZStack {
              Color.listColor.ignoresSafeArea()

              if isLoading {
                  ProgressView()
                      .scaleEffect(1.1)
              } else {
                  ScrollView(showsIndicators: false) {
                      VStack(spacing: 12) {
                          info
                              .padding(12)
                          photos
                              .padding(12)

                          Divider()
                              .opacity(0.15)
                              .padding(.vertical, 2)

                          bodiesOfWater
                      }
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
        .onChange(of: notes, perform: { newNotes in
            if let notes = location.notes {
                if newNotes != notes {
                    if let currentCompany = masterDataManager.currentCompany {
                        VM.updateNotes(companyId: currentCompany.id, serviceLocationId: location.id, notes: newNotes)
                        print("[][] Update Notes: \(newNotes)")
                    }
                }
            } else {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.updateNotes(companyId: currentCompany.id, serviceLocationId: location.id, notes: newNotes)
                    print("[][] New Notes: \(newNotes)")
                }
            }
            print("[][] Notes Change")
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
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                if let location = masterDataManager.selectedServiceLocation {

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.nickName)
                                .font(.title3.weight(.semibold))
                                .lineLimit(1)

                            Text("Service Location")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        edit
                    }

                    contactInfo

                    Divider().opacity(0.15)

                    Text("Address").ddSectionTitle()
                    Text("\(location.address.streetAddress)")
                        .font(.subheadline)
                    Text("\(location.address.city) \(location.address.state) \(location.address.zip)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider().opacity(0.15)

                    if let dogs = location.dogName, !dogs.isEmpty {
                        Text("Dog Name").ddSectionTitle()
                        FlowTags(tags: dogs)
                    }

                    HStack {
                        Text("Estimated Time").ddSectionTitle()
                        Spacer()
                        if let time = location.estimatedTime {
                            Text("\(time)")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    HStack {
                        Text("Gate Code").ddSectionTitle()
                        Spacer()
                        Text("\(location.gateCode)")
                            .font(.subheadline.weight(.semibold))
                    }

                    Divider().opacity(0.15)

                    Text("Notes").ddSectionTitle()

                    // Keep your existing binding + updateNotes logic intact
                    TextField(
                        "Description",
                        text: $notes,
                        axis: .vertical
                    )
                    .frame(maxWidth: .infinity)
                    .submitLabel(.done)
                    .modifier(PlainTextFieldModifier())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ddCard()
    }
    
    var contactInfo: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    changeContact.toggle()
                }, label: {
                    Text("Change")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $changeContact, content: {
                    if let location = masterDataManager.selectedServiceLocation {
                        ChangeServiceLocationContact(dataService: dataService, serviceLocation: location)
                            .presentationDetents([.medium, .large])
                    }
                })

                Spacer()

                Text("Main Contact")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Divider().opacity(0.15)

            ContactInfo(contact: location.mainContact)

            Divider().opacity(0.15)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }

    var photos: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos").ddSectionTitle()
                Spacer()
            }

            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)

            if !VM.selectedDripDropPhotos.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading Images...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
            }

            if VM.loadedImages.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(.secondary)
                    Text("No Images")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                DripDropStoredImageRow(images: VM.loadedImages)
            }
        }
        .ddCard()
    }

    var bodiesOfWater: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bodies Of Water").ddSectionTitle()
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if VM.bodiesOfWater.count == 0 {
                        Button(action: {
                            scheduleLocationSetUp.toggle()
                        }, label: {
                            Text("Schedule Set Up")
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                        })
                        .modifier(AddButtonModifier())
                        .sheet(isPresented: $scheduleLocationSetUp, content: {
                            AddNewJobView(dataService: dataService, customerId: location.customerId)
                        })

                        Button(action: {
                            showLocationSetUp.toggle()
                        }, label: {
                            Text("Set Up Location")
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                        })
                        .modifier(AddButtonModifier())
                        .sheet(isPresented: $showLocationSetUp, content: {
                            if let location = masterDataManager.selectedServiceLocation {
                                ServiceLocationStartUpView(dataService: dataService, serviceLocation: location, isPresented: $showLocationSetUp)
                            }
                        })

                    } else {
                        Button(action: {
                            showAddSheet = true
                        }, label: {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                                .padding(10)
                                .background(Circle().fill(Color.primary.opacity(0.08)))
                        })
                        .sheet(isPresented: $showAddSheet, content: {
                            if let location = masterDataManager.selectedServiceLocation {
                                AddBodyOfWaterView(dataService: dataService, serviceLocation: location)
                            }
                        })

                        ForEach(VM.bodiesOfWater) { BOW in
                            Button(action: {
                                VM.selectedBOW = nil
                                VM.selectedBOW = BOW
                                masterDataManager.selectedBodyOfWater = BOW
                            }, label: {
                                Text(BOW.name)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule().fill(
                                            VM.selectedBOW == BOW
                                            ? Color.primary.opacity(0.14)
                                            : Color.primary.opacity(0.06)
                                        )
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            VM.selectedBOW == BOW
                                            ? Color.primary.opacity(0.22)
                                            : Color.primary.opacity(0.10),
                                            lineWidth: 1
                                        )
                                    )
                            })
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            if let verifiedBodyOfWater = VM.selectedBOW {
                BodyOfWaterDetailView(dataService: dataService, bodyOfWater: verifiedBodyOfWater)
//                    .ddCard()
            } else {
                Group {
                    if VM.bodiesOfWater.count == 0 {
                        Text("No Bodies Of water Set Up")
                    } else {
                        Text("Please select a Body of Water")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
            }
        }
//        .ddCard()
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
    private struct FlowTags: View {
        let tags: [String]

        var body: some View {
            // Simple horizontal wrap alternative: show as a flexible HStack-like list
            // (No geometry tricks; keeps it lightweight)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule().fill(Color.primary.opacity(0.07))
                            )
                            .overlay(
                                Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
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


private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddSectionTitle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
