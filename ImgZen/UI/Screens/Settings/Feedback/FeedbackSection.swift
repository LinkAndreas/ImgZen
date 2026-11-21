import SwiftUI

/// Rating, writing to the developer and sharing the app, together and always within reach.
struct FeedbackSection: View {
    let onSendFeedback: () -> Void

    var body: some View {
        Section {
            ExternalLinkRow(
                title: String(localized: "settings.feedback.rate"),
                systemImage: "star",
                destination: AppStoreLinks.writeReview,
                accessibilityHint: String(localized: "settings.feedback.rateHint")
            )
            SendFeedbackRow(action: onSendFeedback)
            ShareAppRow()
        } header: {
            Text(String(localized: "settings.feedback.header"))
        } footer: {
            Text(String(localized: "settings.feedback.footer"))
        }
    }
}

#if DEBUG
#Preview {
    Form {
        FeedbackSection(onSendFeedback: {})
    }
}
#endif
