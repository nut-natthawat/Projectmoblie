import SwiftUI
import FirebaseFirestore

struct CommentView: View {
    let activityId: String
    @EnvironmentObject var authManager: AuthManager
    @StateObject var activityManager = ActivityManager()
    
    // 🔥 [NEW] รับค่า Owner Id เพื่อรู้ว่าจะส่ง Notification หาใคร
    // (จริงๆ ควรแก้ให้รับ Model Activity มาเลย แต่เพื่อให้แก้โค้ดน้อยที่สุด เราจะ query เอาหรือปล่อยให้ Backend จัดการ)
    // เพื่อความง่ายใน MVP เราจะสมมติว่าเราหา ownerId ได้ หรือรับมา
    // แต่ใน RunningServices เราแก้ให้รับ ownerId แล้ว ดังนั้นต้องแก้ตรงนี้ให้ส่งไป
    
    // วิธีแก้ที่ดีที่สุดคือรับ RunningActivity มาแทน activityId string
    // แต่เพื่อให้ง่ายต่อโค้ดเดิม ผมจะใช้วิธี Fetch ownerId ของ activity นี้ก่อนส่ง
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        VStack {
            if comments.isEmpty {
                Spacer()
                Text("ยังไม่มีความคิดเห็น")
                    .foregroundColor(.gray)
                Text("เป็นคนแรกที่แสดงความคิดเห็นสิ!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(comments) { comment in
                    HStack(alignment: .top) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 35, height: 35)
                            .overlay(Text(comment.username.prefix(1)).font(.caption).bold())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(comment.username)
                                    .font(.caption)
                                    .bold()
                                Text(comment.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Text(comment.text)
                                .font(.body)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            
            HStack {
                TextField("แสดงความคิดเห็น...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(AppColors.hotPink)
                        .font(.title2)
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listener = activityManager.listenToComments(activityId: activityId) { fetchedComments in
                self.comments = fetchedComments
            }
        }
        .onDisappear {
            listener?.remove()
        }
    }
    
    func sendComment() {
        guard let user = authManager.currentUser else { return }
        let text = newCommentText
        newCommentText = ""
        
        // 🔥 ต้อง Fetch activity เพื่อเอา ownerId ก่อน (วิธีแบบ hack เร็วๆ)
        // ใน Production ควรรับ activity model มาตั้งแต่ต้น
        Firestore.firestore().collection("activities").document(activityId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let ownerId = data["userId"] as? String else { return }
            
            activityManager.addComment(activityId: activityId, text: text, user: user, ownerId: ownerId) { success in
                if !success { print("Failed to send comment") }
            }
        }
    }
}
