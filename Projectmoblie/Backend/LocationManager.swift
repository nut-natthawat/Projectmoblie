import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var totalDistance: Double = 0.0
    @Published var isRecording = false
    @Published var currentPace: Double = 0.0
    
    // 🔥 [NEW] เพิ่มสถานะ Paused
    @Published var isPaused = false
    
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func startRecording() {
        isRecording = true
        isPaused = false
        routeCoordinates = []
        totalDistance = 0.0
        currentPace = 0.0
        lastLocation = nil
    }
    
    // 🔥 [NEW] ฟังก์ชันหยุดชั่วคราว
    func pauseRecording() {
        isPaused = true
        currentPace = 0.0 // รีเซ็ต Pace ตอนหยุด
    }
    
    // 🔥 [NEW] ฟังก์ชันเล่นต่อ
    func resumeRecording() {
        isPaused = false
        lastLocation = nil // สำคัญ! ต้องรีเซ็ตจุดล่าสุด เพื่อไม่ให้ระยะทางกระโดดข้ามช่วงที่หยุดไป
    }
    
    func stopRecording() {
        isRecording = false
        isPaused = false
        currentPace = 0.0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        
        // 🔥 ต้องเช็คว่า กำลังบันทึก AND ไม่ได้หยุดพักอยู่
        if isRecording && !isPaused {
            if location.speed > 0 && location.horizontalAccuracy >= 0 {
                let pace = 16.6667 / location.speed
                if pace < 60 {
                    self.currentPace = pace
                } else {
                    self.currentPace = 0
                }
            } else {
                self.currentPace = 0
            }
            
            routeCoordinates.append(location.coordinate)
            
            if let lastLoc = lastLocation {
                let distance = location.distance(from: lastLoc)
                totalDistance += (distance / 1000.0)
            }
            lastLocation = location
        }
    }
}
