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

package com.ayogo.cordova.updatenotifier;

import android.app.Activity;
import android.content.Intent;
import android.content.IntentSender;
import com.google.android.material.snackbar.Snackbar;
import android.view.View;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.LOG;
import org.json.JSONArray;
import org.json.JSONException;

import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.InstallState;
import com.google.android.play.core.install.InstallStateUpdatedListener;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.InstallStatus;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;

import static android.app.Activity.RESULT_OK;

public class UpdateNotifierPlugin extends CordovaPlugin {
    private AppUpdateManager mAppUpdateManager;
    private InstallStateUpdatedListener mInstallListener;
    private Boolean mHasPrompted = false;

    private final String TAG = "UpdateNotifierPlugin";
    private static final Integer RC_APP_UPDATE = 577;


    /**
     * Called after plugin construction and fields have been initialized.
     */
    @Override
    public void pluginInitialize() {
        LOG.i(TAG, "[UpdateNotifier] Plugin initializing");
    }


    /**
     * Executes the requested action.
     *
     * @param action          The action to execute.
     * @param args            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return                Whether the action was valid.
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        LOG.i(TAG, "[UpdateNotifier] Execute called with action: " + action);
        
        if ("checkForUpdate".equals(action)) {
            String updateType = null;
            
            // Check if options object was passed
            if (args.length() > 0 && !args.isNull(0)) {
                updateType = args.getJSONObject(0).optString("updateType", null);
                LOG.i(TAG, "[UpdateNotifier] Update type override: " + updateType);
            }
            
            checkForUpdate(callbackContext, updateType);
            return true;
        }
        return false;
    }


    /**
     * Called when the activity is becoming visible to the user.
     */
    @Override
    public void onStart() {
        LOG.i(TAG, "[UpdateNotifier] Activity onStart");
        
        mInstallListener = new InstallStateUpdatedListener() {
            @Override
            public void onStateUpdate(InstallState state) {
                LOG.i(TAG, "[UpdateNotifier] Install state updated: " + state.installStatus());
                
                if (state.installStatus() == InstallStatus.DOWNLOADED){
                    LOG.i(TAG, "[UpdateNotifier] Update downloaded, showing snackbar");
                    popupSnackbarForCompleteUpdate();
                } else if (state.installStatus() == InstallStatus.INSTALLED) {
                    LOG.i(TAG, "[UpdateNotifier] Update installed");
                    if (mAppUpdateManager != null){
                        mAppUpdateManager.unregisterListener(mInstallListener);
                    }
                }
            }
        };

        mAppUpdateManager = AppUpdateManagerFactory.create(cordova.getActivity());
        mAppUpdateManager.registerListener(mInstallListener);

        // Check if EnableAutomaticUpdates is enabled
        final Boolean enableAutomaticUpdates = preferences.getBoolean("EnableAutomaticUpdates", true);
        
        LOG.i(TAG, "[UpdateNotifier] EnableAutomaticUpdates setting: " + enableAutomaticUpdates + ", hasPrompted: " + mHasPrompted);
        
        if (enableAutomaticUpdates && mHasPrompted == false) {
            LOG.i(TAG, "[UpdateNotifier] Starting automatic update check");
            performUpdateCheck(null);
        } else {
            LOG.i(TAG, "[UpdateNotifier] Skipping automatic update check");
        }
    }


