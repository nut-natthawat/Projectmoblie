import SwiftUI
import MapKit
import FirebaseFirestore
import Charts

struct ActivityDetailView: View {
    let activity: RunningActivity
    let currentUser: UserProfile?
    @ObservedObject var activityManager: ActivityManager
    
    @Environment(\.dismiss) var dismiss
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var listener: ListenerRegistration?
    
    @State private var showDeleteActivityAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. MAP
                if !activity.routePoints.isEmpty {
                    MapView(userLocation: nil, routeCoordinates: activity.routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                        .frame(height: 350)
                } else {
                    Rectangle().fill(AppColors.hotPink.opacity(0.1)).frame(height: 250).overlay(Text("No Map Data").foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // 2. HEADER (🔥 UPDATED)
                    HStack {
                        if let base64 = activity.userProfileImageBase64,
                           let data = Data(base64Encoded: base64),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(activity.username).font(.title2).bold()
                            Text(activity.timestamp.formatted(date: .long, time: .shortened)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    // 4. STATS
                    HStack(spacing: 20) {
                        DetailStat(label: "Distance", value: String(format: "%.2f km", activity.distance))
                        DetailStat(label: "Pace", value: formatPace(activity.avgPace))
                        DetailStat(label: "Time", value: formatDuration(activity.duration))
                    }
                    .padding(.vertical)
                    
                    // 5. SPLITS CHART
                    if !activity.splits.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Splits (Pace per KM)").font(.headline)
                            Chart {
                                ForEach(Array(activity.splits.enumerated()), id: \.offset) { index, splitSeconds in
                                    BarMark(
                                        x: .value("KM", index + 1),
                                        y: .value("Pace", splitSeconds / 60.0)
                                    )
                                    .foregroundStyle(AppColors.hotPink).cornerRadius(4)
                                }
                            }
                            .frame(height: 200).chartYAxisLabel("Minutes / KM").padding().background(Color.white).cornerRadius(10).shadow(color: Color.black.opacity(0.05), radius: 5)
                        }
                        .padding(.vertical)
                    }
                    
                    Divider()
                    
                    // 6. COMMENTS
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Comments").font(.headline)
                        
                        if comments.isEmpty {
                            Text("No comments yet.").foregroundColor(.gray).font(.subheadline)
                        } else {
                            ForEach(comments) { comment in
                                HStack(alignment: .top) {
                                    Image(systemName: "person.circle.fill").foregroundColor(.gray)
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(comment.username).bold().font(.footnote)
                                            Text(comment.timestamp.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundColor(.gray)
                                        }
                                        Text(comment.text).font(.subheadline)
                                    }
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Write a comment...", text: $newCommentText).textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: sendComment) { Image(systemName: "paperplane.fill").foregroundColor(AppColors.hotPink) }.disabled(newCommentText.isEmpty)
                        }
                        .padding(.top, 5)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Activity Detail")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                listener = activityManager.listenToComments(activityId: activity.id ?? "") { self.comments = $0 }
            }
            .onDisappear { listener?.remove() }

            // 2. Toolbar และ Alert
            .toolbar {
                if let user = currentUser, user.id == activity.userId {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive, action: {
                            showDeleteActivityAlert = true // แก้เป็นชื่อตัวแปรที่ถูกต้อง
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Confirm Delete", isPresented: $showDeleteActivityAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteAndDismiss() }
            } message: {
                Text("Do you really want to delete this activity?")
            }
        } // ⬇️ ปิด body
    
    
    func sendComment() {
        guard let user = currentUser, let activityId = activity.id else { return }
        let text = newCommentText
        newCommentText = ""
        Firestore.firestore().collection("activities").document(activityId).getDocument { snapshot, _ in
            let ownerId = snapshot?.data()?["userId"] as? String ?? ""
            activityManager.addComment(activityId: activityId, text: text, user: user, ownerId: ownerId) { _ in }
        }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter(); f.allowedUnits = [.hour, .minute, .second]; f.unitsStyle = .abbreviated
        return f.string(from: seconds) ?? "00:00"
    }
    func formatPace(_ pace: Double?) -> String {
        guard let p = pace, p > 0, !p.isInfinite else { return "--:--" }
        let m = Int(p); let s = Int((p - Double(m)) * 60); return String(format: "%d:%02d /km", m, s)
    }
    func deleteAndDismiss() {
        activityManager.deleteActivity(activity: activity) { success in
            if success {
                // ปิด ActivityDetailView เมื่อลบสำเร็จ
                dismiss()
            } else {
                print("Error: Could not delete activity.")
                // คุณอาจเพิ่ม logic สำหรับแสดงข้อผิดพลาด (Error Message) ที่นี่
            }
        }
    }
}

struct DetailStat: View {
    let label: String; let value: String
    var body: some View {
        VStack { Text(label).font(.caption).foregroundColor(.gray); Text(value).font(.title3).bold() }
        .frame(maxWidth: .infinity)
    }
}
