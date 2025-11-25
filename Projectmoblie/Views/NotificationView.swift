import SwiftUI
import FirebaseFirestore

struct NotificationView: View {
    let userId: String
    @StateObject var activityManager = ActivityManager()
    @State private var notifications: [NotificationItem] = []
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        List(notifications) { notif in
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(notif.type == .like ? Color.pink.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: notif.type == .like ? "heart.fill" : "bubble.left.fill")
                        .foregroundColor(notif.type == .like ? .pink : .blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notif.fromUsername)
                        .font(.headline)
                    + Text(" \(notif.type == .like ? "Liked your post" : "Commented on your post")")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(notif.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !notif.isRead {
                    Circle().fill(AppColors.hotPink).frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 5)
        }
        .listStyle(.plain)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listener = activityManager.listenToNotifications(userId: userId) { fetchedNotifs in
                self.notifications = fetchedNotifs
            }
            
            activityManager.markAllNotificationsAsRead(userId: userId)
        }
        .onDisappear {
            listener?.remove()
        }
        .overlay {
            if notifications.isEmpty {
                ContentUnavailableView("No notifications yet", systemImage: "bell.slash", description: Text("Show when someone is liking or commenting on your posts"))
                    .padding()
            }
        }
    }
}

#Preview {
    NotificationView(userId: "test")
}
