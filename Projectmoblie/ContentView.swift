import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        // เช็คสถานะ Login
        if let user = authManager.currentUser {
            // --- State: LOGIN แล้ว -> ไปหน้า Tab Bar หลัก ---
            MainTabView(user: user)
        } else {
            // --- State: ยังไม่ LOGIN -> ไปหน้า Login ---
            NavigationStack {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
