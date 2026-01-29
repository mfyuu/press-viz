import SwiftUI

@main
struct PressVizApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // メニューバーアプリなのでWindowGroupは使用しない
        Settings {
            EmptyView()
        }
    }
}
