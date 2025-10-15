/**
 * Copyright 2020-2023 Ayogo Health Inc.
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
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { Injectable } from "@angular/core";
/**
 * Angular service wrapper for the UpdateNotifier Cordova plugin
 *
 * @example
 * ```typescript
 * import { UpdateNotifier } from '@phemium-costaisa/cordova-plugin-update-notifier';
 *
 * export class MyComponent {
 *   private updateNotifier = inject(UpdateNotifier);
 *
 *   checkForUpdate() {
 *     this.updateNotifier.checkForUpdate({
 *       updateType: 'immediate',
 *       alertType: 'critical'
 *     });
 *   }
 * }
 * ```
 */
let UpdateNotifier = class UpdateNotifier {
    get plugin() {
        return window.cordova?.plugins?.UpdateNotifier;
    }
    /**
     * Check if the plugin is available
     */
    get isAvailable() {
        return !!this.plugin;
    }
    /**
     * Manually check for app updates
     * @param options Options for the update check
     * @returns Promise that resolves when the check completes
     */
    checkForUpdate(options = {}) {
        return new Promise((resolve, reject) => {
            if (!this.isAvailable) {
                reject(new Error("UpdateNotifier plugin is not available"));
                return;
            }
            const successCallback = options.successCallback || (() => resolve());
            const errorCallback = options.errorCallback || ((error) => reject(error));
            this.plugin.checkForUpdate({
                ...options,
                successCallback,
                errorCallback,
            });
        });
    }
    /**
     * Manually check for app updates with callbacks (legacy format)
     * @param successCallback Success callback
     * @param errorCallback Error callback
     */
    checkForUpdateWithCallbacks(successCallback, errorCallback) {
        if (!this.isAvailable) {
            if (errorCallback) {
                errorCallback(new Error("UpdateNotifier plugin is not available"));
            }
            return;
        }
        this.plugin.checkForUpdate(successCallback, errorCallback);
    }
};
UpdateNotifier = __decorate([
    Injectable({
        providedIn: "root",
    })
], UpdateNotifier);
export { UpdateNotifier };
//# sourceMappingURL=index.js.map