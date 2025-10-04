import SwiftUI
import MapKit

struct RouteMapView: UIViewRepresentable {
    let routePolyline: String
    let selectedStations: [RouteChargingStation]
    let allStations: [RouteChargingStation]
    let onStationTap: (RouteChargingStation) -> Void
    let onToggleSelection: (RouteChargingStation) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        
        // Store mapView in coordinator for updates
        context.coordinator.mapView = mapView
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Compute a lightweight signature to avoid reloading identical state
        let polyHash = routePolyline.hashValue
        let selectedIDs = Set(selectedStations.map { $0.id })
        let allIDs = Set(allStations.map { $0.id })

        if context.coordinator.lastPolylineHash == polyHash,
           context.coordinator.lastSelectedIDs == selectedIDs,
           context.coordinator.lastAllIDs == allIDs,
           !uiView.overlays.isEmpty {
            // Nothing changed; skip heavy updates
            return
        }

        context.coordinator.lastPolylineHash = polyHash
        context.coordinator.lastSelectedIDs = selectedIDs
        context.coordinator.lastAllIDs = allIDs

        // Clear existing overlays and annotations
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations.filter { !($0 is MKUserLocation) })

        // Decode and add route
        let coordinates = PolylineDecoder.decode(routePolyline)
        guard !coordinates.isEmpty else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)

        // Calculate bounding rect focused strictly on the route polyline
        var mapRect = polyline.boundingMapRect

        // Add selected stations
        print("RouteMapView: Adding \(selectedStations.count) selected stations to map")
        for (index, station) in selectedStations.enumerated() {
            let annotation = ChargingStationAnnotation(station: station, isSelected: true)
            uiView.addAnnotation(annotation)
            // Keep visible region focused on the route only (do not expand to stations)
            print("Added selected station \(index + 1): \(station.stationName) at \(station.location.lat), \(station.location.lng)")
        }

        // Add other stations
        if !allStations.isEmpty {
            print("RouteMapView: Adding non-selected stations from \(allStations.count) total stations")
            for station in allStations where !selectedIDs.contains(station.id) {
                let annotation = ChargingStationAnnotation(station: station, isSelected: false)
                uiView.addAnnotation(annotation)
                // Keep visible region focused on the route only (do not expand to stations)
                print("Added station: \(station.stationName) at \(station.location.lat), \(station.location.lng)")
            }
        }

        // Expand tiny rects to avoid zero-area fits (e.g., short polylines)
        if mapRect.size.width < 10 || mapRect.size.height < 10 {
            let expand: Double = 2000
            mapRect = mapRect.insetBy(dx: -expand, dy: -expand)
        }

        // Only set visible rect when map has laid out
        if uiView.bounds.width > 0 && uiView.bounds.height > 0 {
            let edgePadding = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
            uiView.setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: false)
        } else {
            DispatchQueue.main.async {
                if uiView.bounds.width > 0 && uiView.bounds.height > 0 {
                    let edgePadding = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
                    uiView.setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: false)
                }
            }
        }

        print("Total annotations on map: \(uiView.annotations.count - 1)") // -1 for user location
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        weak var mapView: MKMapView?
        // Cache to avoid redundant heavy updates
        var lastPolylineHash: Int?
        var lastSelectedIDs: Set<String> = []
        var lastAllIDs: Set<String> = []
        
        init(_ parent: RouteMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            if let stationAnnotation = annotation as? ChargingStationAnnotation {
                // Determine max speed for scaling across all stations
                let all = parent.allStations + parent.selectedStations
                let maxSpeed = all.map { $0.chargingSpeedKw }.max() ?? stationAnnotation.station.chargingSpeedKw
                let reuseId = stationAnnotation.isSelected ? "StationPin_Selected" : "StationPin_Normal"
                var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
                if pinView == nil {
                    pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                    pinView?.canShowCallout = true
                    // Left callout: Select/Unselect button
                    let leftButton = UIButton(type: .system)
                    let isSelectedInParent = parent.selectedStations.contains { $0.id == stationAnnotation.station.id }
                    leftButton.setTitle(isSelectedInParent ? "Unselect" : "Select", for: .normal)
                    leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                    leftButton.setTitleColor(isSelectedInParent ? .systemOrange : .systemBlue, for: .normal)
                    leftButton.sizeToFit()
                    pinView?.leftCalloutAccessoryView = leftButton
                    // Right callout: Details button
                    let button = UIButton(type: .system)
                    button.setTitle("Details", for: .normal)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                    button.setTitleColor(.systemBlue, for: .normal)
                    button.sizeToFit()
                    pinView?.rightCalloutAccessoryView = button
                }
                // Generate a static image sized by speed
                if let mkView = pinView {
                    mkView.annotation = annotation
                    mkView.image = makePinImage(for: stationAnnotation.station, maxSpeed: maxSpeed, selected: stationAnnotation.isSelected)
                    mkView.centerOffset = CGPoint(x: 0, y: -10)
                    mkView.displayPriority = .required
                    mkView.clusteringIdentifier = nil
                }
                return pinView
            }
            
            return nil
        }

        // Draw a circular pin image whose size is proportional to speed
        private func makePinImage(for station: RouteChargingStation, maxSpeed: Double, selected: Bool) -> UIImage {
            let maxS = max(maxSpeed, 1)
            // Linear scaling with reduced overall size (~50%)
            let ratio = max(min(station.chargingSpeedKw / maxS, 1), 0)
            let minDiameter: CGFloat = 6
            let maxDiameter: CGFloat = 16
            let diameter = Double(minDiameter + CGFloat(ratio) * (maxDiameter - minDiameter))
            let size = CGSize(width: diameter, height: diameter)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                let rect = CGRect(origin: .zero, size: size)
                // Circle
                (selected ? UIColor.systemOrange : UIColor.systemBlue).setFill()
                UIBezierPath(ovalIn: rect).fill()
                // Bolt glyph
                let bolt = "⚡️" as NSString
                let font = UIFont.systemFont(ofSize: CGFloat(diameter * 0.38), weight: .bold)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.white
                ]
                let textSize = bolt.size(withAttributes: attrs)
                let textRect = CGRect(
                    x: (rect.width - textSize.width) / 2,
                    y: (rect.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                bolt.draw(in: textRect, withAttributes: attrs)
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? ChargingStationAnnotation else { return }
            if control === view.rightCalloutAccessoryView {
                parent.onStationTap(annotation.station)
            } else if control === view.leftCalloutAccessoryView {
                parent.onToggleSelection(annotation.station)
            }
        }
        
        func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            // Ensure annotations are visible
            for view in views {
                if let annotation = view.annotation as? ChargingStationAnnotation {
                    view.isHidden = false
                    view.alpha = 1.0
                    view.isEnabled = true
                    
                    // Bring selected stations to front
                    if annotation.isSelected {
                        view.superview?.bringSubviewToFront(view)
                    }
                }
            }
        }
    }
}

