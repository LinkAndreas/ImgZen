import Foundation
import Testing
@testable import ImgZen

struct WebsiteLinksTests {

    @Test("A page opens in the app's language, and in English for languages the site doesn't have")
    func testPageLanguage() {
        #expect(WebsiteLinks.page("privacy", localization: "de").absoluteString == "https://imgzen.linkandreas.de/privacy/de/")
        #expect(WebsiteLinks.page("privacy", localization: "de-AT").absoluteString == "https://imgzen.linkandreas.de/privacy/de/")
        #expect(WebsiteLinks.page("privacy", localization: "en").absoluteString == "https://imgzen.linkandreas.de/privacy/en/")
        #expect(WebsiteLinks.page("privacy", localization: "fr").absoluteString == "https://imgzen.linkandreas.de/privacy/en/")
        #expect(WebsiteLinks.page("privacy", localization: nil).absoluteString == "https://imgzen.linkandreas.de/privacy/en/")
    }
}
