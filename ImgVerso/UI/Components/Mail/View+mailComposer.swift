import SwiftUI

/// Extension providing mail composer sheet presentation.
extension View {
    /// Presents a mail composer sheet.
    /// - Parameters:
    ///   - isPresenting: Binding that controls sheet presentation.
    ///   - recipients: Primary email recipients.
    ///   - ccRecipients: CC recipients. Defaults to empty.
    ///   - bccRecipients: BCC recipients. Defaults to empty.
    ///   - subject: Email subject line. Defaults to empty.
    ///   - body: Email body text.
    /// - Returns: A view with the mail composer modifier applied.
    func mailComposer(
        isPresenting: Binding<Bool>,
        recipients: [String],
        ccRecipients: [String] = [],
        bccRecipients: [String] = [],
        subject: String = "",
        body: String
    ) -> some View {
        self.sheet(isPresented: isPresenting) {
             MailComposer(
                recipients: recipients,
                ccRecipients: ccRecipients,
                bccRecipients: bccRecipients,
                subject: subject,
                body: body
             )
        }
    }
}
