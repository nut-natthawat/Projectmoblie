import SwiftUI

struct MainTabView: View {
    let user: UserProfile
    @State private var selectedTab = 0
    init(user: UserProfile) {
            self.user = user
            let appearance = UITabBarAppearance()
            
            appearance.backgroundColor = UIColor(AppColors.white)
            
            UITabBar.appearance().standardAppearance = appearance
            
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            RecordView()
                .tabItem {
                    Image(systemName: "record.circle")
                    Text("Record")
                }
                .tag(1)
            
            ProfileView(user: user)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(AppColors.hotPink)
    }
}
