import CoreLocation

struct PolylineDecoder {
    static func decode(_ polyline: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = polyline.startIndex
        var latitude = 0
        var longitude = 0
        
        while index < polyline.endIndex {
            var shift = 0
            var result = 0
            var byte: Int
            
            repeat {
                let char = polyline[index]
                index = polyline.index(after: index)
                byte = Int(char.asciiValue! - 63)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            
            let deltaLatitude = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            latitude += deltaLatitude
            
            shift = 0
            result = 0
            
            repeat {
                let char = polyline[index]
                index = polyline.index(after: index)
                byte = Int(char.asciiValue! - 63)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20
            
            let deltaLongitude = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            longitude += deltaLongitude
            
            let coordinate = CLLocationCoordinate2D(
                latitude: Double(latitude) / 1e5,
                longitude: Double(longitude) / 1e5
            )
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
}