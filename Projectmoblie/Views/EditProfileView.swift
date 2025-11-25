import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var username: String
    @State private var bio: String
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var currentImageBase64: String?
    
    @State private var isLoading = false
    
    init(currentUsername: String, currentBio: String?, currentImageBase64: String?) {
        _username = State(initialValue: currentUsername)
        _bio = State(initialValue: currentBio ?? "")
        _currentImageBase64 = State(initialValue: currentImageBase64)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let base64 = currentImageBase64,
                                      let data = Data(base64Encoded: base64),
                                      let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                            }
                        
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text("เปลี่ยนรูปโปรไฟล์")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("ข้อมูลส่วนตัว")) {
                    TextField("ชื่อผู้ใช้", text: $username)
                    TextField("แนะนำตัวสั้นๆ (Bio)", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("แก้ไขโปรไฟล์")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("บันทึก") { saveProfile() }
                        .bold()
                        .disabled(username.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("กำลังบันทึก...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
        }
    }
    
    func saveProfile() {
        isLoading = true
        authManager.updateProfile(username: username, bio: bio, image: selectedImage) { success in
            isLoading = false
            if success { dismiss() }
        }
    }
}

#Preview {
    EditProfileView(currentUsername: "TestUser", currentBio: "Love Running!", currentImageBase64: nil)
        .environmentObject(AuthManager())
}
