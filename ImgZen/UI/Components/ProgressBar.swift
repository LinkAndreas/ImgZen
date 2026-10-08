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

    /// How far the work is, from 0 to 1; nothing yet while preparing.
    private var fraction: Double {
        switch state {
        case .indeterminate:
            return 0
        case let .percentage(value):
            return max(0, min(1, value))
        case let .amount(current, total):
            return total > 0 ? Double(current) / Double(total) : 0
        }
    }

    /// The count or percentage under the bar; empty while preparing, keeping its line so the card doesn't resize.
    private var detail: String {
        switch state {
        case .indeterminate:
            return " "
        case let .percentage(value):
            return String(format: String(localized: "progress.percentage", defaultValue: "%lld%%"), Int(max(0, min(1, value)) * 100))
        case let .amount(current, total):
            return String(format: String(localized: "progress.amount", defaultValue: "%lld of %lld"), current, total)
        }
    }

    private var currentSubtitle: String? {
        isComplete ? (completedSubtitle ?? subtitle) : subtitle
    }

    public var body: some View {
        ZStack {
            Color.black
                .opacity(0.3)
                .ignoresSafeArea()

            // One layout for every stage: only values change in place, so nothing shifts or overlaps
            // as the card goes from preparing to converting to done.
            VStack(spacing: 20) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "photo.stack")
                    .font(.system(size: 52, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isComplete ? Color.green : Color.accentColor)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.pulse, isActive: !isComplete)
                    .frame(height: 60)
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    if let currentSubtitle {
                        Text(currentSubtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                        .tint(isComplete ? .green : .accentColor)
                        .scaleEffect(x: 1, y: 1.5)

                    Text(detail)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(value: fraction))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(currentSubtitle ?? title)
                .accessibilityValue(detail)

                Button(action: onCancel) {
                    Text(String(localized: "button.cancel"))
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                // Hidden once done, keeping its space so the card doesn't change size as it closes.
                .opacity(isComplete ? 0 : 1)
                .disabled(isComplete)
                .accessibilityHidden(isComplete)
            }
            .animation(.smooth(duration: 0.35), value: state)
            .frame(maxWidth: 320)
            .padding(28)
            // An opaque material keeps the text readable over the photos; clear glass let them show through.
            .background(.thickMaterial, in: .rect(cornerRadius: 32))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
            .padding(24)
            .accessibilityElement(children: .contain)
        }
    }
}
