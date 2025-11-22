import SwiftUI

extension Color {
    // ฟังก์ชันสำหรับสร้าง Color จาก Hex String
    init(hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgbValue: UInt64 = 0
        
        // อ่านค่า Hex
        scanner.scanHexInt64(&rgbValue)

        // แปลงค่า RGB เป็น Double (0.0 ถึง 1.0)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
