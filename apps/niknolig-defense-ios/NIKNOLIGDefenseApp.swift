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
        ZStack {
            DefenseTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    brandHeader

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sicherheitsübersicht")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(DefenseTheme.text)
                        Text("Der aktuelle Status deiner Defense-App")
                            .font(.body)
                            .foregroundStyle(DefenseTheme.steelBlue)
                    }

                    securityStatus
                    websiteAccess

                    Text("NIKNOLIG Defense · iOS")
                        .font(.footnote)
                        .foregroundStyle(DefenseTheme.steelBlue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .tint(DefenseTheme.steelBlue)
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title2.weight(.semibold))
                .foregroundStyle(DefenseTheme.steelBlue)
                .frame(width: 48, height: 48)
                .background(DefenseTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("NIKNOLIG")
                    .font(.headline.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(DefenseTheme.text)
                Text("DEFENSE")
                    .font(.caption.weight(.semibold))
                    .tracking(2.4)
                    .foregroundStyle(DefenseTheme.steelBlue)
            }

            Spacer()

            Text("iOS")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DefenseTheme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DefenseTheme.panel, in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }

    private var securityStatus: some View {
        DefensePanel(title: "Sicherheitsstatus", systemImage: "lock.shield") {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text(SecurityReadiness.securityChainP0 == .blocked ? "GESPERRT" : SecurityReadiness.securityChainP0.rawValue)
                        .font(.headline.weight(.bold))
                        .tracking(0.8)
                } icon: {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.title3)
                }
                .foregroundStyle(DefenseTheme.signalRed)
                .accessibilityIdentifier("security-p0-status")

                Text("Die Schutzkette ist nicht freigegeben. Anmeldung, Geräteverknüpfung und Sensorzugriffe sind derzeit nicht aktiviert.")
                    .font(.body)
                    .foregroundStyle(DefenseTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var websiteAccess: some View {
        DefensePanel(title: "Offizielle Defense-Website", systemImage: "globe.americas.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Text(DefenseWebsite.url.host() ?? DefenseWebsite.url.absoluteString)
                    .font(.headline)
                    .foregroundStyle(DefenseTheme.text)
                    .textSelection(.enabled)

                Text("Die sichere Verbindung wird geprüft, bevor die Website im Browser geöffnet wird. Das Laden im Browser kann diese App nicht überwachen.")
                    .font(.body)
                    .foregroundStyle(DefenseTheme.steelBlue)
                    .fixedSize(horizontal: false, vertical: true)

                if website.state == .checking {
                    ProgressView("Sichere Verbindung wird geprüft …")
                        .font(.body.weight(.medium))
                        .tint(DefenseTheme.steelBlue)
                        .foregroundStyle(DefenseTheme.text)
                        .accessibilityIdentifier("website-checking")
                }

                if case .failed(let error) = website.state {
                    Label(error.message, systemImage: "exclamationmark.triangle.fill")
                        .font(.body)
                        .foregroundStyle(DefenseTheme.signalRed)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("website-error")
                }

                Button {
                    websiteAttempt += 1
                } label: {
                    Label(websiteButtonTitle, systemImage: "arrow.up.right.square")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(DefenseActionButtonStyle())
                .disabled(website.state == .checking || website.state == .opening)
                .accessibilityIdentifier("website-open-retry")
                .accessibilityHint("Prüft die Website über HTTPS und öffnet sie anschließend im Browser.")
            }
        }
        .task(id: websiteAttempt) {
            guard websiteAttempt > 0, await website.prepareToOpen() else { return }
            openURL(DefenseWebsite.url) { accepted in
                website.finishedOpening(accepted: accepted)
            }
        }
    }

    private var websiteButtonTitle: String {
        if case .failed = website.state { return "Erneut versuchen" }
        if website.state == .opening { return "Website wird geöffnet …" }
        return "Website öffnen"
    }
}

private struct DefensePanel<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(DefenseTheme.text)
                .labelStyle(DefensePanelLabelStyle())

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DefenseTheme.panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(DefenseTheme.panelBorder, lineWidth: 1)
        }
    }
}

private struct DefensePanelLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .font(.headline)
                .foregroundStyle(DefenseTheme.steelBlue)
                .frame(width: 40, height: 40)
                .background(DefenseTheme.background, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            configuration.title
        }
    }
}

private struct DefenseActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DefenseTheme.background)
            .background(
                DefenseTheme.steelBlue.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private enum DefenseTheme {
    static let background = Color(red: 16 / 255, green: 24 / 255, blue: 32 / 255)
    static let panel = Color(red: 25 / 255, green: 36 / 255, blue: 47 / 255)
    static let steelBlue = Color(red: 141 / 255, green: 168 / 255, blue: 196 / 255)
    static let signalRed = Color(red: 229 / 255, green: 72 / 255, blue: 77 / 255)
    static let text = Color(red: 232 / 255, green: 237 / 255, blue: 242 / 255)
    static let panelBorder = steelBlue.opacity(0.22)
}
