import Foundation

/// Presentation logic for formatting `DeviceInfo` as a multi-line string.
struct DeviceInfoPresenter {

    let deviceInfo: DeviceInfo

    var formatted: String {
        """
        Device: \(deviceInfo.deviceIdentifier)
        iOS: \(deviceInfo.osVersion)
        App: ImgZen
        Version: \(deviceInfo.appVersion) (\(deviceInfo.buildNumber))
        """
    }
}
