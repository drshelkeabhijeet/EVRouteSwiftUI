import SwiftUI

struct RouteAmenityChip: View {
    let amenity: Amenity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: amenity.icon)
                    .font(.caption)
                
                Text(amenity.label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Amenity Model

struct Amenity: Identifiable {
    let id: String
    let label: String
    let icon: String
    
    static let all = [
        Amenity(id: "restaurant", label: "Restaurant", icon: "fork.knife"),
        Amenity(id: "shopping", label: "Shopping", icon: "cart"),
        Amenity(id: "restroom", label: "Restroom", icon: "drop"),
        Amenity(id: "lodging", label: "Hotel", icon: "bed.double"),
        Amenity(id: "cafe", label: "Cafe", icon: "cup.and.saucer"),
        Amenity(id: "supermarket", label: "Supermarket", icon: "basket")
    ]
}