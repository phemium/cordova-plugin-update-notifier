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

var exec = require("cordova/exec");

var UpdateNotifier = {
  _listeners: [],

  onUpdateAvailable: function (callback) {
    if (typeof callback !== "function") {
      throw new Error("Callback must be a function");
    }
    this._listeners.push(callback);

    // Return unsubscribe function
    var self = this;
    return function unsubscribe() {
      var index = self._listeners.indexOf(callback);
      if (index !== -1) {
        self._listeners.splice(index, 1);
      }
    };
  },

  checkForUpdate: function (options, errorCallback) {
    var successCallback, updateType, alertType;

    // Support legacy format: checkForUpdate(successCallback, errorCallback)
    if (typeof options === "function") {
      successCallback = options;
      errorCallback = errorCallback || function () {};
      updateType = null;
      alertType = null;
    } else {
      // New format: checkForUpdate({ successCallback, errorCallback, updateType, alertType })
      successCallback = options.successCallback || function () {};
      errorCallback = options.errorCallback || function () {};
      updateType = options.updateType || null;
      alertType = options.alertType || null;
    }

    var args = [];
    if (updateType || alertType) {
      args.push({
        updateType: updateType,
        alertType: alertType,
      });
    }

    exec(
      successCallback,
      errorCallback,
      "UpdateNotifier",
      "checkForUpdate",
      args
    );
  },

  _notifyListeners: function (updateInfo) {
    this._listeners.forEach(function (callback) {
      try {
        callback(updateInfo);
      } catch (error) {
        console.error("Error in onUpdateAvailable listener:", error);
      }
    });
  },
};

// Setup event listener
exec(
  function (updateInfo) {
    UpdateNotifier._notifyListeners(updateInfo);
  },
  function (error) {
    console.error("UpdateNotifier event error:", error);
  },
  "UpdateNotifier",
  "startEventListener",
  []
);

module.exports = UpdateNotifier;
