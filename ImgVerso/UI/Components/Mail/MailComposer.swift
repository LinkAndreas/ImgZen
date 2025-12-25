import MessageUI
import SwiftUI

/// A SwiftUI wrapper for MFMailComposeViewController for composing and sending emails.
struct MailComposer: UIViewControllerRepresentable {
    private let recipients: [String]
    private let ccRecipients: [String]
    private let bccRecipients: [String]
    private let subject: String
    private let body: String

    /// Creates a mail composer.
    /// - Parameters:
    ///   - recipients: Primary email recipients.
    ///   - ccRecipients: CC recipients. Defaults to empty.
    ///   - bccRecipients: BCC recipients. Defaults to empty.
    ///   - subject: Email subject line. Defaults to empty.
    ///   - body: Email body text.
    init(
        recipients: [String],
        ccRecipients: [String] = [],
        bccRecipients: [String] = [],
        subject: String = "",
        body: String
    ) {
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.bccRecipients = bccRecipients
        self.subject = subject
        self.body = body
    }

    func makeCoordinator() -> MailCoordinator {
        MailCoordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients(recipients)
            controller.setCcRecipients(ccRecipients)
            controller.setBccRecipients(bccRecipients)
            controller.setSubject(subject)
            controller.setMessageBody(body, isHTML: false)
            controller.mailComposeDelegate = context.coordinator
            return controller
        } else {
            return UIViewController()
        }
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}

/// Coordinator that handles MFMailComposeViewController delegate callbacks.
final class MailCoordinator: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    ) {
        controller.dismiss(animated: true)
    }
}
