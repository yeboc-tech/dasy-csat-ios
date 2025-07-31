import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set }
    
    func start()
}

class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        print("DEBUG: AppCoordinator start called")
        showHomeView()
    }
    
    func showHomeView() {
        print("DEBUG: AppCoordinator showHomeView called")
        let homeVC = HomeViewController()
        homeVC.coordinator = self
        navigationController.setViewControllers([homeVC], animated: false)
        print("DEBUG: AppCoordinator set HomeViewController as root")
    }
    
    func showDocumentView() {
        let documentVC = DocumentViewController()
        documentVC.coordinator = self
        navigationController.pushViewController(documentVC, animated: true)
    }
} 