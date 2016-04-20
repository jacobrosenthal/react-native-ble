/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   18-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 18-04-2016
*/



package com.maximejunger.react;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.ParcelUuid;
import android.os.Parcelable;
import android.text.TextUtils;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.annotation.Nullable;

/**
 * Project - android - RNBLE
 * Created by Maxime JUNGER - junger_m on 18/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class RNBLEModule extends ReactContextBaseJavaModule implements BluetoothAdapter.LeScanCallback {

    private Map<String, BluetoothDevice> mPeripherals;
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
            else if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                // Create a new device item
                int i = 0;
                System.out.print(device.getName());

                ParcelUuid[] pcl = device.getUuids();
                //System.out.println(device.getUuids());


                System.out.println(device.getAddress());

                System.out.println(device.getType());
               // DeviceItem newDevice = new DeviceItem(device.getName(), device.getAddress(), "false");
                // Add it to our adapter
               // mAdapter.add(newDevice);
            }
            else  if (BluetoothDevice.ACTION_UUID.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                Parcelable[] uuids = intent.getParcelableArrayExtra(BluetoothDevice.EXTRA_UUID);
                System.out.print("JE SUIS LA EHEHHEHE");
                for (Parcelable ep : uuids) {
                    System.out.print("UUID Records : " + ep.toString());
                    //Utilities.print("UUID records : "+ ep.toString());
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

        mPeripherals = new HashMap<String, BluetoothDevice>();


        BluetoothManager manager = (BluetoothManager) this.getReactApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        mBluetoothAdapter = manager.getAdapter();

        WritableMap params = Arguments.createMap();

        if (mBluetoothAdapter == null || !this.getReactApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
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

    @ReactMethod
    public void startScanning(ReadableArray uuids, Boolean allowDuplicates) {
        System.out.println("Je start scanning :D");
        IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);

        this.mPeripherals.clear();

        if (mBluetoothAdapter.isDiscovering())
            mBluetoothAdapter.cancelDiscovery();

      //  this.getReactApplicationContext().registerReceiver(this.mReceiver, filter);
       // this.getReactApplicationContext().registerReceiver(this.mReceiver, new IntentFilter(BluetoothDevice.ACTION_UUID));
        //this.mBluetoothAdapter.startDiscovery();


        UUID[] arrayUUIDS = new UUID[1];
        arrayUUIDS[0] = UUID.fromString("00001816-0000-1000-8000-00805F9B34FB");


       // UUID[] arrayUUIDS = new UUID[uuids.size()];

//        for (int i = 0; i < uuids.size(); i++) {
//            arrayUUIDS[i] = UUID.fromString(uuids.getString(i));
//
//        }

        /**
         * Start scanning for needed UUIDS
         */
        this.mBluetoothAdapter.startLeScan(arrayUUIDS, this);
    }

    @Override
    public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {

        WritableMap params = Arguments.createMap();

        /**
         * Save devices in map if not present
         */
        if (!this.mPeripherals.containsKey(device.getAddress()))
            this.mPeripherals.put(device.getAddress(), device);

        params.putString("name", device.getName());
        params.putString("address", device.getAddress());
        params.putInt("rssi", rssi);

        sendEvent(this.getReactApplicationContext(), "discover", params);
    }

    @ReactMethod
    public void connect(String address) {
        System.out.print("JE VAIS ME CONNECTER EHEHEH ");

        BluetoothDevice device = this.mPeripherals.get(address);

        if (device != null) {
            // Connect to device
            device.connectGatt(this.getReactApplicationContext(), true, mGattCallbacl);
        }


    }

    private BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
    }

}
