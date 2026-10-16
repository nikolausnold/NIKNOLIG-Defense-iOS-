import SwiftUI

@main
struct NIKNOLIGApp: App {
    @State private var learningProfile = LearningProfileStore()

    var body: some Scene {
        WindowGroup {
            ContentView(learningProfile: learningProfile)
                .preferredColorScheme(.dark)
        }
    }
}
