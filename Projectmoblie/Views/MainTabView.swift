import SwiftUI

struct MainTabView: View {
    let user: UserProfile
    @State private var selectedTab = 0
    init(user: UserProfile) {
            self.user = user
            // 1. สร้าง Appearance Object
            let appearance = UITabBarAppearance()
            
            // 2. กำหนดสีพื้นหลังที่ต้องการ (ต้องแปลงจาก Color เป็น UIColor)
            // สมมติว่าต้องการสีเทาเข้ม (AppColors.darkBackground) เป็นพื้นหลัง
            appearance.backgroundColor = UIColor(AppColors.white)
            
            // 3. กำหนดสีให้กับ Tab Bar ทั่วทั้งแอป
            UITabBar.appearance().standardAppearance = appearance
            
            // 4. (สำหรับ iOS 15+ scrollEdge)
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
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
        .accentColor(AppColors.hotPink)
    }
}
