import UIKit
import SwiftUI

typealias EventsViewController = ActionableHostingViewController<EventsListView, EventsListViewModel>

enum EventsModuleBuilder {
    @MainActor
    static func build(coordinator: EventsCoordinating) -> EventsViewController {
        let viewModel = EventsListViewModel(coordinator: coordinator)
        let view = EventsListView(viewModel: viewModel)
        return EventsViewController(rootView: view, viewModel: viewModel)
    }
}
