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
    private let state: State
    private let onCancel: () -> Void

    /// Creates a progress bar.
    /// - Parameters:
    ///   - title: Title text displayed above the progress indicator.
    ///   - subtitle: Optional subtitle text.
    ///   - state: The current progress state.
    ///   - onCancel: Action to perform when cancel is tapped.
    public init(
        title: String,
        subtitle: String? = nil,
        state: State,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
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
                .opacity(0.2)
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

                    if let subtitle {
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
                // Not glass, since the card already is; glass shouldn't sit on glass.
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isComplete)
            }
            .animation(.smooth, value: state)
            .frame(maxWidth: 280)
            .padding(24)
            .glassEffect(.regular, in: .rect(cornerRadius: 32))
            .padding(24)
            .accessibilityElement(children: .contain)
        }
    }
}
