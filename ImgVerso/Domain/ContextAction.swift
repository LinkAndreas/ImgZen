import Foundation

/// Describes an action presented in a context menu or similar UI, with an icon, title, and action block.
struct ContextAction: Identifiable {
    let id: UUID
    let title: String
    let systemImage: String
    let destructive: Bool
    let execute: () -> Void
    
    /// Creates a new context action.
    /// - Parameters:
    ///   - title: Title to display in context menu.
    ///   - systemImage: SFSymbol name for the icon.
    ///   - destructive: Marks the action as destructive for styling. Default is false.
    ///   - execute: Closure to run when the action is triggered.
    init(
        title: String,
        systemImage: String,
        destructive: Bool = false,
        execute: @escaping () -> Void
    ) {
        self.id = UUID()
        self.title = title
        self.systemImage = systemImage
        self.destructive = destructive
        self.execute = execute
    }
}
