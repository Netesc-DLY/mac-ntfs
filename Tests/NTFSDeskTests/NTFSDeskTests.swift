import XCTest
@testable import NTFSDesk

final class NTFSDeskTests: XCTestCase {
    func testVolumeStoreStarts() {
        let store = VolumeStore()
        XCTAssertGreaterThanOrEqual(store.volumes.count, 0)
    }
}
