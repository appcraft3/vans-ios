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

        // Ensure the hosting controller fills available space (iOS 16+)
        if #available(iOS 16.0, *) {
            sizingOptions = [.preferredContentSize]
        }

        // Make sure view fills the screen
        view.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.frame = view.superview?.bounds ?? view.frame
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
