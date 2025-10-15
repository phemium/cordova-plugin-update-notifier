<!--
  Copyright 2020-2023 Ayogo Health Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# @phemium-costaisa/cordova-plugin-update-notifier

This plugin provides a mechanism for showing an in-app notification when a new
version of the app is available for download from the App Store or Play Store.

For iOS, this uses the [Siren][siren] library.

For Android, this implements the [Play Store In-App Update][playlib] system.

> ℹ️ **This plugin uses AndroidX!**
>
> Use version 1.x if you are building without AndroidX enabled.

## Installation

### Cordova

```bash
cordova plugin add @phemium-costaisa/cordova-plugin-update-notifier
```

### Angular/Ionic

```bash
npm install @phemium-costaisa/cordova-plugin-update-notifier
```

> **Note:** El wrapper de Angular viene precompilado y listo para usar. No necesitas configurar nada adicional.

#### Specifying Android Library Versions

You may need to specify specific versions of the Android Material Design or
Play App Update frameworks, depending on the Android SDK version and build
tools that your app is targeting. You can override these by specifying versions
as variables when installing.

For example:

```
cordova plugin add @phemium-costaisa/cordova-plugin-update-notifier \
    --variable ANDROIDX_MATERIAL_DESIGN_VERSION=1.8.0 \
    --variable PLAY_APP_UPDATE_SDK_VERSION=2.1.0
```

### Capacitor

```
npm install @phemium-costaisa/cordova-plugin-update-notifier
npx cap sync
```

#### Note about Android strings for Capacitor

To override the text shown in the banner when an update is ready to install,
add the following to `app/src/main/res/values/strings.xml`:

```xml
<string name="app_update_ready">An update has just been downloaded.</string>
<string name="app_update_install">RESTART</string>
```

## Usage

By default, the plugin automatically checks for updates when the app starts. However, you can also manually trigger update checks from JavaScript or Angular/Ionic.

### Angular/Ionic Usage

For Angular and Ionic applications, you can use the provided service wrapper:

```typescript
import { Component, inject, OnInit } from "@angular/core";
import { UpdateNotifier } from "@phemium-costaisa/cordova-plugin-update-notifier/ngx";

@Component({
    selector: "app-example",
    template: '<button (click)="checkUpdate()">Check for Update</button>',
})
export class ExampleComponent implements OnInit {
    private updateNotifier = inject(UpdateNotifier);

    ngOnInit() {
        // Check on component initialization
        this.updateNotifier
            .checkForUpdate({
                updateType: "flexible", // Android
                alertType: "critical", // iOS
            })
            .then(() => {
                console.log("Update check completed");
            })
            .catch((error) => {
                console.error("Update check failed:", error);
            });
    }

    checkUpdate() {
        // Manual check with promise
        this.updateNotifier.checkForUpdate({});
    }

    // Or using async/await
    async checkUpdateAsync() {
        try {
            await this.updateNotifier.checkForUpdate({
                updateType: "immediate",
                alertType: "persistent",
            });
            console.log("Update check completed");
        } catch (error) {
            console.error("Update check failed:", error);
        }
    }
}
```

**TypeScript Options:**

```typescript
interface UpdateNotifierOptions {
    updateType?: "flexible" | "immediate"; // Android
    alertType?:
        | "critical"
        | "annoying"
        | "persistent"
        | "hinting"
        | "relaxed"
        | "default"; // iOS
    successCallback?: () => void;
    errorCallback?: (error: any) => void;
}
```

#### Advanced Angular Examples

**Check on App Start:**

```typescript
import { Component, OnInit, inject } from "@angular/core";
import { Platform } from "@ionic/angular";
import { UpdateNotifier } from "@phemium-costaisa/cordova-plugin-update-notifier/ngx";

@Component({
    selector: "app-root",
    template: "<ion-router-outlet></ion-router-outlet>",
})
export class AppComponent implements OnInit {
    private platform = inject(Platform);
    private updateNotifier = inject(UpdateNotifier);

    ngOnInit() {
        this.platform.ready().then(() => {
            if (this.updateNotifier.isAvailable) {
                this.checkForUpdate();
            }
        });
    }

    private async checkForUpdate() {
        try {
            await this.updateNotifier.checkForUpdate({
                updateType: "flexible",
                alertType: "hinting",
            });
        } catch (error) {
            console.warn("Update check failed:", error);
        }
    }
}
```

