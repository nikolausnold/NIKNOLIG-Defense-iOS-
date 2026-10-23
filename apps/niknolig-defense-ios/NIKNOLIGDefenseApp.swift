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
    @Environment(\.openURL) private var openURL
    @State private var website = WebsiteConnection()
    @State private var websiteAttempt = 0

    var body: some View {
        ScrollView {
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
                Divider()
                Text("Official Defense website")
                    .font(.headline)
                Text(DefenseWebsite.url.absoluteString)
                    .font(.footnote)
                    .textSelection(.enabled)
                Text("Checks the website over HTTPS, then opens your browser. Browser loading cannot be monitored by this app.")
                    .font(.footnote)
                if website.state == .checking {
                    ProgressView("Checking website…")
                }
                if case .failed(let error) = website.state {
                    Label(error.message, systemImage: "exclamationmark.triangle")
                        .accessibilityIdentifier("website-error")
                }
                Button(websiteButtonTitle) {
                    websiteAttempt += 1
                }
                .disabled(website.state == .checking || website.state == .opening)
                .accessibilityIdentifier("website-open-retry")
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .task(id: websiteAttempt) {
            guard websiteAttempt > 0, await website.prepareToOpen() else { return }
            openURL(DefenseWebsite.url) { accepted in
                website.finishedOpening(accepted: accepted)
            }
        }
    }

    private var websiteButtonTitle: String {
        if case .failed = website.state { return "Retry website" }
        return "Open Defense website"
    }
}
