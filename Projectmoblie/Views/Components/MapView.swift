import SwiftUI
import MapKit

// Component แผนที่แบบ Interactive (เลื่อนได้ ซูมได้)
struct MapView: UIViewRepresentable {
    var userLocation: CLLocationCoordinate2D?
    var routeCoordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if !routeCoordinates.isEmpty {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            // ลบเส้นเก่าออกก่อนวาดใหม่
            uiView.removeOverlays(uiView.overlays)
            uiView.addOverlay(polyline)
            
            // จัดกึ่งกลางแผนที่ไปยังจุดล่าสุด
            if let lastLocation = routeCoordinates.last {
                let region = MKCoordinateRegion(center: lastLocation, latitudinalMeters: 500, longitudinalMeters: 500)
                uiView.setRegion(region, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .orange // สีเส้น
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