**Platform-Specific Updates:**

```typescript
import { Component, inject } from "@angular/core";
import { Platform } from "@ionic/angular";
import { UpdateNotifier } from "@phemium-costaisa/cordova-plugin-update-notifier/ngx";

@Component({
    selector: "app-update-checker",
    template: '<button (click)="checkUpdate()">Check for Updates</button>',
})
export class UpdateCheckerComponent {
    private platform = inject(Platform);
    private updateNotifier = inject(UpdateNotifier);

    async checkUpdate() {
        const isAndroid = this.platform.is("android");
        const isIOS = this.platform.is("ios");

        if (isAndroid) {
            await this.updateNotifier.checkForUpdate({
                updateType: "immediate",
            });
        } else if (isIOS) {
            await this.updateNotifier.checkForUpdate({
                alertType: "critical",
            });
        }
    }
}
```

**Integration with RxJS:**

```typescript
import { Component, inject } from "@angular/core";
import { from } from "rxjs";
import { catchError, tap } from "rxjs/operators";
import { UpdateNotifier } from "@phemium-costaisa/cordova-plugin-update-notifier/ngx";

@Component({
    selector: "app-example",
    template: '<button (click)="checkUpdate()">Check Update</button>',
})
export class ExampleComponent {
    private updateNotifier = inject(UpdateNotifier);

    checkUpdate() {
        from(this.updateNotifier.checkForUpdate({}))
            .pipe(
                tap(() => console.log("Update check successful")),
                catchError((error) => {
                    console.error("Update check failed", error);
                    throw error;
                })
            )
            .subscribe();
    }
}
```

**Create a Dedicated Service:**

```typescript
import { Injectable, inject } from "@angular/core";
import { Platform } from "@ionic/angular";
import { UpdateNotifier } from "@phemium-costaisa/cordova-plugin-update-notifier/ngx";

@Injectable({
    providedIn: "root",
})
export class UpdateService {
    private platform = inject(Platform);
    private updateNotifier = inject(UpdateNotifier);

    async checkForUpdates(): Promise<void> {
        if (!this.updateNotifier.isAvailable) {
            console.warn("Update notifier not available");
            return;
        }

        const isAndroid = this.platform.is("android");
        const isIOS = this.platform.is("ios");

        try {
            if (isAndroid) {
                await this.updateNotifier.checkForUpdate({
                    updateType: "flexible",
                });
            } else if (isIOS) {
                await this.updateNotifier.checkForUpdate({
                    alertType: "persistent",
                });
            }
        } catch (error) {
            console.error("Update check failed:", error);
            throw error;
        }
    }

    async forceUpdate(): Promise<void> {
        if (this.platform.is("android")) {
            await this.updateNotifier.checkForUpdate({
                updateType: "immediate",
            });
        }
    }
}
```

Then use it in your components:

```typescript
import { Component, inject, OnInit } from "@angular/core";
import { UpdateService } from "./services/update.service";

@Component({
    selector: "app-home",
    template: "<ion-content>Home Content</ion-content>",
})
export class HomePage implements OnInit {
    private updateService = inject(UpdateService);

    ngOnInit() {
        this.updateService.checkForUpdates();
    }
}
```

### JavaScript Usage

To manually check for updates from your JavaScript code:

```javascript
cordova.plugins.UpdateNotifier.checkForUpdate({
    successCallback: function () {
        console.log("Update check completed");
    },
    errorCallback: function (error) {
        console.error("Update check failed:", error);
    },
});
```

#### Specifying Update/Alert Type

You can specify the update type for Android or alert type for iOS when calling `checkForUpdate()`:

