import SwiftUI

@main
struct NTFSDeskApp: App {
    @StateObject private var store = VolumeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1200, minHeight: 780)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
