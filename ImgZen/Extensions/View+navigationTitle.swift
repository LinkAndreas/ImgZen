import SwiftUI
import UIKit

extension View {
    /// Sets the navigation title, centered inline on iPad: there the title sits in the bar of the content
    /// column, centered over the content rather than across the inspector next to it. iPhone keeps
    /// the large title that collapses while scrolling.
    @ViewBuilder
    func adaptiveNavigationTitle(_ title: String) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
        } else {
            navigationTitle(title)
        }
    }
}
