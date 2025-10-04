import SwiftUI
import MapKit

struct LocationSearchField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var coordinates: CLLocationCoordinate2D?
    @State private var isSearching = false
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var completer = MKLocalSearchCompleter()
    @State private var completerDelegate: LocationSearchCompleterDelegate?
    @FocusState private var isFocused: Bool
    @State private var recentPlaces: [RecentPlace] = RecentPlacesStore.shared.load()
    @State private var favoritePlaces: [RecentPlace] = RecentPlacesStore.shared.loadFavorites()
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        updateSearchResults(for: newValue)
                    }
                    .onSubmit {
                        // Hide keyboard on submit
                        isFocused = false
                    }
                
                if !text.isEmpty {
                    Button {
                        text = ""
                        coordinates = nil
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // Current Location Button
                Button {
                    useCurrentLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
            )
            
        }
        .overlay(alignment: .top) {
            // Search Results / Favorites / Recents Dropdown
            if isFocused {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if text.isEmpty {
                            if !favoritePlaces.isEmpty {
                                sectionHeader("Favorites")
                                ForEach(favoritePlaces, id: \.self) { place in
                                    recentRow(place)
                                }
                            }
                            if !recentPlaces.isEmpty {
                                sectionHeader("Recent")
                                ForEach(recentPlaces, id: \.self) { place in
                                    recentRow(place)
                                }
                            }
                        }
                        if !searchResults.isEmpty {
                            sectionHeader("Results")
                            ForEach(searchResults, id: \.self) { result in
                                Button { selectLocation(result) } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .accessibilityLabel("Result: \(result.title), \(result.subtitle)")
                                Divider().padding(.leading)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                        .shadow(radius: 10)
                )
                .offset(y: 60) // Position below the input field
                .zIndex(9999) // Very high z-index to ensure it's on top
            }
        }
        .onAppear {
            let delegate = LocationSearchCompleterDelegate { results in
                // Filter results to only show cities/regions
                let filteredResults = results.filter { result in
                    // Check if it's likely a city by looking at the subtitle
                    let subtitle = result.subtitle.lowercased()
                    let title = result.title.lowercased()
                    
                    // Skip if it contains street indicators
                    let streetIndicators = ["street", "st", "avenue", "ave", "road", "rd", "drive", "dr", "lane", "ln", "boulevard", "blvd", "way", "court", "ct", "place", "pl"]
                    let hasStreetIndicator = streetIndicators.contains { indicator in
                        title.contains(" \(indicator)") || title.contains(" \(indicator).") ||
                        subtitle.contains(" \(indicator)") || subtitle.contains(" \(indicator).")
                    }
                    
                    // Skip if it has numbers (likely addresses)
                    let hasNumbers = title.range(of: "\\d", options: .regularExpression) != nil
                    
                    return !hasStreetIndicator && !hasNumbers
                }
                
                self.searchResults = filteredResults
            }
            completerDelegate = delegate
            completer.delegate = delegate
            // Use address query type
            completer.resultTypes = .address
            completer.pointOfInterestFilter = .excludingAll
        }
    }
    
    private func updateSearchResults(for query: String) {
        if query.isEmpty {
            searchResults = []
        } else {
            completer.queryFragment = query
        }
    }
    
    private func selectLocation(_ result: MKLocalSearchCompletion) {
        // For cities, we typically want just the title
        text = result.title
        
        // Convert to coordinates
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let item = response?.mapItems.first {
                coordinates = item.placemark.coordinate
                
                // Update text with city name if available
                if let city = item.placemark.locality {
                    text = city
                    if let state = item.placemark.administrativeArea {
                        text += ", \(state)"
                    }
                }
                // Save to recents
                let place = RecentPlace(title: text, subtitle: item.placemark.title ?? "", latitude: coordinates?.latitude ?? item.placemark.coordinate.latitude, longitude: coordinates?.longitude ?? item.placemark.coordinate.longitude, favorite: false)
                RecentPlacesStore.shared.add(place)
                recentPlaces = RecentPlacesStore.shared.load()
                favoritePlaces = RecentPlacesStore.shared.loadFavorites()
            }
        }
        
        searchResults = []
        isFocused = false
    }
    
    private func useCurrentLocation() {
        text = "Current Location"
        
        // Use SimpleLocationManager to avoid threading issues
        SimpleLocationManager.shared.requestLocationIfNeeded()
        
        if let location = SimpleLocationManager.shared.currentLocation {
            coordinates = location.coordinate
        } else {
            // For simulator, use San Francisco as default
            coordinates = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
        
        searchResults = []
        isFocused = false
    }

    // MARK: - Recents/Favorites helpers
    @ViewBuilder private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption).foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
            Spacer()
        }
    }
    
    @ViewBuilder private func recentRow(_ place: RecentPlace) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.title).font(.subheadline).foregroundColor(.primary)
                if !place.subtitle.isEmpty { Text(place.subtitle).font(.caption).foregroundColor(.secondary) }
            }
            Spacer()
            Button {
                RecentPlacesStore.shared.toggleFavorite(place)
                recentPlaces = RecentPlacesStore.shared.load()
                favoritePlaces = RecentPlacesStore.shared.loadFavorites()
            } label: {
                Image(systemName: place.favorite ? "star.fill" : "star")
                    .foregroundColor(place.favorite ? .yellow : .secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            text = place.title
            coordinates = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            searchResults = []
            isFocused = false
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityLabel("\(place.favorite ? "Favorite" : "Recent") place: \(place.title)")
        Divider().padding(.leading)
    }
}

// MARK: - Search Completer Delegate

class LocationSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onResults: ([MKLocalSearchCompletion]) -> Void
    
    init(onResults: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onResults = onResults
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle error silently
    }
}
// MARK: - Recents Store
struct RecentPlace: Codable, Hashable {
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    var favorite: Bool
}

final class RecentPlacesStore {
    static let shared = RecentPlacesStore()
    private let recentsKey = "route_recents_v1"
    private let maxItems = 12
    private init() {}
    
    func load() -> [RecentPlace] {
        guard let data = UserDefaults.standard.data(forKey: recentsKey),
              let items = try? JSONDecoder().decode([RecentPlace].self, from: data) else { return [] }
        return items
    }
    
    func loadFavorites() -> [RecentPlace] {
        load().filter { $0.favorite }
    }
    
    func add(_ place: RecentPlace) {
        var items = load()
        // Deduplicate by coords/title
        items.removeAll { $0.title == place.title && abs($0.latitude - place.latitude) < 0.0001 && abs($0.longitude - place.longitude) < 0.0001 }
        items.insert(place, at: 0)
        if items.count > maxItems { items = Array(items.prefix(maxItems)) }
        save(items)
    }
    
    func toggleFavorite(_ place: RecentPlace) {
        var items = load()
        if let idx = items.firstIndex(of: place) {
            items[idx].favorite.toggle()
        } else {
            var p = place
            p.favorite = true
            items.insert(p, at: 0)
        }
        save(items)
    }
    
    private func save(_ items: [RecentPlace]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: recentsKey)
        }
    }
}
