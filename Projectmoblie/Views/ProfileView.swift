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
                VStack(spacing: 25) {
                    HStack(alignment: .top, spacing: 10) {
                        ZStack(alignment: .bottomTrailing) {
                            if let base64 = user.profileImageBase64,
                               let data = Data(base64Encoded: base64),
                               let uiImage = UIImage(data: data) {
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 5)
                            }
                        }
                        VStack(alignment: .leading, spacing: -5) {
                            Text(user.username)
                                .font(.title2)
                                .bold()
                            
                            if let bio = user.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.dark)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Text("Member since \(user.joinDate.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        Button(action: { showEditProfile = true }) {
                            Text("Edit")
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppColors.hotPink)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(color: AppColors.hotPink.opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    HStack(spacing: 15) {
                        StatBox(title: "Total Distance", value: String(format: "%.1f", user.totalDistance), unit: "km")
                        StatBox(title: "Total Runs", value: "\(myActivities.count)", unit: "runs")
                    }
                    .padding(.horizontal)
                    
                    
                    Divider()
                    
                    HStack {
                        Text("Recent Activities")
                            .font(.title3)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if myActivities.isEmpty {
                        Text("No activities yet").foregroundColor(.gray).padding(.top, 20)
                    } else {
                        LazyVStack(spacing: 15) {
                            ForEach(myActivities) { activity in
                                NavigationLink(value: activity) {
                                                ActivityCard(activity: activity, activityManager: activityManager, currentUser: authManager.currentUser)
                                            }
                                            .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationDestination(for: RunningActivity.self) { activity in
                        ActivityDetailView(activity: activity, currentUser: authManager.currentUser, activityManager: activityManager)
                    }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log Out") { authManager.signOut() }.foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showEditProfile) {
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

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(AppColors.dark)
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(value).font(.largeTitle).bold().foregroundColor(AppColors.hotPink)
                Text(unit).font(.headline).bold().foregroundColor(AppColors.hotPink)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4) 
        
    }
}
