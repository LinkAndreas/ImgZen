import SwiftUI

/// A full-screen progress bar overlay with title, subtitle, and cancel option.
public struct ProgressBar: View {
    /// The state of the progress indicator.
    public enum State: Equatable {
        case indeterminate
        case percentage(value: Double)
        case amount(current: Int, total: Int)
    }

    private let title: String
    private let subtitle: String?
    private let completedSubtitle: String?
    private let state: State
    private let onCancel: () -> Void

    /// Creates a progress bar.
    /// - Parameters:
    ///   - title: Title text displayed above the progress indicator.
    ///   - subtitle: Optional subtitle text.
    ///   - completedSubtitle: Optional subtitle replacing `subtitle` once all work is done.
    ///   - state: The current progress state.
    ///   - onCancel: Action to perform when cancel is tapped.
    public init(
        title: String,
        subtitle: String? = nil,
        completedSubtitle: String? = nil,
        state: State,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.completedSubtitle = completedSubtitle
        self.state = state
        self.onCancel = onCancel
    }

    /// Whether all work is done, so the card can confirm it before it disappears.
    private var isComplete: Bool {
        switch state {
        case .indeterminate:
            return false
        case let .percentage(value):
            return value >= 1
        case let .amount(current, total):
            return total > 0 && current >= total
        }
    }

    public var body: some View {
        ZStack {
            Color.black
                .opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "photo.stack")
                    .font(.system(size: 44, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isComplete ? Color.green : Color.accentColor)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.pulse, isActive: !isComplete)
                    .frame(height: 52)
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    if let subtitle = isComplete ? (completedSubtitle ?? subtitle) : subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                switch state {
                case .indeterminate:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                case let .percentage(value):
                    VStack(spacing: 8) {
                        ProgressView(value: value, total: 1.0)
                            .animation(.smooth, value: state)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)

                        Text(String(format: String(localized: "progress.percentage", defaultValue: "%lld%%"), Int((max(0, min(1, value))) * 100)))
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                case let .amount(current, total):
                    VStack(spacing: 8) {
                        ProgressView(value: Double(current), total: Double(max(total, 1)))
                            .animation(.smooth, value: state)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)

                        Text(String(format: String(localized: "progress.amount", defaultValue: "%lld of %lld"), current, total))
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: Double(current)))
                    }
                }

                Button(action: onCancel) {
                    Text(String(localized: "button.cancel"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                // Hidden once done, keeping its space so the card doesn't change size as it closes.
                .opacity(isComplete ? 0 : 1)
                .disabled(isComplete)
                .accessibilityHidden(isComplete)
            }
            .animation(.smooth, value: state)
            .frame(maxWidth: 280)
            .padding(24)
            // An opaque material keeps the text readable over the photos; clear glass let them show through.
            .background(.thickMaterial, in: .rect(cornerRadius: 32))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
            .padding(24)
            .accessibilityElement(children: .contain)
        }
    }
}
