import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if let user = authManager.currentUser {
            MainTabView(user: user)
        } else {
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
