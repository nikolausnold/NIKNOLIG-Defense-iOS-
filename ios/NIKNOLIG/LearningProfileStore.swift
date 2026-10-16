import Foundation
import Observation

@Observable
final class LearningProfileStore {
    enum ResponseStyle: String, CaseIterable, Identifiable {
        case concise
        case stepByStep = "step_by_step"
        case detailed

        var id: String { rawValue }

        var titleKey: String {
            switch self {
            case .concise: "response.style.concise"
            case .stepByStep: "response.style.step_by_step"
            case .detailed: "response.style.detailed"
            }
        }

        var previewKey: String {
            switch self {
            case .concise: "response.preview.concise"
            case .stepByStep: "response.preview.step_by_step"
            case .detailed: "response.preview.detailed"
            }
        }
    }

    private enum Key {
        static let learningEnabled = "learning_enabled"
        static let responseStyle = "response_style"
        static let helpfulCount = "helpful_count"
        static let unclearCount = "unclear_count"
        static let correctionCount = "correction_count"
        static let sessionSummary = "session_summary"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var learningEnabled: Bool {
        didSet { defaults.set(learningEnabled, forKey: Key.learningEnabled) }
    }

    var responseStyle: ResponseStyle {
        didSet { defaults.set(responseStyle.rawValue, forKey: Key.responseStyle) }
    }

    private(set) var helpfulCount: Int64 {
        didSet { defaults.set(helpfulCount, forKey: Key.helpfulCount) }
    }

    private(set) var unclearCount: Int64 {
        didSet { defaults.set(unclearCount, forKey: Key.unclearCount) }
    }

    private(set) var correctionCount: Int64 {
        didSet { defaults.set(correctionCount, forKey: Key.correctionCount) }
    }

    private(set) var sessionSummary: String {
        didSet {
            if sessionSummary.isEmpty {
                defaults.removeObject(forKey: Key.sessionSummary)
            } else {
                defaults.set(sessionSummary, forKey: Key.sessionSummary)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        learningEnabled = defaults.bool(forKey: Key.learningEnabled)
        responseStyle = ResponseStyle(rawValue: defaults.string(forKey: Key.responseStyle) ?? "")
            ?? .concise
        helpfulCount = defaults.object(forKey: Key.helpfulCount).map { ($0 as? NSNumber)?.int64Value ?? 0 } ?? 0
        unclearCount = defaults.object(forKey: Key.unclearCount).map { ($0 as? NSNumber)?.int64Value ?? 0 } ?? 0
        correctionCount = defaults.object(forKey: Key.correctionCount).map { ($0 as? NSNumber)?.int64Value ?? 0 } ?? 0
        sessionSummary = defaults.string(forKey: Key.sessionSummary) ?? ""
    }

    func recordHelpfulFeedback() {
        helpfulCount = nextCount(helpfulCount)
    }

    func recordUnclearFeedback() {
        unclearCount = nextCount(unclearCount)
    }

    func recordCorrectionFeedback() {
        correctionCount = nextCount(correctionCount)
    }

    @discardableResult
    func saveSessionSummary(_ text: String) -> Bool {
        let summary = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
        sessionSummary = summary
        return !summary.isEmpty
    }

    func clear() {
        learningEnabled = false
        responseStyle = .concise
        helpfulCount = 0
        unclearCount = 0
        correctionCount = 0
        sessionSummary = ""
        [
            Key.learningEnabled,
            Key.responseStyle,
            Key.helpfulCount,
            Key.unclearCount,
            Key.correctionCount,
            Key.sessionSummary
        ].forEach(defaults.removeObject(forKey:))
    }

    private func nextCount(_ count: Int64) -> Int64 {
        guard learningEnabled, count < Int64.max else { return count }
        return count + 1
    }
}
