import OpenWaterCore
import Foundation

public enum OpenWaterBridge {
    public static func openWaterInit() -> String {
        guard let cString = openwater_init() else {
            return "Failed to get version"
        }
        let result = String(cString: cString)
        // free_string(UnsafeMutablePointer(mutating: cString))
        return result
    }
}
