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
    let onSave: (ServiceLocation) -> Void
    let onDelete: (String) -> Void
    init(
        dataService:any ProductionDataServiceProtocol,
        location:ServiceLocation,
        onSave: @escaping (ServiceLocation) -> Void = { _ in },
        onDelete: @escaping (String) -> Void = { _ in }
    ){
        _VM = StateObject(wrappedValue: ServiceLocationDetailViewModel(dataService: dataService))
        
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _location = State(wrappedValue: location)
        self.onSave = onSave
        self.onDelete = onDelete
        
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
                  VStack(spacing: 12) {
                      info
                      photos

                      Divider()
                          .opacity(0.15)
                          .padding(.vertical, 2)

                      bodiesOfWater
                  }
                  .frame(maxWidth: .infinity)
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
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                })
                .buttonStyle(.plain)
                .sheet(isPresented: $showEditSheet, content: {
                    EditServiceLocationView(
                        dataService: dataService,
                        serviceLocation: location,
                        onSave: { updatedLocation in
                            self.location = updatedLocation
                            masterDataManager.selectedServiceLocation = updatedLocation
                            onSave(updatedLocation)
                        },
                        onDelete: { deletedLocationId in
                            onDelete(deletedLocationId)
                        }
                    )
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

                    contactInfo(for: location.mainContact)

                    Divider().opacity(0.15)

                    Text("Address").ddSectionTitle()
                    addressLink(for: location.address)

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
    
    private func contactInfo(for contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())

                Text("Main Contact")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: {
                    changeContact.toggle()
                }, label: {
                    Label("Change", systemImage: "person.crop.circle.badge.plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                })
                .buttonStyle(.plain)
                .sheet(isPresented: $changeContact, content: {
                    if let location = masterDataManager.selectedServiceLocation {
                        ChangeServiceLocationContact(dataService: dataService, serviceLocation: location)
                            .presentationDetents([.medium, .large])
                    }
                })
            }

            contactInfoRow(
                title: "Name",
                value: contact.name,
                systemImage: "person.fill",
                tint: .poolBlue
            )

            contactInfoRow(
                title: "Email",
                value: contact.email,
                systemImage: "envelope.fill",
                tint: .orange
            )

            contactInfoRow(
                title: "Phone",
                value: contact.phoneNumber,
                systemImage: "phone.fill",
                tint: .poolGreen
            )

            contactInfoRow(
                title: "Notes",
                value: contact.notes ?? "",
                systemImage: "note.text",
                tint: .secondary,
                lineLimit: 3
            )
        }
        .padding(.vertical, 2)
    }

    private func contactInfoRow(
        title: String,
        value: String,
        systemImage: String,
        tint: Color,
        lineLimit: Int = 1
    ) -> some View {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(trimmedValue.isEmpty ? "Missing" : trimmedValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(trimmedValue.isEmpty ? Color.orange : Color.primary)
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func addressLink(for address: Address) -> some View {
        let canOpenAddress = mapsURL(for: address) != nil

        return Button {
            openAddressInMaps(address)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
                    .frame(width: 34, height: 34)
                    .background(Color.poolGreen.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(addressStreetLine(address))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(addressCityLine(address))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if canOpenAddress {
                        Text("Open in Maps")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.poolBlue)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: canOpenAddress ? "arrow.up.right" : "location.slash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())
            }
            .padding(10)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canOpenAddress)
        .opacity(canOpenAddress ? 1 : 0.72)
        .accessibilityLabel(canOpenAddress ? "Open service location address in Maps" : "No service location address available")
    }

    var photos: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos").ddSectionTitle()
                Spacer()
            }

            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)

            if !VM.selectedDripDropPhotos.isEmpty {
                DripDropPhotoUploadIndicator(count: VM.selectedDripDropPhotos.count)
            }

            if VM.loadedImages.isEmpty {
                DripDropCompactPhotoEmptyState()
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
                            showAddSheet = true
                        }, label: {
                            Label("Add Body", systemImage: "plus.circle.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.poolGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        })
                        .buttonStyle(.plain)

                        Button(action: {
                            scheduleLocationSetUp.toggle()
                        }, label: {
                            Label("Schedule Set Up", systemImage: "calendar.badge.plus")
                                .font(.caption.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        })
                        .buttonStyle(.plain)
                        .sheet(isPresented: $scheduleLocationSetUp, content: {
                            AddNewJobView(dataService: dataService, customerId: location.customerId)
                        })

                        Button(action: {
                            showLocationSetUp.toggle()
                        }, label: {
                            Label("Set Up Location", systemImage: "sparkles")
                                .font(.caption.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.poolGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        })
                        .buttonStyle(.plain)
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
        .sheet(isPresented: $showAddSheet, onDismiss: {
            refreshBodiesOfWaterAfterSheet()
        }, content: {
            if let location = masterDataManager.selectedServiceLocation {
                AddBodyOfWaterView(dataService: dataService, serviceLocation: location)
                    .presentationDetents([.medium, .large])
            }
        })
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

    private func refreshBodiesOfWaterAfterSheet() {
        Task {
            do {
                guard let currentCompany = masterDataManager.currentCompany,
                      let location = masterDataManager.selectedServiceLocation else {
                    return
                }

                let selectedBodyId = VM.selectedBOW?.id
                try await VM.getAllBodiesOfWaterByServiceLocation(companyId: currentCompany.id, serviceLocation: location)

                if let selectedBodyId,
                   let selectedBody = VM.bodiesOfWater.first(where: { $0.id == selectedBodyId }) {
                    VM.selectedBOW = selectedBody
                    masterDataManager.selectedBodyOfWater = selectedBody
                } else if let firstBody = VM.bodiesOfWater.first {
                    VM.selectedBOW = firstBody
                    masterDataManager.selectedBodyOfWater = firstBody
                } else {
                    VM.selectedBOW = nil
                    masterDataManager.selectedBodyOfWater = nil
                }
            } catch {
                print("Error refreshing bodies of water after add sheet")
            }
        }
    }

    private func openAddressInMaps(_ address: Address) {
        guard let url = mapsURL(for: address) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func mapsURL(for address: Address) -> URL? {
        var components = URLComponents(string: "http://maps.apple.com/")

        if let addressLine = addressSearchLine(address) {
            components?.queryItems = [
                URLQueryItem(name: "q", value: addressLine)
            ]
        } else if hasUsableCoordinates(address) {
            components?.queryItems = [
                URLQueryItem(name: "ll", value: "\(address.latitude),\(address.longitude)"),
                URLQueryItem(name: "q", value: "Service Location")
            ]
        } else {
            return nil
        }

        return components?.url
    }

    private func addressSearchLine(_ address: Address) -> String? {
        let addressLine = [
            address.streetAddress,
            address.city,
            address.state,
            address.zip
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return addressLine.isEmpty ? nil : addressLine
    }

    private func addressStreetLine(_ address: Address) -> String {
        let street = address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        if !street.isEmpty {
            return street
        }

        return hasUsableCoordinates(address) ? "Saved map pin" : "No street address"
    }

    private func addressCityLine(_ address: Address) -> String {
        let cityStateZip = [
            address.city,
            address.state,
            address.zip
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !cityStateZip.isEmpty {
            return cityStateZip
        }

        return hasUsableCoordinates(address) ? "\(address.latitude), \(address.longitude)" : "No city, state, or zip"
    }

    private func hasUsableCoordinates(_ address: Address) -> Bool {
        address.latitude.isFinite &&
        address.longitude.isFinite &&
        abs(address.latitude) <= 90 &&
        abs(address.longitude) <= 180 &&
        !(address.latitude == 0 && address.longitude == 0)
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
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
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
