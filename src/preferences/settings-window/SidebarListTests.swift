import XCTest
import Cocoa

final class SidebarListTests: XCTestCase {
    private func descendantViews(_ view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendantViews($0) }
    }

    func testRepeatedContentRefreshDoesNotAccumulateTitleViews() {
        let row = SidebarListRow()
        row.setContent("Shortcut 2", "")
        let count = descendantViews(row).count
        row.setContent("Shortcut 2", "")
        row.setContent("Shortcut 2", "")
        XCTAssertEqual(descendantViews(row).count, count)
    }
}
