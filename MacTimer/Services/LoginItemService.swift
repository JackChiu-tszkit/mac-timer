import Foundation
import ServiceManagement

enum LoginItemService {
    static func apply(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            AppLog.warn("Login item could not be updated. \(type(of: error))")
        }
    }
}
