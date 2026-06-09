#if os(iOS)
import UIKit

enum RevoxaIOSNavigationAppearance {
    static func configure() {
        let accent = UIColor(red: 242 / 255, green: 138 / 255, blue: 46 / 255, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: accent]
        appearance.titleTextAttributes = [.foregroundColor: accent]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = accent
    }
}
#endif
