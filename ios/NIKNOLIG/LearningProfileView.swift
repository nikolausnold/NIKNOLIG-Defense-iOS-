import SwiftUI

struct LearningProfileView: View {
    @Bindable var learningProfile: LearningProfileStore
    @State private var summaryDraft = ""
    @State private var summaryStatus: LocalizedStringKey?
    @State private var showingClearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("learning.title")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("learning.description")
                    .foregroundStyle(AppColors.secondaryText)

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading("session.heading")
                        Text("session.description")
                            .font(.subheadline)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $summaryDraft)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(8)
                            if summaryDraft.isEmpty {
                                Text("session.hint")
                                    .foregroundStyle(AppColors.secondaryText)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(AppColors.background, in: RoundedRectangle(cornerRadius: 10))
                        .onChange(of: summaryDraft) { _, value in
                            if value.count > 500 {
                                summaryDraft = String(value.prefix(500))
                            }
                        }
                        Text("\(summaryDraft.count)/500")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        if let summaryStatus {
                            Text(summaryStatus)
                                .font(.footnote)
                                .foregroundStyle(AppColors.secondaryText)
                                .accessibilityLiveRegion(.polite)
                        }
                        Button("session.save") {
                            let saved = learningProfile.saveSessionSummary(summaryDraft)
                            summaryDraft = learningProfile.sessionSummary
                            summaryStatus = saved ? "session.saved" : "session.empty"
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.gold)
                        .foregroundStyle(.black)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading("principle.heading")
                        Text("principle.description")
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading("privacy.heading")
                        Text("privacy.description")
                            .font(.subheadline)
                        Toggle("learning.opt_in", isOn: $learningProfile.learningEnabled)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading("response.heading")
                        Picker("response.heading", selection: $learningProfile.responseStyle) {
                            ForEach(LearningProfileStore.ResponseStyle.allCases) { style in
                                Text(LocalizedStringKey(style.titleKey)).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text(LocalizedStringKey(learningProfile.responseStyle.previewKey))
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading("feedback.heading")
                        Text("feedback.description")
                            .font(.subheadline)
                        Text(
                            String(
                                format: String(localized: "feedback.summary"),
                                locale: Locale.current,
                                learningProfile.helpfulCount,
                                learningProfile.unclearCount,
                                learningProfile.correctionCount
                            )
                        )
                        .font(.footnote)
                        .foregroundStyle(AppColors.secondaryText)
                        FeedbackButton(title: "feedback.helpful") {
                            learningProfile.recordHelpfulFeedback()
                        }
                        .disabled(!learningProfile.learningEnabled)
                        FeedbackButton(title: "feedback.unclear") {
                            learningProfile.recordUnclearFeedback()
                        }
                        .disabled(!learningProfile.learningEnabled)
                        FeedbackButton(title: "feedback.correction") {
                            learningProfile.recordCorrectionFeedback()
                        }
                        .disabled(!learningProfile.learningEnabled)
                    }
                }

                Button("learning.clear") {
                    showingClearConfirmation = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("learning.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            summaryDraft = learningProfile.sessionSummary
        }
        .confirmationDialog(
            "learning.clear.title",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("learning.clear.action", role: .destructive) {
                learningProfile.clear()
                summaryDraft = ""
                summaryStatus = "session.cleared"
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("learning.clear.message")
        }
    }
}

private struct FeedbackButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .tint(AppColors.gold)
            .frame(maxWidth: .infinity)
    }
}
