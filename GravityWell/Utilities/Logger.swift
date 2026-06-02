import OSLog

enum Logger {
    static let app = os.Logger(subsystem: "com.zacharyreece.GravityWell", category: "App")
    static let api = os.Logger(subsystem: "com.zacharyreece.GravityWell", category: "PiHoleAPI")
}
