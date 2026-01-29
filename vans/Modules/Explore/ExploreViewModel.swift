import Foundation
import Combine

final class ExploreViewModel: ActionableViewModel {
    private weak var coordinator: ExploreCoordinating?

    init(coordinator: ExploreCoordinating?) {
        self.coordinator = coordinator
    }
}
