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
    
    func pauseRecording() {
        isPaused = true
        currentPace = 0.0
    }
    
    func resumeRecording() {
        isPaused = false
        lastLocation = nil
    }
    
    func stopRecording() {
        isRecording = false
        isPaused = false
        currentPace = 0.0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        
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
