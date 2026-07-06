import FirebaseCore
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()

        window = UIWindow(frame: UIScreen.main.bounds)
        let isUITesting = CommandLine.arguments.contains("--uitesting")
        let root = isUITesting ? TestHostViewController() : MainViewController()
        let nav = UINavigationController(rootViewController: root)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        return true
    }
}
