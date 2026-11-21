import Foundation
import Testing
@testable import ImgZen

struct WebsiteLinksTests {

    @Test("A page opens in the app's language, and in English for languages the site doesn't have")
    func testPageLanguage() {
        #expect(WebsiteLinks.page("privacy", localization: "de").absoluteString == "https://imgzen.linkandreas.de/privacy/de/")
        #expect(WebsiteLinks.page("privacy", localization: "de-AT").absoluteString == "https://imgzen.linkandreas.de/privacy/de/")
        #expect(WebsiteLinks.page("privacy", localization: "en").absoluteString == "https://imgzen.linkandreas.de/privacy/en/")
        #expect(WebsiteLinks.page("privacy", localization: "sv").absoluteString == "https://imgzen.linkandreas.de/privacy/en/")
        #expect(WebsiteLinks.page("privacy", localization: nil).absoluteString == "https://imgzen.linkandreas.de/privacy/en/")
    }

    @Test(
        "Every app language opens the website's page in that language",
        arguments: [
            ("es", "es"), ("fr", "fr"), ("fr-CA", "fr"), ("it", "it"), ("nl", "nl"), ("ja", "ja"), ("ko", "ko"),
            ("pt-BR", "pt-br"), ("pt-PT", "pt-br"), ("ru", "ru"), ("ru-RU", "ru"), ("zh-Hans", "zh"), ("zh-Hans-CN", "zh"),
        ]
    )
    func testNewLanguages(localization: String, path: String) {
        #expect(WebsiteLinks.page("imprint", localization: localization).absoluteString == "https://imgzen.linkandreas.de/imprint/\(path)/")
    }

    @Test("The legal pages use the paths the website publishes them at")
    func testLegalPages() {
        #expect(WebsiteLinks.page("termsofuse", localization: "de").absoluteString == "https://imgzen.linkandreas.de/termsofuse/de/")
        #expect(WebsiteLinks.termsOfUse.path().hasPrefix("/termsofuse/"))
        #expect(WebsiteLinks.legalNotice.path().hasPrefix("/imprint/"))
    }
}
