import SwiftUI
import FirebaseFirestore

struct FeedView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var activityManager = ActivityManager()
    @State var activities: [RunningActivity] = []
    
    @State private var unreadCount: Int = 0
    @State private var notiListener: ListenerRegistration?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if activities.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "figure.run").font(.system(size: 50)).foregroundColor(.gray)
                            Text("ยังไม่มีกิจกรรมการวิ่ง").foregroundColor(.gray)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(activities) { activity in
                            NavigationLink(value: activity) {
                                ActivityCard(activity: activity, activityManager: activityManager, currentUser: authManager.currentUser)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Feed")
            .navigationDestination(for: RunningActivity.self) { activity in
                ActivityDetailView(activity: activity, currentUser: authManager.currentUser, activityManager: activityManager)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationView(userId: authManager.currentUser?.id ?? "")) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell").font(.system(size: 20)).foregroundColor(.primary)
                            if unreadCount > 0 {
                                Circle().fill(Color.red).frame(width: 10, height: 10).offset(x: 2, y: -2)
                            }
                        }
                    }
                }
            }
            .onAppear {
                activityManager.fetchFeed { self.activities = $0 }
                if let userId = authManager.currentUser?.id {
                    notiListener?.remove()
                    notiListener = activityManager.listenToUnreadCount(userId: userId) { self.unreadCount = $0 }
                }
            }
            .onDisappear { notiListener?.remove() }
            .refreshable { activityManager.fetchFeed { self.activities = $0 } }
        }
    }
}

struct ActivityCard: View {
    let activity: RunningActivity
    @ObservedObject var activityManager: ActivityManager
    let currentUser: UserProfile?
    
    @State private var isLiked = false
    @State private var showComments = false
    @State private var showDeleteAlert = false
    @State private var isDeleted = false
    
    var body: some View {
        if isDeleted {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // 🔥 [UPDATED] ส่วนแสดงรูปโปรไฟล์
                    if let base64 = activity.userProfileImageBase64,
                       let data = Data(base64Encoded: base64),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        // รูป Placeholder เดิม
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(Text(activity.username.prefix(1)).bold())
                    }
                    
                    VStack(alignment: .leading) {
                        Text(activity.username).font(.headline)
                        Text(activity.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    if let user = currentUser, user.id == activity.userId {
                        Button(action: { showDeleteAlert = true }) {
                            Image(systemName: "trash").foregroundColor(.red.opacity(0.7)).font(.system(size: 16))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                HStack(spacing: 20) {
                    StatValue(label: "Distance", value: String(format: "%.2f km", activity.distance))
                    StatValue(label: "Pace", value: formatPace(activity.avgPace))
                    StatValue(label: "Time", value: formatDuration(activity.duration))
                }
                
                if !activity.routePoints.isEmpty {
                    StaticMapView(routePoints: activity.routePoints)
                        .frame(height: 200).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .allowsHitTesting(false)
                } else {
                    Rectangle().fill(Color.orange.opacity(0.1)).frame(height: 150).cornerRadius(8)
                        .overlay(Image(systemName: "map.fill").foregroundColor(.orange))
                        .allowsHitTesting(false)
                }
                
                Divider()
                
                HStack {
                    Button(action: {
                        guard let user = currentUser else { return }
                        activityManager.likeActivity(activity: activity, fromUser: user)
                        isLiked.toggle()
                    }) {
                        HStack { Image(systemName: isLiked ? "heart.fill" : "heart").foregroundColor(isLiked ? .red : .gray); Text("\(activity.likes)") }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { showComments = true }) {
                        HStack { Image(systemName: "bubble.right"); Text("Comment") }.foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .sheet(isPresented: $showComments) {
                        if let activityId = activity.id {
                            NavigationStack { CommentView(activityId: activityId) }.presentationDetents([.medium, .large])
                        }
                    }
                }
            }
            .padding().background(Color.white).cornerRadius(12).shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .alert("ยืนยันการลบ", isPresented: $showDeleteAlert) {
                Button("ยกเลิก", role: .cancel) { }
                Button("ลบ", role: .destructive) { deleteThisActivity() }
            } message: { Text("คุณต้องการลบกิจกรรมนี้ใช่ไหม?") }
        }
    }
    
    func deleteThisActivity() {
        activityManager.deleteActivity(activity: activity) { success in
            if success { withAnimation { isDeleted = true } }
        }
    }
    struct StatValue: View {
        let label: String; let value: String
        var body: some View { VStack { Text(label).font(.caption).foregroundColor(.gray); Text(value).font(.headline).bold() } }
    }
    func formatDuration(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter(); f.allowedUnits = [.hour, .minute, .second]; f.unitsStyle = .positional; f.zeroFormattingBehavior = .pad
        return f.string(from: seconds) ?? "00:00"
    }
    func formatPace(_ pace: Double?) -> String {
        guard let p = pace, p > 0, !p.isInfinite else { return "--:--" }
        let m = Int(p); let s = Int((p - Double(m)) * 60); return String(format: "%d:%02d /km", m, s)
    }
}
