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
    func testSharedSequenceNumberAcrossDataAndPriority() {
        // DATA and PAP share a single monotonic sequence counter,
        // matching ETC Eos behavior and avoiding jump warnings in sACNView.
        let connection = Connection(universe: 1)
        XCTAssertEqual(connection.sequenceNumber, 0)

        connection.sendDMXData(Data([0xFF]), priority: 100)
        XCTAssertEqual(connection.sequenceNumber, 1)

        connection.sendPerAddressPriority(Data([100]), priority: 100)
        XCTAssertEqual(connection.sequenceNumber, 2)

        connection.sendDMXData(Data([0xFF]), priority: 100)
        XCTAssertEqual(connection.sequenceNumber, 3)

        connection.sendPerAddressPriority(Data([100]), priority: 100)
        XCTAssertEqual(connection.sequenceNumber, 4)
    }
}
