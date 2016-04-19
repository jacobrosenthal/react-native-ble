/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   18-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 18-04-2016
*/



package com.maximejunger.react;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import javax.annotation.Nullable;

/**
 * Project - android - RNBLE
 * Created by Maxime JUNGER - junger_m on 18/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class RNBLEModule extends ReactContextBaseJavaModule {

    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNBLE";
    }


    /**
     * Send events to Javascript
     * @param reactContext context of react
     * @param eventName name of event that Javascript is listening
     * @param params WritableMap of params
     */
    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    /**
     * Just a simple test
     */
    @ReactMethod
    public void getTest() {
        System.out.println("Hello moto");

        WritableMap params = Arguments.createMap();

        params.putString("name", "test ahahahahhahah");

        sendEvent(this.getReactApplicationContext(), "testEvent", params);
    }
}
