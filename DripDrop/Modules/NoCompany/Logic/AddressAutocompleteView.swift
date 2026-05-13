// AddressAutocompleteView.swift
// DripDrop
//
// A SwiftUI wrapper that presents MapKit address autocomplete UI and returns a parsed Address.
//
// Troubleshooting notes:
// - This uses MKLocalSearchCompleter for live suggestions.
// - Tapping a suggestion uses MKLocalSearch to resolve the completion into a placemark.
// - The completer delegate must be retained, which is why completerDelegate is stored in @State.
// - A debounce is used so MapKit is not queried on every single keystroke.
// - If suggestions are not appearing, check:
//   1. searchField is true
//   2. text is not empty after trimming whitespace
//   3. completer.queryFragment is being set after the debounce
//   4. completerDidUpdateResults is being called
//   5. suggestions is not empty
//   6. completer errors are being printed with full NSError details

import SwiftUI
import MapKit
import CoreLocation

// If your project already defines Address elsewhere, remove this and use your existing type.

struct AddressAutocompleteView: View {
    @Binding var text: String
    @Binding var selectedAddress: Address?

    var placeholder: String = "Search Address"
    var showsPinIcon: Bool = true

    @State private var completer = MKLocalSearchCompleter()
    @State private var suggestions: [MKLocalSearchCompletion] = []

    // Important: MKLocalSearchCompleter.delegate is weak.
    // Store the delegate in @State so it does not get deallocated.
    @State private var completerDelegate: ContextDelegate? = nil

    // Debounce task used to avoid sending a MapKit request on every keystroke.
    @State private var searchTask: Task<Void, Never>? = nil

    @FocusState var searchField: Bool

    var body: some View {
        ZStack(alignment: .top) {
            // Dropdown suggestions
            if searchField &&
                !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !suggestions.isEmpty {

                VStack(spacing: 0) {
                    ForEach(suggestions, id: \.self) { completion in
                        Button {
                            print("[AddressAutocomplete] Tapped suggestion: \(completion.title) — \(completion.subtitle)")
                            resolve(completion)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completion.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if completion != suggestions.last {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                .padding(.horizontal)
                .padding(.top, 56)
                .frame(maxHeight: 280, alignment: .top)
                .clipped()
            }

            // Input row
            HStack(spacing: 8) {
                if showsPinIcon {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                }

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .focused($searchField)
                    .padding(.vertical, 10)
                    .onChange(of: text) { newValue in
                        guard searchField else {
                            print("[AddressAutocomplete] Text changed while field is not focused. Ignoring autocomplete update.")
                            return
                        }

                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("[AddressAutocomplete] User typed: '\(trimmed)'")

                        // Cancel any pending autocomplete request.
                        searchTask?.cancel()

                        if trimmed.isEmpty {
                            print("[AddressAutocomplete] Empty text, clearing suggestions")
                            suggestions = []
                            completer.queryFragment = ""
                            return
                        }

                        // Debounce the autocomplete request.
                        // This prevents MapKit from being queried on every keystroke.
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 350_000_000)

                            guard !Task.isCancelled else {
                                print("[AddressAutocomplete] Debounced search cancelled")
                                return
                            }

                            await MainActor.run {
                                print("[AddressAutocomplete] Debounced queryFragment = '\(trimmed)'")
                                completer.queryFragment = trimmed
                            }
                        }
                    }
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        searchField ? Color.accentColor.opacity(0.4) : Color(.separator),
                        lineWidth: 0.8
                    )
            )
            .padding(.horizontal)
            .padding(.top, 8)
            .onAppear {
                print("[AddressAutocomplete] onAppear: configuring completer")

                // Limit results to address-style completions.
                completer.resultTypes = .address

                // Temporarily commented out while troubleshooting MKErrorDomain Code=5.
                // Once autocomplete works reliably, you can try adding these back one at a time.
                //
                // completer.region = MKCoordinateRegion(
                //     center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                //     span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
                // )
                //
                // completer.pointOfInterestFilter = .excludingAll

                let delegate = ContextDelegate { results in
                    print("[AddressAutocomplete] completerDidUpdateResults -> \(results.count) results")
                    self.suggestions = results
                }

                self.completerDelegate = delegate
                completer.delegate = delegate

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

                if !trimmed.isEmpty {
                    print("[AddressAutocomplete] Seeding completer with existing text: '\(trimmed)'")

                    searchTask?.cancel()

                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 350_000_000)

                        guard !Task.isCancelled else {
                            print("[AddressAutocomplete] Seeded debounced search cancelled")
                            return
                        }

                        await MainActor.run {
                            print("[AddressAutocomplete] Seeded debounced queryFragment = '\(trimmed)'")
                            completer.queryFragment = trimmed
                        }
                    }
                }
            }
            .onDisappear {
                print("[AddressAutocomplete] onDisappear: cancelling search task")

                // Prevent any delayed debounce task from updating the completer after the view disappears.
                searchTask?.cancel()
            }
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) {
        print("[AddressAutocomplete] Resolving: \(completion.title) — \(completion.subtitle)")

        // Cancel any pending autocomplete request because the user has selected a result.
        searchTask?.cancel()

        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = .address

        let search = MKLocalSearch(request: request)

        search.start { response, error in
            if let error = error {
                let nsError = error as NSError

                print("[AddressAutocomplete] MKLocalSearch failed")
                print("domain:", nsError.domain)
                print("code:", nsError.code)
                print("userInfo:", nsError.userInfo)
            }

            guard let item = response?.mapItems.first else {
                print("[AddressAutocomplete] No mapItems returned for completion")
                return
            }

            let placemark = item.placemark
            let parsed = parse(placemark: placemark)

            print("[AddressAutocomplete] Resolved placemark: \(placemark)")
            print("[AddressAutocomplete] Parsed address: street=\(parsed.streetAddress), city=\(parsed.city), state=\(parsed.state), zip=\(parsed.zip)")

            self.selectedAddress = parsed

            self.text = [
                placemark.subThoroughfare,
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.postalCode
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            self.suggestions = []
            self.searchField = false

            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    private func parse(placemark: MKPlacemark) -> Address {
        var street = ""

        if let num = placemark.subThoroughfare, !num.isEmpty {
            street = num
        }

        if let route = placemark.thoroughfare, !route.isEmpty {
            street = street.isEmpty ? route : "\(street) \(route)"
        }

        let city = placemark.locality ?? ""
        let state = placemark.administrativeArea ?? ""
        let zip = placemark.postalCode ?? ""
        let coord = placemark.coordinate

        return Address(
            streetAddress: street,
            city: city,
            state: state,
            zip: zip,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }

    // A lightweight delegate wrapper for MKLocalSearchCompleter.
    //
    // MKLocalSearchCompleter needs an NSObject delegate.
    // This lets us bridge MapKit callbacks back into SwiftUI using a closure.
    private final class ContextDelegate: NSObject, MKLocalSearchCompleterDelegate {
        private let onUpdate: ([MKLocalSearchCompletion]) -> Void

        init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
            self.onUpdate = onUpdate
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            print("[AddressAutocomplete] completerDidUpdateResults called")
            print("[AddressAutocomplete] results count:", completer.results.count)

            onUpdate(completer.results)
        }

        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
            let nsError = error as NSError

            print("[AddressAutocomplete] completer failed")
            print("domain:", nsError.domain)
            print("code:", nsError.code)
            print("userInfo:", nsError.userInfo)

            onUpdate([])
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
