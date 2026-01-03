import SwiftUI

/// A prominent button for initiating image conversion.
struct ConvertButton: View {
    private let action: () -> Void

    /// Creates a convert button.
    /// - Parameter action: Action to perform when the button is tapped.
    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(String(localized: "button.convert"))
                .frame(minWidth: 0, maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
    }
}
