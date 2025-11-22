//
//  ProjectmoblieApp.swift
//  Projectmoblie
//
//  Created by Natthawat Noiauthai on 19/11/2568 BE.
//

import SwiftUI
import FirebaseCore // 1. Import Firebase

// 2. สร้าง AppDelegate เพื่อ Initialise Firebase ตอนเปิดแอป
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct ProjectmoblieApp: App {
    // 3. เชื่อม AppDelegate กับ App
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // สร้าง StateObject ของ AuthManager ไว้ใช้ทั้งแอป
    @StateObject var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            // ส่ง authManager ไปให้ View อื่นๆ ใช้
            ContentView()
                .environmentObject(authManager)
            
        }
    }
}
