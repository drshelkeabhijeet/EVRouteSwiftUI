import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RouteView()
                .tabItem {
                    Label("Route", systemImage: "map.fill")
                }
                .tag(0)
            
            NearbyView()
                .tabItem {
                    Label("Nearby", systemImage: "bolt.circle.fill")
                }
                .tag(1)
            
            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

// Placeholder Views
struct RouteView: View {
    var body: some View {
        RoutePlanningView()
    }
}

struct SavedView: View {
    var body: some View {
        RouteHistoryView()
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vehicleManager = VehicleManager.shared
    @State private var showingImagePicker = false
    @State private var userImage: UIImage?
    @State private var isLoadingPhoto = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button {
                            showingImagePicker = true
                        } label: {
                            if isLoadingPhoto {
                                ProgressView()
                                    .frame(width: 60, height: 60)
                            } else if let userImage = userImage {
                                Image(uiImage: userImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text(authManager.currentUser?.displayNameOrName ?? "User")
                                .font(.headline)
                            Text(authManager.currentUser?.email ?? "user@example.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let phone = authManager.currentUser?.phone, !phone.isEmpty {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Vehicle") {
                    NavigationLink {
                        VehicleSelectionView()
                    } label: {
                        HStack {
                            Label("My Vehicles", systemImage: "car.fill")
                            Spacer()
                            if let vehicle = VehicleManager.shared.selectedVehicle {
                                Text(vehicle.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Settings") {
                    NavigationLink {
                        Text("Preferences")
                    } label: {
                        Label("Preferences", systemImage: "gear")
                    }
                    
                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                
                Section {
                    Button {
                        Task {
                            try? await authManager.signOut()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $userImage)
            }
            .onAppear {
                loadUserPhoto()
            }
            .onChange(of: userImage) { _, newImage in
                if let newImage = newImage {
                    uploadUserPhoto(newImage)
                }
            }
        }
    }
    
    private func loadUserPhoto() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoadingPhoto = true
        Task {
            do {
                let photo = try await PhotoStorageService.shared.downloadUserPhoto(userId: userId)
                await MainActor.run {
                    self.userImage = photo
                    self.isLoadingPhoto = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPhoto = false
                }
            }
        }
    }
    
    private func uploadUserPhoto(_ image: UIImage) {
        guard let userId = authManager.currentUser?.id else { 
            print("No user ID available for photo upload")
            return 
        }
        
        print("ProfileView: Starting photo upload for user: \(userId)")
        isLoadingPhoto = true
        
        Task {
            do {
                let url = try await PhotoStorageService.shared.uploadUserPhoto(image, userId: userId)
                print("ProfileView: Photo upload successful, URL: \(url)")
                await MainActor.run {
                    self.isLoadingPhoto = false
                }
            } catch {
                print("ProfileView: Photo upload failed: \(error)")
                await MainActor.run {
                    self.isLoadingPhoto = false
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
