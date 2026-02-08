import MapKit

final class EventAnnotation: NSObject, MKAnnotation, Identifiable {
    let id: String
    let event: VanEvent
    dynamic var coordinate: CLLocationCoordinate2D

    var title: String? { event.title }
    var subtitle: String? { event.activityType.capitalized }

    init(event: VanEvent, coordinate: CLLocationCoordinate2D) {
        self.id = event.id
        self.event = event
        self.coordinate = coordinate
        super.init()
    }

    override var hash: Int { id.hashValue }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? EventAnnotation else { return false }
        return id == other.id
    }
}
