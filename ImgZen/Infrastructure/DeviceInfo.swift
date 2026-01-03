import UIKit

/// Information about the device and app for feedback and diagnostics.
struct DeviceInfo {
    /// Device model identifier (e.g., "iPhone16,1").
    let deviceIdentifier: String
    /// iOS version string.
    let osVersion: String
    /// App version string from Info.plist.
    let appVersion: String
    /// Build number string from Info.plist.
    let buildNumber: String

    /// Generates device and app information for feedback or diagnostics.
    /// - Returns: A DeviceInfo instance with current device and app details.
    static func compute() -> DeviceInfo {
        let device = UIDevice.current

        // Get device identifier
        let deviceIdentifier = getDeviceIdentifier()

        // Get iOS version
        let osVersion = device.systemVersion

        // Get app version and build number
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        return DeviceInfo(
            deviceIdentifier: deviceIdentifier,
            osVersion: osVersion,
            appVersion: appVersion,
            buildNumber: buildNumber
        )
    }
}

extension DeviceInfo {
    /// Retrieves the device model identifier from system information.
    /// - Returns: Device identifier string (e.g., "iPhone16,1").
    private static func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier
    }
}
