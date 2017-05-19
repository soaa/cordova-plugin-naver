package com.github.soaa.naver;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import com.nhn.android.naverlogin.OAuthLogin;
import com.nhn.android.naverlogin.OAuthLoginHandler;
import com.nhn.android.naverlogin.data.OAuthErrorCode;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by soaa on 2017. 5. 19..
 */

public class NaverPlugin extends CordovaPlugin {
    private final String NAVER_CLIENT_ID = "com.naver.sdk.clientId";
    private final String NAVER_CLIENT_SECRET = "com.naver.sdk.clientSecret";
    private final String NAVER_CLIENT_NAME = "com.naver.sdk.clientName";

    private final String pluginName = "NaverPlugin";

    private boolean initialized = false;

    @Override
    protected void pluginInitialize() {
        try {
           ApplicationInfo appInfo = cordova.getActivity().getPackageManager().getApplicationInfo(
                   cordova.getActivity().getPackageName(),
                   PackageManager.GET_META_DATA
           );

            if (appInfo != null && appInfo.metaData != null) {
                String clientId = appInfo.metaData.getString(NAVER_CLIENT_ID);
                String clientSecret = appInfo.metaData.getString(NAVER_CLIENT_SECRET);
                String clientName = appInfo.metaData.getString(NAVER_CLIENT_NAME);

                OAuthLogin.getInstance().init(cordova.getActivity().getApplicationContext(), clientId, clientSecret, clientName);

                initialized = true;

                Log.d(pluginName, "plugin initialized:" + clientId);
            }
        } catch (PackageManager.NameNotFoundException e) {
        }
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (!initialized) return false;

        Log.d(pluginName, "executing " + action);
        if ("login".equals(action)) {
            login(callbackContext);
        } else if ("logout".equals(action)) {
            logout(callbackContext);
        } else {
            return false;
        }

        return true;
    }

    private void login(final CallbackContext callbackContext) {
        final OAuthLogin oauthLogin = OAuthLogin.getInstance();
        final Context context = cordova.getActivity().getApplicationContext();

        oauthLogin.startOauthLoginActivity(cordova.getActivity(), new OAuthLoginHandler() {
            @Override
            public void run(boolean result) {

                if(result) {
                    JSONObject jobj = new JSONObject();

                    try {
                        jobj.put("access_token", oauthLogin.getAccessToken(context));
                        jobj.putOpt("refresh_token", oauthLogin.getRefreshToken(context));
                        jobj.putOpt("expires_at", oauthLogin.getExpiresAt(context));
                        jobj.putOpt("token_type", oauthLogin.getTokenType(context));
                        Log.d(pluginName, "naver: login success");
                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, jobj));
                    } catch (JSONException e) {
                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "internal error"));
                        Log.e(pluginName, e.getMessage(), e);
                    }

                } else {
                    OAuthErrorCode error = oauthLogin.getLastErrorCode(context);
                    Log.d(pluginName, String.format("로그인 실패 : [%s] %s",error.getCode(), error.getDesc()));
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, oauthLogin.getLastErrorDesc(context)));
                }
            }
        });
    }

    private void logout(final CallbackContext callbackContext) {
        OAuthLogin.getInstance().logout(cordova.getActivity().getApplicationContext());

        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
    }
}
