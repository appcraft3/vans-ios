import MapKit
import UIKit

final class EventAnnotationView: MKAnnotationView {
    private let iconSize: CGFloat = 44

    // Sand-gold border for visibility on dark map
    private let pinColor = UIColor(red: 0x2E / 255.0, green: 0x7D / 255.0, blue: 0x5A / 255.0, alpha: 1.0)
    private let borderColor = UIColor(red: 0xE8 / 255.0, green: 0xB8 / 255.0, blue: 0x6D / 255.0, alpha: 1.0)

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

        // Larger render size to include shadow
        let shadowPadding: CGFloat = 8
        let totalSize = iconSize + shadowPadding * 2

        let container = UIView(frame: CGRect(x: shadowPadding, y: shadowPadding, width: iconSize, height: iconSize))
        container.backgroundColor = pinColor
        container.layer.cornerRadius = iconSize / 2
        container.layer.borderWidth = 2.5
        container.layer.borderColor = borderColor.cgColor

        // Strong shadow for visibility
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 3)
        container.layer.shadowRadius = 6
        container.layer.shadowOpacity = 0.7

        let symbolSize: CGFloat = 18
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

        let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: totalSize, height: totalSize))
        wrapper.addSubview(container)

        let renderer = UIGraphicsImageRenderer(size: wrapper.bounds.size)
        let pinImage = renderer.image { ctx in
            wrapper.layer.render(in: ctx.cgContext)
        }

        self.image = pinImage
        self.frame.size = CGSize(width: totalSize, height: totalSize)
        self.centerOffset = CGPoint(x: 0, y: -totalSize / 2)
    }
}
