// FocusFields.swift

import Foundation

// ประกาศ enum Field เพียงครั้งเดียวที่นี่
enum Field: Hashable {
    case username, email, password
}

// ถ้าคุณมี LoginView ที่มีแค่ email และ password
// คุณสามารถสร้าง enum แยกได้ แต่ในกรณีนี้ใช้ enum เดียวกันเพื่อความง่าย