```javascript
// Android: Force immediate update
cordova.plugins.UpdateNotifier.checkForUpdate({
    updateType: "immediate", // or "flexible"
    successCallback: function () {
        console.log("Update check completed");
    },
    errorCallback: function (error) {
        console.error("Update check failed:", error);
    },
});

// iOS: Use critical alert type
cordova.plugins.UpdateNotifier.checkForUpdate({
    alertType: "critical", // or "annoying", "persistent", "hinting", "relaxed", "default"
    successCallback: function () {
        console.log("Update check completed");
    },
    errorCallback: function (error) {
        console.error("Update check failed:", error);
    },
});

// Specify both (platform-specific values will be used automatically)
cordova.plugins.UpdateNotifier.checkForUpdate({
    updateType: "immediate", // Android
    alertType: "critical", // iOS
    successCallback: function () {
        console.log("Update check completed");
    },
    errorCallback: function (error) {
        console.error("Update check failed:", error);
    },
});
```

**Android Update Types:**

-   `"flexible"` - Allows the user to continue using the app while downloading
-   `"immediate"` - Blocks the user until the update is downloaded and installed

**iOS Alert Types:**

-   `"critical"` - Forces user to update immediately
-   `"annoying"` - Shows alert every time app launches
-   `"persistent"` - Shows alert once per day
-   `"hinting"` - Shows alert once per week
-   `"relaxed"` - Shows alert once per week after 2 weeks
-   `"default"` - Uses Siren's default behavior

### Disabling Automatic Checks

If you want to disable automatic update checks and only check manually from JavaScript, add the following preference to your `config.xml`:

```xml
<preference name="EnableAutomaticUpdates" value="false" />
```

When `EnableAutomaticUpdates` is set to `false`, you must manually call `checkForUpdate()` from your JavaScript code to check for updates.

## Configuration Preferences

### Automatic Update Check

By default, the plugin automatically checks for updates on app launch. You can disable this behavior:

```xml
<preference name="EnableAutomaticUpdates" value="false" />
```

When set to `false`, you must manually trigger update checks using the JavaScript API (see Usage section above).

### Alert Type

Siren's implementation for iOS allows for different alert types (see https://github.com/ArtSabintsev/Siren#screenshots and https://github.com/ArtSabintsev/Siren/blob/6139af3394bc3635c6c8d5255339796feaa7d1a0/Sources/Models/Rules.swift#L12).
You can set the value to "critical", "annoying", "persistent", "hinting" and "relaxed" in config.xml.

```xml
<preference name="SirenAlertType" value="critical" />
<preference name="SirenAlertType" value="annoying" />
<preference name="SirenAlertType" value="persistent" />
<preference name="SirenAlertType" value="hinting" />
<preference name="SirenAlertType" value="relaxed" />
```

For Android, you can force all updates to be considered "immediate" with the `AndroidUpdateAlertType` preference in config.xml.

```xml
<preference name="AndroidUpdateAlertType" value="Immediate" />
```

### Non US-AppStore iOS apps

Siren's implementation for iOS requires specifying a country code if your app is not published to the US AppStore.

```xml
<preference name="SirenCountryCode" value="CA" />
```

For Capacitor, add `"SirenCountryCode": "CA"` to your capacitor.config.json file.

### Managed App Configuration

When deploying an app using an MDM, you can take advantage of [Managed App Configuration](https://developer.apple.com/library/archive/samplecode/sc2279/Introduction/Intro.html) to disable the update check. Simply create a preference called "DisableUpdateCheck" and set it's value to "true".

## Supported Platforms

-   **Cordova CLI** (cordova-cli >= 9.0.0)
-   **iOS** (cordova-ios >= 5.0.0, or capacitor)
-   **Android** (cordova-android >= 9.0.0, or capacitor) with AndroidX

## Contributing

Contributions of bug reports, feature requests, and pull requests are greatly
appreciated!

Please note that this project is released with a [Contributor Code of
Conduct][coc]. By participating in this project you agree to abide by its
terms.

## Licence

Released under the Apache 2.0 Licence.  
Copyright © 2020-2023 Ayogo Health Inc.

[siren]: https://sabintsev.com/Siren/
[playlib]: https://developer.android.com/guide/playcore/in-app-updates
[coc]: https://github.com/phemium/cordova-plugin-update-notifier/blob/main/CODE_OF_CONDUCT.md
