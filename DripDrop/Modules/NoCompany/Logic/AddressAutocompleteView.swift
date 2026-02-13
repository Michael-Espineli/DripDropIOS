// AddressAutocompleteView.swift
// DripDrop
//
// A SwiftUI wrapper that presents Google Places Autocomplete UI and returns a parsed Address.
// Requires: GooglePlaces SDK added to the project and API key configured in AppDelegate/SceneDelegate.

import SwiftUI
import GooglePlaces
import CoreLocation

// If your project already defines Address elsewhere, remove this and use your existing type.
public struct Address: Equatable, Hashable, Codable {
    public var streetAddress: String
    public var city: String
    public var state: String
    public var zip: String
    public var latitude: Double?
    public var longitude: Double?

    public init(streetAddress: String = "", city: String = "", state: String = "", zip: String = "", latitude: Double? = nil, longitude: Double? = nil) {
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zip = zip
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct AddressAutocompleteView: View {
    @Binding var text: String
    @Binding var selectedAddress: Address?

    var placeholder: String = "Enter Address"
    var showsPinIcon: Bool = true
    var textFieldStyle: (AnyView)? = nil // placeholder for custom styling if desired

    @State private var isPresentingAutocomplete = false

    var body: some View {
        HStack(spacing: 8) {
            if showsPinIcon {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.secondary)
            }
            TextField(placeholder, text: $text)
                .onTapGesture {
                    isPresentingAutocomplete = true
                }
        }
        .sheet(isPresented: $isPresentingAutocomplete) {
            AutocompleteControllerRepresentable { place in
                // Parse into Address
                let parsed = Self.parse(place: place)
                self.selectedAddress = parsed
                self.text = place.formattedAddress ?? ""
                isPresentingAutocomplete = false
            } onCancel: {
                isPresentingAutocomplete = false
            }
        }
    }

    private static func parse(place: GMSPlace) -> Address {
        var address = Address()
        address.latitude = place.coordinate.latitude
        address.longitude = place.coordinate.longitude

        if let components = place.addressComponents {
            for component in components {
                let types = component.types
                if types.contains("street_number") {
                    address.streetAddress = component.name
                }
                if types.contains("route") {
                    address.streetAddress = address.streetAddress.isEmpty ? component.name : "\(address.streetAddress) \(component.name)"
                }
                if types.contains("locality") { // city
                    address.city = component.name
                }
                if types.contains("administrative_area_level_1") { // state
                    address.state = component.shortName ?? component.name
                }
                if types.contains("postal_code") {
                    address.zip = component.name
                }
            }
        }
        return address
    }
}

private struct AutocompleteControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    var onSelect: (GMSPlace) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator

        // Filter to US addresses
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        filter.countries = ["US"]
        autocompleteController.autocompleteFilter = filter

        let nav = UINavigationController(rootViewController: autocompleteController)
        nav.modalPresentationStyle = .formSheet
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, onCancel: onCancel)
    }

    final class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        let onSelect: (GMSPlace) -> Void
        let onCancel: () -> Void

        init(onSelect: @escaping (GMSPlace) -> Void, onCancel: @escaping () -> Void) {
            self.onSelect = onSelect
            self.onCancel = onCancel
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            onSelect(place)
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            // You could present an alert here if desired
            onCancel()
        }

        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            onCancel()
        }
    }
}

#Preview {
    StatefulPreview()
}

private struct StatefulPreview: View {
    @State private var query = ""
    @State private var address: Address? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AddressAutocompleteView(text: $query, selectedAddress: $address)
                if let address {
                    Text("Selected: \(address.streetAddress), \(address.city), \(address.state) \(address.zip)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Address Search")
        }
    }
}
