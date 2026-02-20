import SwiftUI
import SwiftData

@main
struct NibblewayStudioApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: ExecutionRecord.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, container.mainContext)
        }
    }
}
