import SwiftUI

@main
struct FirstStateLensApp: App {
    @State private var model: AppModel

    init() {
        let store: FileProgressStore
        let storeError: String?
        do {
            store = try .appStore()
            storeError = nil
        }
        catch {
            let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("FirstStateLens-unavailable.json")
            store = FileProgressStore(fileURL: fallback)
            storeError = error.localizedDescription
        }
        _model = State(initialValue: AppModel(store: store, initialStoreError: storeError))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .tint(LensTheme.teal)
                .preferredColorScheme(nil)
        }
    }
}
