import func NetInterfaceToJson.printInterfaces

@main
struct PrintInterfaces {
  static func main() async {
    let printed: Result<_, _> = await printInterfaces()
    do {
      try printed.get()
    } catch {
      print("\( error )")
    }
  }
}
