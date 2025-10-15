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

export interface UpdateNotifierPlugin {
  /**
   * Manually check for app updates
   * @param options Options for the update check
   */
  checkForUpdate(options: UpdateNotifierOptions): void;

  /**
   * Legacy format: Manually check for app updates
   * @param successCallback Success callback
   * @param errorCallback Error callback
   */
  checkForUpdate(
    successCallback: () => void,
    errorCallback?: (error: any) => void
  ): void;
}

declare global {
  interface Window {
    cordova: {
      plugins: {
        UpdateNotifier: UpdateNotifierPlugin;
      };
    };
  }
}

export {};
