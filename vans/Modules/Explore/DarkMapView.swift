import SwiftUI
import MapKit

struct DarkMapView: UIViewRepresentable {
    let annotations: [EventAnnotation]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedAnnotation: EventAnnotation?
    var onAnnotationTap: ((EventAnnotation) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Dark appearance
        mapView.overrideUserInterfaceStyle = .dark

        // Clean map
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        // Register annotation view
        mapView.register(
            EventAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
        )

        mapView.setRegion(region, animated: false)
        context.coordinator.lastRegion = region
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Sync region if binding changed programmatically (e.g. recenter)
        let coord = context.coordinator
        if !coord.regionsEqual(region, coord.lastRegion) {
            mapView.setRegion(region, animated: true)
            coord.lastRegion = region
        }

        // Diff annotations to avoid flicker
        let existing = Set(mapView.annotations.compactMap { $0 as? EventAnnotation })
        let incoming = Set(annotations)

        let toRemove = existing.subtracting(incoming)
        let toAdd = incoming.subtracting(existing)

        if !toRemove.isEmpty {
            mapView.removeAnnotations(Array(toRemove))
        }
        if !toAdd.isEmpty {
            mapView.addAnnotations(Array(toAdd))
        }
    }

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(parent: self)
    }

    // MARK: - Coordinator

    final class MapCoordinator: NSObject, MKMapViewDelegate {
        var parent: DarkMapView
        var lastRegion: MKCoordinateRegion?

        init(parent: DarkMapView) {
            self.parent = parent
        }

        func regionsEqual(_ a: MKCoordinateRegion, _ b: MKCoordinateRegion?) -> Bool {
            guard let b = b else { return false }
            return abs(a.center.latitude - b.center.latitude) < 0.0001
                && abs(a.center.longitude - b.center.longitude) < 0.0001
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let eventAnnotation = annotation as? EventAnnotation else { return nil }

            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
                for: annotation
            )

            if let pinView = view as? EventAnnotationView {
                pinView.configure(with: eventAnnotation)
            }

            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let eventAnnotation = view.annotation as? EventAnnotation else { return }
            mapView.deselectAnnotation(eventAnnotation, animated: false)
            parent.onAnnotationTap?(eventAnnotation)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Track where the map ended up so updateUIView won't fight it
            lastRegion = mapView.region
            // Sync back to binding asynchronously to avoid publish-during-view-update warning
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}
