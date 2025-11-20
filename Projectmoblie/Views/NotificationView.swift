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
                    + Text(" \(notif.type == .like ? "ถูกใจการวิ่งของคุณ" : "แสดงความคิดเห็นในการวิ่งของคุณ")")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(notif.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // โชว์จุดเล็กๆ ท้ายรายการ ถ้าอันนี้ยังไม่ได้อ่าน (Option เสริม)
                if !notif.isRead {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
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
            
            // 🔥 เปิดหน้านี้ปุ๊บ สั่งให้ Mark as Read ทันที เพื่อเคลียร์จุดแดงที่หน้า Feed
            activityManager.markAllNotificationsAsRead(userId: userId)
        }
        .onDisappear {
            listener?.remove()
        }
        .overlay {
            if notifications.isEmpty {
                ContentUnavailableView("ยังไม่มีการแจ้งเตือน", systemImage: "bell.slash", description: Text("เมื่อมีคนถูกใจหรือคอมเมนต์ จะแสดงที่นี่"))
            }
        }
    }
}

#Preview {
    NotificationView(userId: "test")
}
