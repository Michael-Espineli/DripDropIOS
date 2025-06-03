    //
    //  AddressSearchBar.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/5/24.
    //

import SwiftUI
import MapKit
import Combine
struct LocalSearchViewData: Identifiable {
    var id = UUID()
    var title: String
    var subtitle: String
    var street : String
    var city : String
    var state : String
    var zip : String
    var long : Double
    var lat : Double
    
    
    init(mapItem: MKMapItem) {
        self.title = mapItem.name ?? ""
        self.subtitle = mapItem.placemark.title ?? ""
        
        self.street = mapItem.placemark.postalAddress?.street ?? ""
        self.city = mapItem.placemark.postalAddress?.city  ?? ""
        self.state = mapItem.placemark.postalAddress?.state  ?? ""
        self.zip = mapItem.placemark.postalAddress?.postalCode  ?? ""
        self.long = mapItem.placemark.location?.coordinate.longitude ?? -116.5
        self.lat = mapItem.placemark.location?.coordinate.latitude ?? 32.3
        
    }
}
final class LocalSearchService {
    let localSearchPublisher = PassthroughSubject<[MKMapItem], Never>()
    private let center: CLLocationCoordinate2D
    private let radius: CLLocationDistance
    
    init(in center: CLLocationCoordinate2D,
         radius: CLLocationDistance = 350_000) {
        self.center = center
        self.radius = radius
    }
    
    public func searchCities(searchText: String) {
        request(resultType: .address, searchText: searchText)
    }
    
    private func request(resultType: MKLocalSearch.ResultType = .address,
                         searchText: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = resultType
            //        request.region = MKCoordinateRegion(center: center,
            //                                            latitudinalMeters: radius,
            //                                            longitudinalMeters: radius)
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self](response, _) in
            guard let response = response else {
                return
            }
            self?.localSearchPublisher.send(response.mapItems)
        }
    }
}
final class ContentViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    
    @Published var cityText = "" {
        didSet {
            searchForCity(text: cityText)
        }
    }
    @Published var viewData = [LocalSearchViewData]()
    
    var service: LocalSearchService
    
    init() {
            //        New York
        let center = CLLocationCoordinate2D(latitude: 40.730610, longitude: -73.935242)
        service = LocalSearchService(in: center)
        
        cancellable = service.localSearchPublisher.sink { mapItems in
            self.viewData = mapItems.map({ LocalSearchViewData(mapItem: $0) })
        }
    }
    
    private func searchForCity(text: String) {
        service.searchCities(searchText: text)
    }
    
}

@MainActor
final class AddressSearchBarViewModel:ObservableObject{
    private var dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    
}
struct AddressSearchBar: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var viewModel = ContentViewModel()
    @StateObject var VM : AddressSearchBarViewModel
    @Binding var address : Address
    
    init(dataService:any ProductionDataServiceProtocol,address:Binding<Address>){
        _VM = StateObject(wrappedValue: AddressSearchBarViewModel(dataService: dataService))
        self._address = address
    }
    
    var body: some View {
        VStack{
            content
        }
    }
}
extension AddressSearchBar {
    var content : some View {
        VStack(alignment: .leading) {
            if address.longitude != 0 || address.latitude != 0 {
                BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: address.latitude, longitude: address.longitude))
                    .frame(height: 150)
            }
            HStack{
                TextField("Search Address", text: $viewModel.cityText)
                Button(action: {
                    viewModel.cityText = ""
                }, label: {
                    Image(systemName: "xmark")
                })
            }
            .modifier(TextFieldModifier())
            Divider()
            ForEach(viewModel.viewData) { item in
                Button(action: {
                    address = Address(
                        streetAddress: item.street,
                        city: item.city,
                        state: item.state,
                        zip: item.zip,
                        latitude: item.lat,
                        longitude: item.long
                    )
                },
                       label: {
                    Text("\(item.street) \(item.state) \(item.city) \(item.zip) ")
                })
            }
            
        }
        .padding(.top)
    }
}
    //#Preview {
    //    AddressSearchBar()
    //}
