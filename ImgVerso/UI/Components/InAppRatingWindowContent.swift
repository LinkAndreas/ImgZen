import SwiftUI

/// Content view for the in-app rating/feedback window.
struct InAppRatingWindowContent: View {
    let likeButtonAction: () -> Void
    let dislikeButtonAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                Text(String(localized: "rating.enjoyingApp"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)

                Text(String(localized: "rating.likeUsingApp"))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)

                HStack {
                    Button(String(localized: "button.notReally"), action: dislikeButtonAction)
                        .buttonStyle(.bordered)

                    Button(String(localized: "button.yesILoveIt"), action: likeButtonAction)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(30)
            .frame(maxWidth: 350)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(
                color: .black.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
            .padding()
        }
    }
}
