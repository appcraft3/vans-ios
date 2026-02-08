import SwiftUI
import UIKit

// MARK: - Protocols

protocol ActionableView: View {
    associatedtype ViewModel: ActionableViewModel
    var viewModel: ViewModel { get }
}

protocol ActionableViewModel: ObservableObject {}

// MARK: - ActionableHostingViewController

class ActionableHostingViewController<Content: ActionableView, ViewModel: ActionableViewModel>: UIHostingController<Content> {

    let viewModel: ViewModel

    init(rootView: Content, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
