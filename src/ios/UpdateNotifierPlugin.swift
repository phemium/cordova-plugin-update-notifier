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
class UpdateNotifierPlugin : CDVPlugin {

    override func pluginInitialize() {
        NotificationCenter.default.addObserver(self,
                selector: #selector(UpdateNotifierPlugin._didFinishLaunchingWithOptions(_:)),
                name: UIApplication.didFinishLaunchingNotification,
                object: nil);
    }


    @objc internal func _didFinishLaunchingWithOptions(_ notification : NSNotification) {
        print("[UpdateNotifier] App did finish launching")
        
        // Check if there's an MDM setting to disable update checking
        let disableUpdateCheck = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["DisableUpdateCheck"] as? String
        if (disableUpdateCheck == "true") {
            print("[UpdateNotifier] Update check disabled by MDM")
            return;
        }

        // Check if EnableAutomaticUpdates is enabled
        let enableAutomaticUpdatesString = self.commandDelegate.settings["enableautomaticupdates"] as? String ?? "true"
        let enableAutomaticUpdates = enableAutomaticUpdatesString.lowercased() != "false"
        
        print("[UpdateNotifier] EnableAutomaticUpdates setting: \(enableAutomaticUpdatesString), enabled: \(enableAutomaticUpdates)")
        
        if enableAutomaticUpdates {
            print("[UpdateNotifier] Starting automatic update check")
            performUpdateCheck()
        } else {
            print("[UpdateNotifier] Automatic update check disabled")
        }
    }


    /**
     * Manually check for updates (called from JavaScript).
     *
     * @param command The CDVInvokedUrlCommand from Cordova
     */
    @objc(checkForUpdate:)
    func checkForUpdate(command: CDVInvokedUrlCommand) {
        print("[UpdateNotifier] checkForUpdate called from JavaScript")
        
        var alertTypeOverride: String? = nil
        
        // Check if options object was passed
        if command.arguments.count > 0, let options = command.arguments[0] as? [String: Any] {
            alertTypeOverride = options["alertType"] as? String
            print("[UpdateNotifier] Alert type override: \(alertTypeOverride ?? "none")")
        }
        
        performUpdateCheck(alertTypeOverride: alertTypeOverride)
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }


    /**
     * Performs the actual update check logic using Siren.
     *
     * @param alertTypeOverride Optional alert type to override the preference setting
     */
    private func performUpdateCheck(alertTypeOverride: String? = nil) {
        print("[UpdateNotifier] performUpdateCheck called")
        
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            print("[UpdateNotifier] Executing on main thread")
            let siren = Siren.shared

            // Determine which alert type to use
            let alertType = alertTypeOverride ?? (self.commandDelegate.settings["sirenalerttype"] as? String)
            
            print("[UpdateNotifier] Alert type: \(alertType ?? "default")")
            
            if let type = alertType {
                switch type.lowercased() {
                case "critical":
                    print("[UpdateNotifier] Setting rules: critical")
                    siren.rulesManager = RulesManager(globalRules: .critical)
                    break;
                case "annoying":
                    print("[UpdateNotifier] Setting rules: annoying")
                    siren.rulesManager = RulesManager(globalRules: .annoying)
                    break;
                case "persistent":
                    print("[UpdateNotifier] Setting rules: persistent")
                    siren.rulesManager = RulesManager(globalRules: .persistent)
                    break;
                case "hinting":
                    print("[UpdateNotifier] Setting rules: hinting")
                    siren.rulesManager = RulesManager(globalRules: .hinting)
                    break;
                case "relaxed":
                    print("[UpdateNotifier] Setting rules: relaxed")
                    siren.rulesManager = RulesManager(globalRules: .relaxed)
                    break;
                default:
                    print("[UpdateNotifier] Setting rules: default")
                    siren.rulesManager = RulesManager(globalRules: .default)
                }
            }

            if let countryCode = self.commandDelegate.settings["sirencountrycode"] as? String {
                print("[UpdateNotifier] Country code: \(countryCode)")
                siren.apiManager = APIManager(countryCode: countryCode)
            }

            // Configure presentation to show immediately
            print("[UpdateNotifier] Configuring presentation manager")
            siren.presentationManager = PresentationManager(alertTintColor: nil, appName: nil)
            
            // Start Siren check first
            print("[UpdateNotifier] Calling Siren.wail()")
            siren.wail { results in
                switch results {
                case .success(let updateResults):
                    print("[UpdateNotifier] ✅ Siren check completed successfully")
                    print("[UpdateNotifier] Alert action: \(updateResults.alertAction)")
                case .failure(let error):
                    print("[UpdateNotifier] ❌ Siren error: \(error.localizedDescription)")
                }
            }
            
            // After starting Siren, simulate foreground event to trigger the alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("[UpdateNotifier] Simulating willEnterForeground notification")
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("[UpdateNotifier] Simulating didBecomeActive notification")
                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: UIApplication.shared)
                }
            }
        }
    }
}
