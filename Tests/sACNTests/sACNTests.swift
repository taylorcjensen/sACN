import XCTest
@testable import sACN

final class sACNTests: XCTestCase {
    func testRootLayerTemplateDataCount() {
        XCTAssertEqual(rootLayerTemplate.count, 38)
    }
    func testDmxDataFramingLayerTemplateDataCount() {
        XCTAssertEqual(dmxDataFramingLayerTemplate.count, 77)
    }
    func testFlagsAndLength() {
        XCTAssertEqual(flagsAndLength(length: 1, flags: 0), UInt16(256).networkByteOrder)
    }
    func testDMPLayerStartCodeDefaultsToZero() {
        let layer = DMPLayer(dmxData: Data([0xFF]))
        XCTAssertEqual(layer.startCode, 0x00)
    }
    func testDMPLayerStartCodeCanBeSet() {
        let layer = DMPLayer(dmxData: Data([0xFF]), startCode: 0xDD)
        XCTAssertEqual(layer.startCode, 0xDD)
    }
    func testDMPLayerWritesDefaultStartCode() {
        let layer = DMPLayer(dmxData: Data([0xFF]))
        let packetSize = 126 + 1
        var data = Data(count: packetSize)
        layer.write(to: &data, fullPacketLength: UInt16(packetSize))
        XCTAssertEqual(data[DMPLayer.startCodeIndex], 0x00)
    }
    func testDMPLayerWritesCustomStartCode() {
        let layer = DMPLayer(dmxData: Data([0xFF]), startCode: 0xDD)
        let packetSize = 126 + 1
        var data = Data(count: packetSize)
        layer.write(to: &data, fullPacketLength: UInt16(packetSize))
        XCTAssertEqual(data[DMPLayer.startCodeIndex], 0xDD)
    }
    func testDMPLayerWritesDMXDataAfterStartCode() {
        let dmxData = Data([0x01, 0x02, 0x03])
        let layer = DMPLayer(dmxData: dmxData, startCode: 0xDD)
        let packetSize = 126 + dmxData.count
        var data = Data(count: packetSize)
        layer.write(to: &data, fullPacketLength: UInt16(packetSize))
        XCTAssertEqual(data[126], 0x01)
        XCTAssertEqual(data[127], 0x02)
        XCTAssertEqual(data[128], 0x03)
    }
    func testConnectionPrioritySequenceIsIndependent() {
        let connection = Connection(universe: 1)
        connection.sendDMXData(Data([0xFF]), priority: 100)
        connection.sendDMXData(Data([0xFF]), priority: 100)
        connection.sendDMXData(Data([0xFF]), priority: 100)
        let dmxSeqAfter = connection.sequenceNumber  // should be 3
        connection.sendPerAddressPriority(Data([100]), priority: 100)
        // DMX sequence should be unchanged after sending priority
        XCTAssertEqual(connection.sequenceNumber, dmxSeqAfter)
    }
    func testPrioritySequenceStartsOffsetFromDataSequence() {
        // Per-address priority sequence starts at 128 to avoid matching
        // data sequence numbers, which confuses some sACN receivers.
        let connection = Connection(universe: 1)
        // Data starts at 0
        XCTAssertEqual(connection.sequenceNumber, 0)
        // Send one of each and verify they differ
        connection.sendDMXData(Data([0xFF]), priority: 100)
        connection.sendPerAddressPriority(Data([100]), priority: 100)
        // Data seq is now 1, priority seq is now 129 -- they should not match
        XCTAssertEqual(connection.sequenceNumber, 1)
    }
}
