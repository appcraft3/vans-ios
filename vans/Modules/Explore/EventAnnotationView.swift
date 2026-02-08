import MapKit
import UIKit

final class EventAnnotationView: MKAnnotationView {
    private let iconSize: CGFloat = 38

    // accentGreen #2E7D5A
    private let pinColor = UIColor(red: 0x2E / 255.0, green: 0x7D / 255.0, blue: 0x5A / 255.0, alpha: 1.0)

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: -iconSize / 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with annotation: EventAnnotation) {
        self.annotation = annotation

        let container = UIView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
        container.backgroundColor = pinColor
        container.layer.cornerRadius = iconSize / 2
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor

        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.5

        let symbolSize: CGFloat = 16
        let config = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .semibold)
        let iconImage = UIImage(systemName: annotation.event.activityIcon, withConfiguration: config)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let iconView = UIImageView(image: iconImage)
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(
            x: (iconSize - symbolSize) / 2,
            y: (iconSize - symbolSize) / 2,
            width: symbolSize,
            height: symbolSize
        )
        container.addSubview(iconView)

        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        let pinImage = renderer.image { ctx in
            container.layer.render(in: ctx.cgContext)
        }

        self.image = pinImage
        self.frame.size = CGSize(width: iconSize, height: iconSize)
    }
}
