import SwiftUI

private enum AppColors {
    static let background = Color(red: 16 / 255, green: 16 / 255, blue: 16 / 255)
    static let surface = Color(red: 36 / 255, green: 36 / 255, blue: 36 / 255)
    static let gold = Color(red: 228 / 255, green: 182 / 255, blue: 78 / 255)
    static let green = Color(red: 200 / 255, green: 241 / 255, blue: 105 / 255)
    static let secondaryText = Color(red: 197 / 255, green: 197 / 255, blue: 197 / 255)
}

struct ContentView: View {
    let learningProfile: LearningProfileStore

    private var supportURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "n_nold@hotmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: String(localized: "support.email.subject")),
            URLQueryItem(name: "body", value: String(localized: "support.email.body"))
        ]
        return components.url
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            Text("brand.name")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(AppColors.green)
                        } icon: {
                            Image(systemName: "bolt.shield.fill")
                                .font(.title2)
                                .foregroundStyle(AppColors.gold)
                        }
                        .accessibilityAddTraits(.isHeader)

                        Text("assistant.name")
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text("assistant.description")
                            .font(.body)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeading("status.heading")
                            Text("status.preview")
                                .font(.title3.bold())
                            Text("status.devices")
                            NavigationLink {
                                LearningProfileView(learningProfile: learningProfile)
                            } label: {
                                Label("learning.button", systemImage: "slider.horizontal.3")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.gold)
                            .foregroundStyle(.black)
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeading("support.heading")
                            Text("support.description")
                            Text("support.payment_notice")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                            if let supportURL {
                                Link(destination: supportURL) {
                                    Label("support.button", systemImage: "envelope")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(AppColors.gold)
                            }
                        }
                    }

                    Text("demo.notice")
                        .font(.footnote)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(AppColors.gold)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SectionHeading: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(1)
            .foregroundStyle(AppColors.gold)
            .accessibilityAddTraits(.isHeader)
    }
}
