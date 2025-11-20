import SwiftUI
import MapKit

struct StaticMapView: UIViewRepresentable {
    let routePoints: [RouteCoordinate]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isScrollEnabled = false // ห้ามเลื่อน
        mapView.isZoomEnabled = false   // ห้ามซูม
        mapView.isUserInteractionEnabled = false // ห้ามแตะ
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // แปลงข้อมูลจาก Server เป็นพิกัด GPS
        let coordinates = routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        guard !coordinates.isEmpty else { return }
        
        // 1. ลบเส้นเก่าออกก่อน
        uiView.removeOverlays(uiView.overlays)
        
        // 2. สร้างเส้น Polyline
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)
        
        // 3. คำนวณกรอบให้พอดีกับเส้นทาง (Auto Zoom)
        // เผื่อขอบ (Padding) ไว้นิดหน่อยรูปจะได้ไม่ชิดขอบเกินไป
        let mapRect = polyline.boundingMapRect
        uiView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: StaticMapView
        
        init(_ parent: StaticMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .orange // สีส้ม Strava
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
