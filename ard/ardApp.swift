//
//  ardApp.swift
//  ard
//
//  Created on 19/10/2023.
//

// todo:
// use userDefault if defaultSettings are empty when selecting profile

import SwiftUI

@main
struct ardApp: App {
    
    @State var currentDisplaySetupShortLetter: String = "x"
    
    var body: some Scene {
//        no need for menu bar app
//        WindowGroup {
//            ContentView()
//        }
        
        MenuBarExtra(currentDisplaySetupShortLetter, systemImage: "\(currentDisplaySetupShortLetter).square") {
            Button("Home") {
                currentDisplaySetupShortLetter = "h"
                
                let profileScreensInfoList = getSettingsByProfile(profile: currentDisplaySetupShortLetter)
                
                for screen in profileScreensInfoList {
                    setDisplayOrigin(display: screen.id, x: Int32(screen.x), y: Int32(screen.y))
                }
            }
            Button("Office") {
                currentDisplaySetupShortLetter = "o"
                
                let profileScreensInfoList = getSettingsByProfile(profile: currentDisplaySetupShortLetter)
                
                for screen in profileScreensInfoList {
                    setDisplayOrigin(display: screen.id, x: Int32(screen.x), y: Int32(screen.y))
                }
            }
            // debug only
            /*
            Button("Print") {
                currentDisplaySetupShortLetter = "p"
                
                for (profile, settings) in displaySettings {
                    print(profile)
                    for info in settings {
                        print(info.name, info.x, info.y, info.id)
                    }
                }
            }
            Button("Print saved") {
                currentDisplaySetupShortLetter = "x"
                
                if let dataDto = UserDefaults.standard.data(forKey: "ardSavedSettings") {
                    do {
                        let decoder = JSONDecoder()
                        let ardSettingsStored = try decoder.decode([String: Set<ScreenPositionInfo>].self, from: dataDto)
                        for (profile, settings) in ardSettingsStored {
                            for monitor in settings {
                                print(profile, monitor.id, monitor.name)
                            }
                        }
                    } catch {
                        
                    }
                }
            }
             */
            Divider()
            Menu("Save...") {
                Button("Home") {
                    currentDisplaySetupShortLetter = "h"
                    
                    var screensSettings = Set<ScreenPositionInfo>()
                    
                    for screen in NSScreen.screens {
                        let quartzFrame = CGDisplayBounds(screen.displayID)
                        let x = quartzFrame.origin.x
                        let y = quartzFrame.origin.y
                        
                        let screenInfo = ScreenPositionInfo(x: x, y: y, id: screen.displayID, name: screen.localizedName)
                        
                        screensSettings.insert(screenInfo)
                    }
                    
                    self.saveXYForDisplayId(profileName: currentDisplaySetupShortLetter, screens: screensSettings)
                }
                Button("Office") {
                    currentDisplaySetupShortLetter = "o"
                    
                    var screensSettings = Set<ScreenPositionInfo>()
                    
                    for screen in NSScreen.screens {
                        let quartzFrame = CGDisplayBounds(screen.displayID)
                        let x = quartzFrame.origin.x
                        let y = quartzFrame.origin.y
                        
                        let screenInfo = ScreenPositionInfo(x: x, y: y, id: screen.displayID, name: screen.localizedName)
                        
                        screensSettings.insert(screenInfo)
                    }
                    
                    self.saveXYForDisplayId(profileName: currentDisplaySetupShortLetter, screens: screensSettings)
                }
            }
            Divider()
            Button("Quit") {
                /* //this saves settings to UserDefaults to use after the app has been restarted
                let encoded = try? JSONEncoder().encode(displaySettings)
                UserDefaults.standard.set(encoded, forKey: "ardSavedSettings")
                */
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    func saveXYForDisplayId(profileName: String, screens: Set<ScreenPositionInfo>) {
        displaySettings[profileName] = screens
    }
    
    func getSettingsByProfile(profile: String) -> Set<ScreenPositionInfo> {
        return displaySettings[profile] ?? Set<ScreenPositionInfo>()
    }
    
    func setDisplayOrigin(display: CGDirectDisplayID, x: Int32, y: Int32) -> CGError {
        let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
        var ret = CGBeginDisplayConfiguration(config)
        if (ret != CGError.success) {
            return ret
        }
        ret = CGConfigureDisplayOrigin(config.pointee, display, x, y)
        if (ret != CGError.success) {
            return ret
        }
        ret = CGCompleteDisplayConfiguration(config.pointee, CGConfigureOption.permanently)
        return ret
    }
    
    func mapInfoToDto(profile: String, source: ScreenPositionInfo) -> ScreenPositionInfoDto {
        return ScreenPositionInfoDto(profile: profile, x: String(format: "%.1f", source.x), y: String(format: "%.1f", source.y), id: String(source.id), name: source.name)
    }
}

// when ready to save to UserDefaults (if needed)
/*
func initDefaults() -> Void {
    if let dataDto = UserDefaults.standard.data(forKey: "ardSavedSettings") {
        do {
            let decoder = JSONDecoder()
            let ardSettingsStored = try decoder.decode([String: Set<ScreenPositionInfo>].self, from: dataDto)
            for (profile, settings) in ardSettingsStored {
                for monitor in settings {
                    print(profile, monitor.id, monitor.name)
                }
            }
        } catch {
            
        }
    }
}
*/

var displaySettings: [String: Set<ScreenPositionInfo>] = [:]

class ScreenPositionInfo: Hashable, Codable {
    
    var x: Double
    var y: Double
    var id: CGDirectDisplayID
    var name: String
    
    init(x: Double, y: Double, id: CGDirectDisplayID, name: String) {
        self.x = x
        self.y = y
        self.id = id
        self.name = name
    }
    
    static func == (lhs: ScreenPositionInfo, rhs: ScreenPositionInfo) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class ScreenPositionInfoDto: Codable {
    var profile: String
    var x: String
    var y: String
    var id: String
    var name: String
    
    init(profile: String, x: String, y: String, id: String, name: String) {
        self.profile = profile
        self.x = x
        self.y = y
        self.id = id
        self.name = name
    }
}

struct ArdSavedSettingsStored: Codable {
    var settings: [ScreenPositionInfoDto] = Array()
    
    init(settings: [ScreenPositionInfoDto]) {
        self.settings = settings
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        return deviceDescription[key] as! CGDirectDisplayID
    }
}
