import Foundation
import Combine

final class HomeViewModel: ActionableViewModel {
    private weak var coordinator: HomeCoordinating?

    init(coordinator: HomeCoordinating?) {
        self.coordinator = coordinator
    }
}
