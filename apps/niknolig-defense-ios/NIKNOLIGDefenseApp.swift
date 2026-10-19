import SharedAPI
import SharedSecurity
import SwiftUI

@main
struct NIKNOLIGDefenseApp: App {
    var body: some Scene {
        WindowGroup {
            FoundationHomeView()
        }
    }
}

private struct FoundationHomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NIKNOLIG Defense")
                .font(.largeTitle.bold())
            Text("Independent iOS foundation")
                .font(.title2)
            Label(
                "SecurityChain P0: \(SecurityReadiness.securityChainP0.rawValue)",
                systemImage: "lock.shield"
            )
            .accessibilityIdentifier("security-p0-status")
            Text("No sign-in, device linking, backend data, or sensor access is enabled.")
            Text("Contract paths: \(HealthEndpoint.allCases.map(\.path).joined(separator: ", "))")
                .font(.footnote)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
