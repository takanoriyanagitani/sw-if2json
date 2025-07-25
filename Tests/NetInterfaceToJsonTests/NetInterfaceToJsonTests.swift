import Testing

import class Foundation.DispatchQueue
import struct Network.NWInterface

@testable import NetInterfaceToJson

struct MockNetworkInterface: NetworkInterfaceProtocol {
  let name: String
  let index: Int
  let type: NWInterface.InterfaceType
}

@Test func example() throws {
  let mockInterface = MockNetworkInterface(name: "lo0", index: 1, type: .loopback)
  let json = try interfaces2json([mockInterface]).get()
  #expect(
    json == """
      [
        {
          "index" : 1,
          "name" : "lo0",
          "type" : "loopback"
        }
      ]
      """)
}

@Test func testGetInterfaces() async throws {
  let queue = DispatchQueue(label: "test-label-2025-07-23-10-16-38")
  let timeout: Duration = .seconds(5)
  let interfaces = try await getInterfaces(queue: queue, timeout: timeout).get()
  #expect(!interfaces.isEmpty, "Expected to get at least one network interface")
}

@Test func testPrintInterfaces() async throws {
  try await printInterfaces().get()
  // No explicit #expect needed here, as throwing an error would fail the test.
}
