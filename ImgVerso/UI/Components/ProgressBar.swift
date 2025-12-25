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

    public var body: some View {
        ZStack {
            Color.black
                .opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(.label))
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                    }
                }
                
                switch state {
                case .indeterminate:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.regular)
                        .scaleEffect(1.4)
                case let .percentage(value):
                    VStack(spacing: 12) {
                        ProgressView(value: value, total: 1.0)
                            .animation(.smooth, value: state)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 150)
                            .tint(.accentColor)
                        
                        Text(String(format: String(localized: "progress.percentage", defaultValue: "%lld%%"), Int((max(0, min(1, value))) * 100)))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                case let .amount(current, total):
                    VStack(spacing: 12) {
                        ProgressView(value: Double(current), total: Double(total))
                            .animation(.smooth, value: state)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 150)
                            .tint(.accentColor)
                        
                        Text(String(format: String(localized: "progress.amount", defaultValue: "%lld of %lld"), current, total))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }

                Button(String(localized: "button.cancel"), action: onCancel)
                    .buttonStyle(.plain)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(24)
        }
    }
}