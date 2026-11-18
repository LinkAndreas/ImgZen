import Testing
@testable import ImgZen

@MainActor
struct AppIconTests {

    @Test("Each icon maps to its alternate icon set and back, the classic icon to the primary one")
    func testAlternateIconNames() {
        #expect(AppIcon.classic.alternateIconName == nil)
        #expect(AppIcon.amethyst.alternateIconName == "AppIcon-Amethyst")
        for icon in AppIcon.allCases {
            #expect(AppIcon(alternateIconName: icon.alternateIconName) == icon)
        }
        #expect(AppIcon(alternateIconName: "Unknown") == .classic)
    }
}
