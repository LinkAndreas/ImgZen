import MessageUI
import SwiftUI

/// A SwiftUI wrapper for MFMailComposeViewController for composing and sending emails.
struct MailComposer: UIViewControllerRepresentable {
    private let recipients: [String]
    private let ccRecipients: [String]
    private let bccRecipients: [String]
    private let subject: String
    private let body: String
    private let onFinish: () -> Void

    /// Creates a mail composer.
    /// - Parameters:
    ///   - recipients: Primary email recipients.
    ///   - ccRecipients: CC recipients. Defaults to empty.
    ///   - bccRecipients: BCC recipients. Defaults to empty.
    ///   - subject: Email subject line. Defaults to empty.
    ///   - body: Email body text.
    ///   - onFinish: Called when the user sends, saves or cancels the email, to close the composer.
    init(
        recipients: [String],
        ccRecipients: [String] = [],
        bccRecipients: [String] = [],
        subject: String = "",
        body: String,
        onFinish: @escaping () -> Void
    ) {
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.bccRecipients = bccRecipients
        self.subject = subject
        self.body = body
        self.onFinish = onFinish
    }

    func makeCoordinator() -> MailCoordinator {
        MailCoordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let deviceInfo = DeviceInfo.compute()
            let deviceInfoPresenter = DeviceInfoPresenter(deviceInfo: deviceInfo)
            let controller = MFMailComposeViewController()
            controller.setToRecipients(recipients)
            controller.setCcRecipients(ccRecipients)
            controller.setBccRecipients(bccRecipients)
            controller.setSubject(subject)
            controller.setMessageBody([
                body,
                deviceInfoPresenter.formatted
            ].joined(separator: "\n\n"), isHTML: false)
            controller.mailComposeDelegate = context.coordinator
            return controller
        } else {
            let fallback = UIViewController()
            fallback.view.backgroundColor = .systemBackground

            let label = UILabel()
            label.text = String(localized: "mail.notAvailable")
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true

            label.translatesAutoresizingMaskIntoConstraints = false
            fallback.view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: fallback.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: fallback.view.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: fallback.view.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(lessThanOrEqualTo: fallback.view.trailingAnchor, constant: -20)
            ])

            return fallback
        }
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}

/// Coordinator that handles MFMailComposeViewController delegate callbacks.
final class MailCoordinator: NSObject, MFMailComposeViewControllerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    ) {
        // Closing through SwiftUI rather than UIKit's dismiss keeps the sheet's state in sync,
        // so feedback can be sent again later.
        onFinish()
    }
}