// MARK: - Charging Station Annotation

class ChargingStationAnnotation: NSObject, MKAnnotation {
    let station: RouteChargingStation
    let isSelected: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: station.location.lat, longitude: station.location.lng)
    }
    
    var title: String? {
        station.stationName
    }
    
    var subtitle: String? {
        if isSelected {
            return "\(Int(station.chargingSpeedKw)) kW • \(station.chargingTimeMinutes) min charge"
        } else {
            return "\(Int(station.chargingSpeedKw)) kW • \(String(format: "%.1f", station.detourKm)) km detour"
        }
    }
    
    init(station: RouteChargingStation, isSelected: Bool) {
        self.station = station
        self.isSelected = isSelected
        super.init()
    }
}

// MARK: - Custom Annotation View with Scalable Size
private class BubbleAnnotationView: MKAnnotationView {
    private let bolt = UILabel()
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) { super.init(annotation: annotation, reuseIdentifier: reuseIdentifier); setup() }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }
    private func setup() {
        layer.masksToBounds = true
        bolt.text = "⚡️"
        bolt.textAlignment = .center
        addSubview(bolt)
        centerOffset = CGPoint(x: 0, y: -10)
    }
    func configure(with station: RouteChargingStation, isSelected: Bool, maxSpeed: Double) {
        let maxS = max(maxSpeed, 1)
        let ratio = max(min(station.chargingSpeedKw / maxS, 1), 0)
        let scaled = CGFloat(sqrt(ratio))
        let diameter: CGFloat = 20 + scaled * 20
        frame = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))
        layer.cornerRadius = diameter / 2
        backgroundColor = isSelected ? UIColor.systemOrange : UIColor.systemBlue
        bolt.frame = bounds
        bolt.font = UIFont.systemFont(ofSize: diameter * 0.45, weight: .bold)
        bolt.textColor = .white
        displayPriority = isSelected ? .required : .defaultHigh
    }
}
