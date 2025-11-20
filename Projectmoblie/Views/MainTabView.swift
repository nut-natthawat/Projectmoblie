import SwiftUI

struct MainTabView: View {
    let user: UserProfile
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Feed
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Tab 2: Record
            RecordView()
                .tabItem {
                    Image(systemName: "record.circle")
                    Text("Record")
                }
                .tag(1)
            
            // Tab 3: Profile
            ProfileView(user: user)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.orange)
    }
}
