import Combine
import UIKit
import SwiftUI

protocol TabHostingDelegate: AnyObject {
    func ensureCoordinatorStarted(at index: Int)
}

final class TabbarCoordinator: NSObject, Coordinator {
    var navigationController: UINavigationController {
        window.rootViewController as? UINavigationController ?? UINavigationController()
    }
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private var startedCoordinators: Set<Int> = []
    private var matchCancellable: AnyCancellable?

    var rootViewController: UIViewController {
        window.rootViewController ?? { fatalError("Window should always contain a root view controller when asked.") }()
    }

    private var tabBarController: TabViewController?
    private var tabCoordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window
        super.init()
    }

    func start() {
        guard !(window.rootViewController is UITabBarController) else { return }

        tabCoordinators = [
            ExploreCoordinator(),
            EventsCoordinator(),
            HomeCoordinator(),
            ProfileCoordinator()
        ]

        tabBarController = TabViewController()
        tabBarController!.delegate = self
        tabBarController!.tabHostingDelegate = self

        startCoordinatorIfNeeded(at: 0)

        tabBarController!.viewControllers = tabCoordinators.map(\.navigationController)

        tabCoordinators
            .map(\.navigationController)
            .forEach { $0.delegate = self }

        window.rootViewController = tabBarController

        DispatchQueue.main.async { [weak self] in
            self?.tabBarController?.switchToTab(0)
        }

        // Start listening for matches
        MatchManager.shared.startListening()
        setupMatchPopup()
    }

    private func setupMatchPopup() {
        matchCancellable = MatchManager.shared.$currentMatch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] match in
                guard let self, let match else { return }
                self.showMatchPopup(match)
            }
    }

    private func showMatchPopup(_ match: MatchInfo) {
        // Dismiss any existing alert / sheet first, then present the popup
        let presenter = topMostViewController(from: tabBarController)

        // If an alert or sheet is showing, dismiss it first
        if presenter != tabBarController, presenter?.presentingViewController != nil {
            presenter?.dismiss(animated: false) { [weak self] in
                self?.presentMatchPopup(match)
            }
        } else {
            presentMatchPopup(match)
        }
    }

    private func presentMatchPopup(_ match: MatchInfo) {
        let popupView = MatchPopupView(
            match: match,
            onSendMessage: { [weak self] in
                MatchManager.shared.dismissMatch()
                self?.navigateToMatchChat(match)
            },
            onDismiss: { [weak self] in
                MatchManager.shared.dismissMatch()
                self?.tabBarController?.dismiss(animated: true)
            }
        )

        let hostingController = UIHostingController(rootView: popupView)
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve

        // Present on the topmost VC to avoid being dismissed by sibling presentations
        let top = topMostViewController(from: tabBarController) ?? tabBarController
        top?.present(hostingController, animated: true)
    }

    private func topMostViewController(from vc: UIViewController?) -> UIViewController? {
        if let presented = vc?.presentedViewController {
            return topMostViewController(from: presented)
        }
        return vc
    }

    private func navigateToMatchChat(_ match: MatchInfo) {
        // Dismiss all presented view controllers (popup + any alerts underneath)
        tabBarController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            // Switch to Messages tab (index 2 = Home/Messages)
            self.tabBarController?.switchToTab(2)
            self.startCoordinatorIfNeeded(at: 2)

            // Push to chat
            if let homeCoordinator = self.tabCoordinators[2] as? HomeCoordinator {
                let otherUser = ChatUser(
                    odId: match.otherUserId,
                    userId: match.otherUserId,
                    profile: UserProfile(
                        firstName: match.otherUserName,
                        photoUrl: match.otherUserPhotoUrl ?? "",
                        age: 0,
                        gender: .male,
                        vanLifeStatus: .planning,
                        region: "",
                        activities: [],
                        bio: nil
                    ),
                    isPremium: false
                )
                homeCoordinator.showChat(
                    chatId: match.connectionId,
                    otherUser: otherUser,
                    sourceEventName: match.eventName,
                    waitingForHer: false
                )
            }
        }
    }

    func goToTab<T>(coordinatorType: T.Type, popToRoot: Bool) {
        guard let index = tabCoordinators.firstIndex(where: { $0 is T }) else { return }
        startCoordinatorIfNeeded(at: index)
        let coordinator = tabCoordinators[index]
        (window.rootViewController as? TabViewController)?.selectedIndex = index
        if popToRoot {
            coordinator.navigationController.popToRootViewController(animated: false)
        }
    }

    private func startCoordinatorIfNeeded(at index: Int) {
        guard index >= 0, index < tabCoordinators.count else { return }
        let coordinator = tabCoordinators[index]
        if !startedCoordinators.contains(index) {
            coordinator.start()
            startedCoordinators.insert(index)
        } else {
            if coordinator.navigationController.viewControllers.isEmpty {
                coordinator.start()
            }
        }
    }
}

