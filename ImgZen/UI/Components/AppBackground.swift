import SwiftUI

/// The app's background: the grouped background with a soft wash in the app icon's colors at the top.
///
/// The launch screen is the plain grouped background, so the app starts on the same background
/// and then fades the wash in.
struct AppBackground: View {
    @Environment(AppIconStore.self) private var iconStore

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            // Each icon's wash is its own view, so changing the icon crossfades between them.
            if let theme = iconStore.theme {
                Wash(palette: theme.palette)
                    .id(theme)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: iconStore.theme)
        .ignoresSafeArea()
    }
}

private struct Wash: View {
    let palette: SupporterIcon.Palette

    var body: some View {
        let locations = SupporterIcon.Palette.locations
        LinearGradient(
            stops: [
                .init(color: palette.mountain, location: locations[0]),
                .init(color: palette.sun, location: locations[1]),
                // The sun's color, faded out, rather than `.clear`, which would fade through black.
                .init(color: palette.sun.opacity(0), location: locations[2]),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// The app's icon as a logo, rounded like on the Home Screen.
struct AppLogo: View {
    @Environment(AppIconStore.self) private var iconStore

    let size: CGFloat

    var body: some View {
        Image(iconStore.current.previewImageName)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: size * 0.225, style: .continuous))
            .accessibilityHidden(true)
    }
}

extension EnvironmentValues {
    /// The app icon's accent color, for controls that need a color rather than the tint style,
    /// such as toolbar buttons, which don't take the tint of the views around them.
    @Entry var appAccentColor: Color = .accentColor
}

#if DEBUG
#Preview {
    VStack {
        AppLogo(size: 96)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { AppBackground() }
    .environment(AppIconStore.preview(.ember))
}
#endif
