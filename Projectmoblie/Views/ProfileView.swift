import SwiftUI

struct ProfileView: View {
    let user: UserProfile
    @EnvironmentObject var authManager: AuthManager
    @StateObject var activityManager = ActivityManager()
    @State var myActivities: [RunningActivity] = []
    
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // --- ส่วน Header Profile ---
                    VStack(spacing: 15) {
                        ZStack(alignment: .bottomTrailing) {
                            // 🔥 แสดงรูปโปรไฟล์ (จาก Base64)
                            if let base64 = user.profileImageBase64,
                               let data = Data(base64Encoded: base64),
                               let uiImage = UIImage(data: data) {
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } else {
                                // Placeholder
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 5)
                            }
                        }
                        
                        VStack(spacing: 5) {
                            Text(user.username)
                                .font(.title)
                                .bold()
                            
                            if let bio = user.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            Text("Member since \(user.joinDate.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                        }
                        
                        Button(action: { showEditProfile = true }) {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // --- ส่วน Stats ---
                    HStack(spacing: 15) {
                        StatBox(title: "Total Distance", value: String(format: "%.1f", user.totalDistance), unit: "km")
                        StatBox(title: "Total Runs", value: "\(myActivities.count)", unit: "runs")
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.vertical)
                    
                    HStack {
                        Text("Recent Activities").font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if myActivities.isEmpty {
                        Text("ยังไม่มีประวัติการวิ่ง").foregroundColor(.gray).padding(.top, 20)
                    } else {
                        LazyVStack(spacing: 15) {
                            ForEach(myActivities) { activity in
                                ActivityCard(activity: activity, activityManager: activityManager, currentUser: authManager.currentUser)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log Out") { authManager.signOut() }.foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                // ส่งค่าปัจจุบันเข้าไป (รวมถึง Base64 รูป)
                EditProfileView(currentUsername: user.username, currentBio: user.bio, currentImageBase64: user.profileImageBase64)
            }
            .onAppear {
                activityManager.fetchUserActivities(userId: user.id) { activities in
                    self.myActivities = activities
                }
            }
        }
    }
}

// View ย่อยสำหรับกล่องสถิติ
struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title2).bold().foregroundColor(.orange)
                Text(unit).font(.caption).bold().foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(10).shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