extension TabbarCoordinator: TabHostingDelegate {
    func ensureCoordinatorStarted(at index: Int) {
        startCoordinatorIfNeeded(at: index)
    }
}

extension TabbarCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else { return }
        startCoordinatorIfNeeded(at: selectedIndex)
    }
}

extension TabbarCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let shouldHide = viewController.hidesBottomBarWhenPushed
        (window.rootViewController as? TabViewController)?.setCustomTabBarHidden(shouldHide, animated: true)
    }
}

// MARK: - TabViewController

class TabViewController: UITabBarController {
    weak var tabHostingDelegate: TabHostingDelegate?

    private var glassHostVC: UIHostingController<GlassTabBarWrapper>!
    private let selectedIndexSubject = CurrentValueSubject<Int, Never>(0)
    private var cancellables = Set<AnyCancellable>()

    private var glassBottomConstraint: NSLayoutConstraint!
    private let glassHeight: CGFloat = 120

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.isHidden = true
        view.backgroundColor = .black

        glassHostVC = UIHostingController(
            rootView: GlassTabBarWrapper(
                selectedIndexPublisher: selectedIndexSubject.eraseToAnyPublisher(),
                onSelect: { [weak self] newIndex in
                    self?.switchToTab(newIndex)
                }
            )
        )
        glassHostVC.view.backgroundColor = .clear

        addChild(glassHostVC)
        view.addSubview(glassHostVC.view)
        glassHostVC.didMove(toParent: self)

        glassHostVC.view.translatesAutoresizingMaskIntoConstraints = false
        glassBottomConstraint = glassHostVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            glassHostVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassHostVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassBottomConstraint,
            glassHostVC.view.heightAnchor.constraint(equalToConstant: glassHeight)
        ])

        selectedIndexSubject.send(super.selectedIndex)
        forceHideSystemTabBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        forceHideSystemTabBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        forceHideSystemTabBar()
    }

    func switchToTab(_ index: Int) {
        guard let vcs = viewControllers,
              index >= 0, index < vcs.count else { return }

        tabHostingDelegate?.ensureCoordinatorStarted(at: index)
        super.selectedIndex = index
        selectedIndexSubject.send(index)

        if let nav = vcs[index] as? UINavigationController {
            let shouldHide = nav.topViewController?.hidesBottomBarWhenPushed ?? false
            setCustomTabBarHidden(shouldHide, animated: true)
        }
    }

    override var selectedIndex: Int {
        get { super.selectedIndex }
        set { switchToTab(newValue) }
    }

    func setCustomTabBarHidden(_ hidden: Bool, animated: Bool) {
        forceHideSystemTabBar()
        glassBottomConstraint.constant = hidden ? glassHeight : 0

        let animations = {
            self.view.layoutIfNeeded()
            self.glassHostVC.view.alpha = hidden ? 0.0 : 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: animations)
        } else {
            animations()
        }
    }

    private func forceHideSystemTabBar() {
        tabBar.isUserInteractionEnabled = false
        tabBar.alpha = 0.0
        tabBar.isHidden = true

        var f = tabBar.frame
        f.origin.y = view.bounds.maxY + 1000
        f.size.height = 0.1
        tabBar.frame = f
    }
}
