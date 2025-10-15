/**
 * Copyright 2020 Ayogo Health Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Siren

@objc(CDVUpdateNotifierPlugin)
class UpdateNotifierPlugin : CDVPlugin, SirenDelegate {
    
    private var eventCallbackId: String?

    override func pluginInitialize() {
        NotificationCenter.default.addObserver(self,
                selector: #selector(UpdateNotifierPlugin._didFinishLaunchingWithOptions(_:)),
                name: UIApplication.didFinishLaunchingNotification,
                object: nil);
    }


    @objc internal func _didFinishLaunchingWithOptions(_ notification : NSNotification) {
        // Check if there's an MDM setting to disable update checking
        let disableUpdateCheck = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["DisableUpdateCheck"] as? String
        if (disableUpdateCheck == "true") {
            return;
        }

        // Check if AUTO_CHECK is enabled
        let autoCheckString = self.commandDelegate.settings["auto_check"] as? String ?? "true"
        let autoCheck = autoCheckString.lowercased() != "false"
        
        if autoCheck {
            performUpdateCheck()
        }
    }


    /**
     * Manually check for updates (called from JavaScript).
     *
     * @param command The CDVInvokedUrlCommand from Cordova
     */
    @objc(checkForUpdate:)
    func checkForUpdate(command: CDVInvokedUrlCommand) {
        var alertTypeOverride: String? = nil
        
        // Check if options object was passed
        if command.arguments.count > 0, let options = command.arguments[0] as? [String: Any] {
            alertTypeOverride = options["alertType"] as? String
        }
        
        performUpdateCheck(alertTypeOverride: alertTypeOverride)
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }


    /**
     * Start listening for update events (called from JavaScript).
     *
     * @param command The CDVInvokedUrlCommand from Cordova
     */
    @objc(startEventListener:)
    func startEventListener(command: CDVInvokedUrlCommand) {
        eventCallbackId = command.callbackId
        
        // Keep the callback for multiple events
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_NO_RESULT)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }


    /**
     * Send update available event to JavaScript.
     *
     * @param updateInfo Dictionary with update information
     */
    private func sendUpdateAvailableEvent(updateInfo: [String: Any]) {
        guard let callbackId = eventCallbackId else {
            return
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: updateInfo)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }


    // MARK: - SirenDelegate Methods
    
    /**
     * Called when Siren detects a new version.
     */
    func sirenDidDetectNewVersionWithoutAlert(title: String, message: String, updateType: Siren.UpdateType) {
        var updateInfo: [String: Any] = [
            "updateAvailable": true,
            "title": title,
            "message": message,
            "platform": "ios"
        ]
        
        switch updateType {
        case .force:
            updateInfo["alertType"] = "force"
        case .option:
            updateInfo["alertType"] = "option"
        case .skip:
            updateInfo["alertType"] = "skip"
        case .none:
            updateInfo["alertType"] = "none"
        @unknown default:
            updateInfo["alertType"] = "unknown"
        }
        
        sendUpdateAvailableEvent(updateInfo: updateInfo)
    }


    /**
     * Performs the actual update check logic using Siren.
     *
     * @param alertTypeOverride Optional alert type to override the preference setting
     */
    private func performUpdateCheck(alertTypeOverride: String? = nil) {
        let siren = Siren.shared
        
        // Set this plugin as the delegate to receive update events
        siren.delegate = self

        // Determine which alert type to use
        let alertType = alertTypeOverride ?? (self.commandDelegate.settings["sirenalerttype"] as? String)
        
        if let type = alertType {
            switch type.lowercased() {
            case "critical":
                siren.rulesManager = RulesManager(globalRules: .critical)
                break;
            case "annoying":
                siren.rulesManager = RulesManager(globalRules: .annoying)
                break;
            case "persistent":
                siren.rulesManager = RulesManager(globalRules: .persistent)
                break;
            case "hinting":
                siren.rulesManager = RulesManager(globalRules: .hinting)
                break;
            case "relaxed":
                siren.rulesManager = RulesManager(globalRules: .relaxed)
                break;
            default:
                siren.rulesManager = RulesManager(globalRules: .default)
            }
        }

        if let countryCode = self.commandDelegate.settings["sirencountrycode"] as? String {
            siren.apiManager = APIManager(countryCode: countryCode)
        }

        siren.wail()
    }
}
