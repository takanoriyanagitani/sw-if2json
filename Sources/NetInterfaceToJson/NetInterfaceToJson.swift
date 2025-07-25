import class AsyncAlgorithms.AsyncChannel
import struct Foundation.Data
import class Foundation.DispatchQueue
import class Foundation.FileHandle
import class Foundation.JSONEncoder
import struct Network.NWInterface
import struct Network.NWPath
import class Network.NWPathMonitor

public protocol NetworkInterfaceProtocol {
  var name: String { get }
  var index: Int { get }
  var type: NWInterface.InterfaceType { get }
}

extension NWInterface: NetworkInterfaceProtocol {}

public func path2ifaces(_ path: NWPath) -> [NWInterface] {
  path.availableInterfaces
}

public enum JsonError: Error {
  case stringEncodingFailed
  case timeout
}

public func encodeInterfacesToData(_ ifaces: [NetworkInterface]) -> Result<Data, Error> {
  Result(catching: {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(ifaces)
  })
}

public func convertDataToString(_ data: Data) -> Result<String, Error> {
  guard let jsonString = String(data: data, encoding: .utf8) else {
    return .failure(JsonError.stringEncodingFailed)
  }
  return .success(jsonString)
}

public func interfaces2json(_ ifaces: [NetworkInterfaceProtocol]) -> Result<String, Error> {
  let encodableIfaces: [NetworkInterface] = ifaces.map {
    NetworkInterface.newInstance($0)
  }
  return encodeInterfacesToData(encodableIfaces).flatMap { data in
    convertDataToString(data)
  }
}

public func writeString(_ s: String, to fileHandle: FileHandle) -> Result<(), Error> {
  Result(catching: {
    let data: Data = Data(s.utf8)
    try fileHandle.write(contentsOf: data)
  })
}

public enum InterfaceType: String, Codable, Hashable {
  case wifi
  case cellular
  case wiredEthernet
  case loopback
  case other
  case unknown
}

public struct NetworkInterface: Codable, Hashable {
  public let name: String
  public let index: Int
  public let type: InterfaceType

  public static func newInstance(_ raw: NetworkInterfaceProtocol) -> Self {
    let type: InterfaceType
    switch raw.type {
    case .wifi:
      type = .wifi
    case .cellular:
      type = .cellular
    case .wiredEthernet:
      type = .wiredEthernet
    case .loopback:
      type = .loopback
    case .other:
      type = .other
    @unknown default:
      type = .unknown
    }
    return Self(name: raw.name, index: raw.index, type: type)
  }
}

public func sleep(_ wait: Duration) async -> Result<(), Error> {
  do {
    try await Task.sleep(for: wait)
    return .success(())
  } catch {
    return .failure(error)
  }
}

public func getInterfaces(
  queue: DispatchQueue = .global(qos: .default),
  timeout: Duration = .seconds(5)
) async -> Result<[NWInterface], Error> {
  await withTaskGroup(of: Result<[NWInterface], Error>.self) { group in
    let channel = AsyncChannel<[NWInterface]>()

    group.addTask {  // Task for the network monitor
      let monitor = NWPathMonitor()

      monitor.pathUpdateHandler = { path in
        let interfaces = path2ifaces(path)
        Task {
          await channel.send(interfaces)
          channel.finish()
        }
      }

      monitor.start(queue: queue)
      defer { monitor.cancel() }

      for await interfaces in channel {
        return .success(interfaces)
      }

      return .failure(JsonError.timeout)  // Should not be reached if channel sends data
    }

    group.addTask {  // Task for the timeout
      let waited = await sleep(timeout)
      switch waited {
      case .success:
        // If sleep completed successfully, it means the timeout occurred.
        return .failure(JsonError.timeout)
      case .failure:
        // If sleep returned .failure (was cancelled), it means another task finished first.
        // This timeout task should not return a timeout error.
        return .success([])  // Return a dummy success, as this task's result won't be used.
      }
    }

    let result = await group.next()  // Get the result from the first task to complete
    group.cancelAll()
    return result ?? .failure(JsonError.timeout)  // Should not be nil, but handle defensively
  }
}

public func printInterfaces() async -> Result<(), Error> {
  let interfacesResult: Result<[NWInterface], Error> = await getInterfaces()
  let jsonStringResult: Result<String, Error> = interfacesResult.flatMap { interfaces in
    interfaces2json(interfaces)
  }
  return jsonStringResult.flatMap { jsonString in
    writeString(jsonString, to: .standardOutput)
  }
}
