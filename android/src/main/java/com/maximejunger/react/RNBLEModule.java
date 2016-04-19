/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   18-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 18-04-2016
*/



package com.maximejunger.react;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.widget.Toast;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Nullable;

/**
 * Project - android - RNBLE
 * Created by Maxime JUNGER - junger_m on 18/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class RNBLEModule extends ReactContextBaseJavaModule {

    private Map                 mPeripherals;
    private BluetoothAdapter    mBluetoothAdapter;
    private BroadcastReceiver   mReceiver;

    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNBLE";
    }


    // use this as an inner class like here or as a top-level class
    public class MyBroadCastReceiver extends BroadcastReceiver {

        ReactApplicationContext mReactApplicationContext;

        @Override
        public void onReceive(Context context, Intent intent) {
            // do something
            String action = intent.getAction();

            if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {

                int extraCode = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1);
                WritableMap params = Arguments.createMap();

                switch (extraCode) {
                    case BluetoothAdapter.STATE_OFF:
                        params.putString("state", "poweredOff");
                        break;
                    case BluetoothAdapter.STATE_ON:
                        params.putString("state", "poweredOn");
                        break;
                }

                if (params.getString("state") != null) {
                    sendEvent(this.mReactApplicationContext, "stateChange", params);
                }
            }
        }

        public MyBroadCastReceiver(ReactApplicationContext reactApplicationContext) {
            mReactApplicationContext = reactApplicationContext;
        }
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

    /**
     * Prepare the Bluetooth and set the stateChange handler
     */
    @ReactMethod
    public void setup() {

        mPeripherals = new HashMap();

        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        WritableMap params = Arguments.createMap();

        if (mBluetoothAdapter == null) {
            params.putString("state", "unsupported");
        } else {
            if (!mBluetoothAdapter.isEnabled()) {
                params.putString("state", "poweredOff");
                System.out.println("NOT ENABLED");
            }
            else {
                params.putString("state", "poweredOn");
                System.out.println("ENABLED");
            }
        }

        sendEvent(this.getReactApplicationContext(), "stateChange", params);

        this.mReceiver = new MyBroadCastReceiver(this.getReactApplicationContext());
        this.getReactApplicationContext().registerReceiver(this.mReceiver, new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED));
    }
}
