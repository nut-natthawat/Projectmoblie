import SwiftUI
import MapKit

struct RecordView: View {
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var authManager: AuthManager
    @StateObject var activityManager = ActivityManager()
    
    @State private var timer: Timer?
    @State private var secondsElapsed: TimeInterval = 0
    
    @State private var showSummary = false
    @State private var finishedActivity: RunningActivity?
    
    @State private var splits: [Double] = []
    @State private var lastSplitTime: TimeInterval = 0
    @State private var nextSplitDistance: Double = 1.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(userLocation: locationManager.userLocation, routeCoordinates: locationManager.routeCoordinates)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    StatItem(label: "Distance (km)", value: String(format: "%.2f", locationManager.totalDistance))
                    StatItem(label: "Pace (min/km)", value: formatPace(locationManager.currentPace))
                    StatItem(label: "Time", value: formatTime(secondsElapsed))
                }
                .padding()
                .background(Color.white.opacity(0.95))
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                HStack(spacing: 30) {
                    if !locationManager.isRecording {
                        Button(action: startRun) {
                            Text("START")
                                .font(.title2).bold()
                                .frame(width: 100, height: 100)
                                .background(AppColors.hotPink)
                                .foregroundColor(AppColors.light)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                    } else {
                        if locationManager.isPaused {
                            Button(action: resumeRun) {
                                Text("RESUME")
                                    .font(.headline).bold()
                                    .frame(width: 80, height: 80)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            
                            Button(action: stopRun) {
                                Text("STOP")
                                    .font(.headline).bold()
                                    .frame(width: 80, height: 80)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        } else {
                            Button(action: pauseRun) {
                                Text("PAUSE")
                                    .font(.headline).bold()
                                    .frame(width: 100, height: 100)
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showSummary, onDismiss: {
            resetRunData()
        }) {
            if let activity = finishedActivity {
                RunSummaryView(activity: activity) {
                    showSummary = false
                }
            }
        }
        .onChange(of: locationManager.totalDistance) { newDistance in
            if locationManager.isRecording && !locationManager.isPaused && newDistance >= nextSplitDistance {
                let currentTime = secondsElapsed
                let timeForThisKm = currentTime - lastSplitTime
                splits.append(timeForThisKm)
                lastSplitTime = currentTime
                nextSplitDistance += 1.0
            }
        }
    }
    
    struct StatItem: View {
        let label: String; let value: String
        var body: some View { VStack { Text(label).font(.caption).foregroundColor(.gray); Text(value).font(.system(size: 24, weight: .bold, design: .rounded)) }.frame(maxWidth: .infinity) }
    }
    
    func startRun() {
        locationManager.startRecording()
        secondsElapsed = 0
        splits = []
        lastSplitTime = 0
        nextSplitDistance = 1.0
        startTimer()
    }
    
    func pauseRun() {
        locationManager.pauseRecording()
        timer?.invalidate()
        timer = nil
    }
    
    func resumeRun() {
        locationManager.resumeRecording()
        startTimer()
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            secondsElapsed += 1
        }
    }
    
    func stopRun() {
        locationManager.stopRecording()
        timer?.invalidate()
        timer = nil
        
        guard let user = authManager.currentUser else { return }
        
        var finalAvgPace: Double = 0.0
        if locationManager.totalDistance > 0 {
            let minutes = secondsElapsed / 60.0
            finalAvgPace = minutes / locationManager.totalDistance
        }
        
        let routePoints = locationManager.routeCoordinates.map { RouteCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        
        let newRun = RunningActivity(
            userId: user.id,
            username: user.username,
            distance: locationManager.totalDistance,
            duration: secondsElapsed,
            routePoints: routePoints,
            timestamp: Date(),
            avgPace: finalAvgPace,
            splits: splits,
            // 🔥 [NEW] แนบรูปโปรไฟล์ปัจจุบันของ User ไปด้วย
            userProfileImageBase64: user.profileImageBase64
        )
        
        activityManager.saveRun(activity: newRun) { success in
            if success {
                self.finishedActivity = newRun
                self.showSummary = true
            }
        }
    }
    
    func resetRunData() {
        secondsElapsed = 0
        locationManager.routeCoordinates = []
        locationManager.totalDistance = 0
        splits = []
        lastSplitTime = 0
        nextSplitDistance = 1.0
        finishedActivity = nil
    }
    
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60; let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    func formatPace(_ pace: Double) -> String {
        if pace == 0 || pace.isInfinite || pace.isNaN { return "--:--" }
        let m = Int(pace); let s = Int((pace - Double(m)) * 60)
        return String(format: "%d:%02d", m, s)
    }
}

// RunSummaryView (เหมือนเดิม)
struct RunSummaryView: View {
    let activity: RunningActivity
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Running Result")
                .font(.title)
                .bold()
                .padding(.top)
            
            if !activity.routePoints.isEmpty {
                StaticMapView(routePoints: activity.routePoints)
                    .frame(height: 300)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .cornerRadius(15)
                    .overlay(Text("No Route Data"))
                    .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                SummaryStat(label: "Distance", value: String(format: "%.2f km", activity.distance))
                SummaryStat(label: "Avg Pace", value: formatPace(activity.avgPace))
                SummaryStat(label: "Time", value: formatDuration(activity.duration))
            }
            .padding()
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Success")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.hotPink)
                    .foregroundColor(AppColors.light)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    struct SummaryStat: View {
        let label: String; let value: String
        var body: some View { VStack { Text(label).font(.caption).foregroundColor(.gray); Text(value).font(.title2).bold().foregroundColor(.primary) }.frame(maxWidth: .infinity) }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter(); f.allowedUnits = [.hour, .minute, .second]; f.unitsStyle = .abbreviated
        return f.string(from: seconds) ?? "00:00"
    }
    
    func formatPace(_ pace: Double?) -> String {
        guard let p = pace, p > 0, !p.isInfinite else { return "--:--" }
        let m = Int(p); let s = Int((p - Double(m)) * 60); return String(format: "%d:%02d /km", m, s)
    }
}
