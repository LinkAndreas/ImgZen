import SwiftUI

/// The app's name and installed version at the end of the settings, e.g. "ImgZen 1.8.1 (1)",
/// to tell when writing feedback.
struct AppVersionFooter: View {
    private var text: String {
        String(
            format: String(localized: "settings.appNameAndVersion"),
            Bundle.main.shortVersion,
            Bundle.main.buildNumber
        )
    }

    var body: some View {
        Text(text)
            .monospacedDigit()
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .textSelection(.enabled)
    }
}

#if DEBUG
#Preview {
    Form {
        Section {
            Text(verbatim: "Row")
        } footer: {
            AppVersionFooter()
        }
    }
}
#endif
