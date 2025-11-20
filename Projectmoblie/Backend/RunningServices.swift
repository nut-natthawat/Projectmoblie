import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// MARK: - 1. DATA MODELS
struct UserProfile: Codable, Identifiable {
    var id: String
    var username: String
    var email: String
    var totalDistance: Double
    var joinDate: Date
    var bio: String?
    // เก็บรูปโปรไฟล์แบบ Text (Base64)
    var profileImageBase64: String?
}

struct RouteCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct Comment: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let text: String
    let timestamp: Date
}

struct RunningActivity: Codable, Identifiable, Hashable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let distance: Double
    let duration: TimeInterval
    let routePoints: [RouteCoordinate]
    let timestamp: Date
    var likes: Int = 0
    var avgPace: Double?
    var note: String?
    var splits: [Double] = []
    
    // 🔥 [NEW] เก็บรูปโปรไฟล์ของคนวิ่งไว้ในกิจกรรมด้วย (Snapshot)
    var userProfileImageBase64: String?
    
    static func == (lhs: RunningActivity, rhs: RunningActivity) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum NotificationType: String, Codable {
    case like
    case comment
}

struct NotificationItem: Codable, Identifiable {
    @DocumentID var id: String?
    let fromUserId: String
    let fromUsername: String
    let type: NotificationType
    let activityId: String
    let timestamp: Date
    var isRead: Bool = false
}

// MARK: - 2. MANAGERS
class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    private let db = Firestore.firestore()
    
    func register(email: String, password: String, username: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else { return }
            let newUser = UserProfile(id: uid, username: username, email: email, totalDistance: 0.0, joinDate: Date())
            do {
                try self.db.collection("users").document(uid).setData(from: newUser)
                DispatchQueue.main.async { self.currentUser = newUser }
                completion(.success(newUser))
            } catch { completion(.failure(error)) }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else { return }
            self.fetchUserProfile(uid: uid, completion: completion)
        }
    }
    
    func fetchUserProfile(uid: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            do {
                let user = try snapshot?.data(as: UserProfile.self)
                if let user = user {
                    DispatchQueue.main.async { self.currentUser = user }
                    completion(.success(user))
                }
            } catch { completion(.failure(error)) }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        DispatchQueue.main.async { self.currentUser = nil }
    }
    
    func updateProfile(username: String, bio: String, image: UIImage?, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUser?.id else { return }
        
        var data: [String: Any] = [
            "username": username,
            "bio": bio
        ]
        
        if let image = image {
            if let imageData = image.jpegData(compressionQuality: 0.1) {
                let base64String = imageData.base64EncodedString()
                data["profileImageBase64"] = base64String
            }
        }
        
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Error updating profile: \(error)")
                completion(false)
            } else {
                DispatchQueue.main.async {
                    self.currentUser?.username = username
                    self.currentUser?.bio = bio
                    if let image = image, let imageData = image.jpegData(compressionQuality: 0.1) {
                        self.currentUser?.profileImageBase64 = imageData.base64EncodedString()
                    }
                }
                completion(true)
            }
        }
    }
}

class ActivityManager: ObservableObject {
    private let db = Firestore.firestore()
    
    func saveRun(activity: RunningActivity, completion: @escaping (Bool) -> Void) {
        do {
            let _ = try db.collection("activities").addDocument(from: activity)
            let userRef = db.collection("users").document(activity.userId)
            userRef.updateData(["totalDistance": FieldValue.increment(activity.distance)])
            completion(true)
        } catch {
            print("Error saving run: \(error)")
            completion(false)
        }
    }
    
    func fetchFeed(completion: @escaping ([RunningActivity]) -> Void) {
        db.collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { completion([]); return }
                let activities = documents.compactMap { try? $0.data(as: RunningActivity.self) }
                completion(activities)
            }
    }
    
    func fetchUserActivities(userId: String, completion: @escaping ([RunningActivity]) -> Void) {
        db.collection("activities").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { completion([]); return }
            var activities = documents.compactMap { try? $0.data(as: RunningActivity.self) }
            activities.sort { $0.timestamp > $1.timestamp }
            completion(activities)
        }
    }
    
    func deleteActivity(activity: RunningActivity, completion: @escaping (Bool) -> Void) {
        guard let activityId = activity.id else { return }
        let activityRef = db.collection("activities").document(activityId)
        let userRef = db.collection("users").document(activity.userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.deleteDocument(activityRef)
            transaction.updateData(["totalDistance": FieldValue.increment(-activity.distance)], forDocument: userRef)
            return nil
        }) { (object, error) in
            completion(error == nil)
        }
    }
    
    func likeActivity(activity: RunningActivity, fromUser: UserProfile) {
        guard let activityId = activity.id, !activityId.isEmpty else { return }
        db.collection("activities").document(activityId).updateData(["likes": FieldValue.increment(Int64(1))])
        if activity.userId != fromUser.id { sendNotification(to: activity.userId, type: .like, fromUser: fromUser, activityId: activityId) }
    }
    
    func addComment(activityId: String, text: String, user: UserProfile, ownerId: String, completion: @escaping (Bool) -> Void) {
        guard !activityId.isEmpty else { return }
        let newComment = Comment(userId: user.id, username: user.username, text: text, timestamp: Date())
        try? db.collection("activities").document(activityId).collection("comments").addDocument(from: newComment)
        if ownerId != user.id { sendNotification(to: ownerId, type: .comment, fromUser: user, activityId: activityId) }
        completion(true)
    }
    
    func listenToComments(activityId: String, completion: @escaping ([Comment]) -> Void) -> ListenerRegistration? {
        return db.collection("activities").document(activityId).collection("comments").order(by: "timestamp", descending: false).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { completion([]); return }
            completion(documents.compactMap { try? $0.data(as: Comment.self) })
        }
    }
    
    private func sendNotification(to userId: String, type: NotificationType, fromUser: UserProfile, activityId: String) {
        let notification = NotificationItem(fromUserId: fromUser.id, fromUsername: fromUser.username, type: type, activityId: activityId, timestamp: Date())
        let _ = try? db.collection("users").document(userId).collection("notifications").addDocument(from: notification)
    }
    
    func listenToNotifications(userId: String, completion: @escaping ([NotificationItem]) -> Void) -> ListenerRegistration? {
        return db.collection("users").document(userId).collection("notifications").order(by: "timestamp", descending: true).limit(to: 20).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { completion([]); return }
            completion(documents.compactMap { try? $0.data(as: NotificationItem.self) })
        }
    }
    
    func listenToUnreadCount(userId: String, completion: @escaping (Int) -> Void) -> ListenerRegistration? {
        return db.collection("users").document(userId).collection("notifications").whereField("isRead", isEqualTo: false).addSnapshotListener { snapshot, error in
            completion(snapshot?.documents.count ?? 0)
        }
    }

    func markAllNotificationsAsRead(userId: String) {
        db.collection("users").document(userId).collection("notifications").whereField("isRead", isEqualTo: false).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let batch = self.db.batch()
            for doc in documents { batch.updateData(["isRead": true], forDocument: doc.reference) }
            batch.commit()
        }
    }
    
    func updateActivityNote(activity: RunningActivity, note: String) {
        guard let activityId = activity.id else { return }
        db.collection("activities").document(activityId).updateData(["note": note])
    }
}
