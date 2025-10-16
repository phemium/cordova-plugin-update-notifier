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

import { InjectionToken } from "@angular/core";

export interface UpdateNotifierOptions {
  /**
   * (Android) Update type: "flexible" or "immediate"
   */
  updateType?: "flexible" | "immediate";

  /**
   * (iOS) Alert type: "critical", "annoying", "persistent", "hinting", "relaxed", or "default"
   */
  alertType?:
    | "critical"
    | "annoying"
    | "persistent"
    | "hinting"
    | "relaxed"
    | "default";

  /**
   * Success callback
   */
  successCallback?: () => void;

  /**
   * Error callback
   */
  errorCallback?: (error: any) => void;
}

/**
 * Angular service wrapper for the UpdateNotifier Cordova plugin
 *
 * @example
 * ```typescript
 * import { UpdateNotifier } from '@phemium-costaisa/cordova-plugin-update-notifier/ngx';
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
export class UpdateNotifier {
  private get plugin() {
    return (window as any).cordova?.plugins?.UpdateNotifier;
  }

  /**
   * Check if the plugin is available
   */
  get isAvailable(): boolean {
    return !!this.plugin;
  }

  /**
   * Manually check for app updates
   * @param options Options for the update check
   * @returns Promise that resolves when the check completes
   */
  checkForUpdate(options: UpdateNotifierOptions = {}): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.isAvailable) {
        reject(new Error("UpdateNotifier plugin is not available"));
        return;
      }

      const successCallback = options.successCallback || (() => resolve());
      const errorCallback =
        options.errorCallback || ((error: any) => reject(error));

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
  checkForUpdateWithCallbacks(
    successCallback: () => void,
    errorCallback?: (error: any) => void
  ): void {
    if (!this.isAvailable) {
      if (errorCallback) {
        errorCallback(new Error("UpdateNotifier plugin is not available"));
      }
      return;
    }

    this.plugin.checkForUpdate(successCallback, errorCallback);
  }
}

/**
 * Injection token for UpdateNotifier service
 */
export const UPDATE_NOTIFIER = new InjectionToken<UpdateNotifier>(
  "UpdateNotifier",
  {
    providedIn: "root",
    factory: () => new UpdateNotifier(),
  }
);

/**
 * Factory function to create UpdateNotifier instance
 * Use this if you want to provide the service manually
 */
export function provideUpdateNotifier() {
  return {
    provide: UPDATE_NOTIFIER,
    useFactory: () => new UpdateNotifier(),
  };
}
