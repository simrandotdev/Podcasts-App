import XCTest
@testable import Podcasts_Bin

final class StringExtensionTests: XCTestCase {
    func test_htmlToPlainText_keepsParagraphsAndLineBreaks() {
        let html = "<p>First paragraph.</p>\n<p>Second<br>line two<br/>line three</p>"
        XCTAssertEqual(html.htmlToPlainText(), "First paragraph.\n\nSecond\nline two\nline three")
    }

    func test_htmlToPlainText_turnsListItemsIntoBullets() {
        let html = "<p>Links:</p><ul><li><a href=\"https://example.com\">Example</a></li><li>Other</li></ul>"
        XCTAssertEqual(html.htmlToPlainText(), "Links:\n\n• Example\n• Other")
    }

    func test_htmlToPlainText_decodesEntities() {
        let html = "<p>Tom &amp; Jerry &mdash; it&#8217;s &quot;fine&quot; &lt;3 &#x1F399;&nbsp;mic</p>"
        XCTAssertEqual(html.htmlToPlainText(), "Tom & Jerry \u{2014} it\u{2019}s \"fine\" <3 \u{1F399} mic")
    }

    func test_htmlToPlainText_doesNotDoubleDecodeEscapedEntities() {
        XCTAssertEqual("<p>Write &amp;lt; for &lt;</p>".htmlToPlainText(), "Write &lt; for <")
    }

    func test_htmlToPlainText_collapsesSourceWhitespaceInHTML() {
        let html = "<p>One\n   sentence   split\n across lines.</p>\n\n\n<p>Next.</p>"
        XCTAssertEqual(html.htmlToPlainText(), "One sentence split across lines.\n\nNext.")
    }

    func test_htmlToPlainText_keepsPlainTextParagraphs() {
        let text = "First paragraph.\n\nSecond paragraph\nwith a line break."
        XCTAssertEqual(text.htmlToPlainText(), text)
    }

    func test_htmlToPlainText_isEmptyForWhitespaceOnlyMarkup() {
        XCTAssertEqual("<p> </p>\n<br>".htmlToPlainText(), "")
    }
}