    /**
     * Manually check for updates (called from JavaScript).
     *
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @param updateType The update type to use (flexible or immediate), or null to use default behavior.
     */
    private void checkForUpdate(final CallbackContext callbackContext, final String updateType) {
        LOG.i(TAG, "[UpdateNotifier] checkForUpdate called from JS with updateType: " + updateType);
        
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                LOG.i(TAG, "[UpdateNotifier] Executing on UI thread");
                performUpdateCheck(updateType);
                callbackContext.success();
            }
        });
    }


    /**
     * Performs the actual update check logic.
     *
     * @param updateTypeOverride The update type to use (flexible or immediate), or null to use preference/default behavior.
     */
    private void performUpdateCheck(final String updateTypeOverride) {
        LOG.i(TAG, "[UpdateNotifier] performUpdateCheck called");
        
        if (mHasPrompted == true) {
            LOG.i(TAG, "[UpdateNotifier] Already prompted, skipping");
            return;
        }

        if (mAppUpdateManager == null) {
            LOG.i(TAG, "[UpdateNotifier] Creating AppUpdateManager");
            mAppUpdateManager = AppUpdateManagerFactory.create(cordova.getActivity());
        }

        LOG.i(TAG, "[UpdateNotifier] Getting app update info");
        Task<AppUpdateInfo> appUpdateInfoTask = mAppUpdateManager.getAppUpdateInfo();

        appUpdateInfoTask.addOnSuccessListener(new OnSuccessListener<AppUpdateInfo>() {
            @Override
            public void onSuccess(AppUpdateInfo appUpdateInfo) {
                LOG.i(TAG, "[UpdateNotifier] ✅ App update info received");
                LOG.i(TAG, "[UpdateNotifier] Update availability: " + appUpdateInfo.updateAvailability());
                LOG.i(TAG, "[UpdateNotifier] Available version code: " + appUpdateInfo.availableVersionCode());
                
                // Determine the update type to use
                boolean forceImmediate = false;
                
                if (updateTypeOverride != null) {
                    // Use the override from JavaScript
                    forceImmediate = updateTypeOverride.equalsIgnoreCase("immediate");
                    LOG.i(TAG, "[UpdateNotifier] Using JS override - forceImmediate: " + forceImmediate);
                } else {
                    // Use the preference setting
                    forceImmediate = preferences.getString("androidupdatealerttype", "").equalsIgnoreCase("immediate");
                    LOG.i(TAG, "[UpdateNotifier] Using preference - forceImmediate: " + forceImmediate);
                }

                if (!forceImmediate && appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                    LOG.i(TAG, "[UpdateNotifier] Starting FLEXIBLE update flow");
                    try {
                        mAppUpdateManager.startUpdateFlowForResult(appUpdateInfo, AppUpdateType.FLEXIBLE, cordova.getActivity(), RC_APP_UPDATE);
                    } catch (IntentSender.SendIntentException e) {
                        LOG.e(TAG, "[UpdateNotifier] ❌ Error starting flexible update", e);
                    }
                } else if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                    LOG.i(TAG, "[UpdateNotifier] Starting IMMEDIATE update flow");
                    try {
                        mAppUpdateManager.startUpdateFlowForResult(appUpdateInfo, AppUpdateType.IMMEDIATE, cordova.getActivity(), RC_APP_UPDATE);
                    } catch (IntentSender.SendIntentException e) {
                        LOG.e(TAG, "[UpdateNotifier] ❌ Error starting immediate update", e);
                    }
                } else if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                    LOG.i(TAG, "[UpdateNotifier] Update already downloaded, showing snackbar");
                    popupSnackbarForCompleteUpdate();
                } else {
                    LOG.i(TAG, "[UpdateNotifier] No update available or unhandled case");
                }
            }
        });
        
        appUpdateInfoTask.addOnFailureListener(new com.google.android.gms.tasks.OnFailureListener() {
            @Override
            public void onFailure(Exception e) {
                LOG.e(TAG, "[UpdateNotifier] ❌ Failed to get app update info", e);
            }
        });
        
        mHasPrompted = true;
        LOG.i(TAG, "[UpdateNotifier] Set hasPrompted to true");
    }

    /**
     * Called when the activity is no longer visible to the user.
     */
    @Override
    public void onStop() {
        if (mAppUpdateManager != null) {
            mAppUpdateManager.unregisterListener(mInstallListener);
        }
    }

    /**
     * Called when an activity you launched exits, giving you the requestCode you started it with,
     * the resultCode it returned, and any additional data from it.
     *
     * @param requestCode   The request code originally supplied to startActivityForResult(),
     *                      allowing you to identify who this result came from.
     * @param resultCode    The integer result code returned by the child activity through its setResult().
     * @param intent        An Intent, which can return result data to the caller (various data can be
     *                      attached to Intent "extras").
     */
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        LOG.i(TAG, "[UpdateNotifier] onActivityResult - requestCode: " + requestCode + ", resultCode: " + resultCode);
        
        if (requestCode == RC_APP_UPDATE) {
            if (resultCode != RESULT_OK) {
                LOG.e(TAG, "[UpdateNotifier] ❌ App Update failed! Result code: " + resultCode);
            } else {
                LOG.i(TAG, "[UpdateNotifier] ✅ App Update result OK");
            }
        }
    }

    private void popupSnackbarForCompleteUpdate() {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Activity activity = cordova.getActivity();

                int descID = activity.getResources().getIdentifier("app_update_ready", "string", activity.getPackageName());
                Snackbar snackbar = Snackbar.make(webView.getView(), (descID != 0 ? activity.getString(descID) : "An update has just been downloaded."), Snackbar.LENGTH_INDEFINITE);

                int actID = activity.getResources().getIdentifier("app_update_install", "string", activity.getPackageName());
                snackbar.setAction((actID != 0 ? activity.getString(actID) : "INSTALL"), new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        if (mAppUpdateManager != null){
                            mAppUpdateManager.completeUpdate();
                        }
                    }
                });

                snackbar.show();
            }
        });
    }
}

