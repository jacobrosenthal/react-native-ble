package com.maximejunger.react;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.UnsupportedEncodingException;
import java.util.List;
import java.util.UUID;

import javax.annotation.Nullable;

/**
 * Project - android - BluetoothGattCallbackHandler
 * Created by Maxime JUNGER - junger_m on 21/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class BluetoothGattCallbackHandler extends BluetoothGattCallback {

    private ReactApplicationContext mReactApplicationContext;
    private BluetoothGatt mBluetoothGatt;

    final protected static char[] hexArray = "0123456789ABCDEF".toCharArray();

    public BluetoothGattCallbackHandler(ReactApplicationContext rac) {
        this.mReactApplicationContext = rac;
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

    @Override
    public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {

        WritableMap params = Arguments.createMap();

        mBluetoothGatt = gatt;

        if (newState == BluetoothProfile.STATE_CONNECTED) {

            Log.i("Status :", "Connected to GATT server. " + gatt.getDevice().getName());
            params.putString("address", gatt.getDevice().getAddress());
            Log.i("DebugEheheh", "Ici");
            sendEvent(this.mReactApplicationContext, "connect", params);
            Log.i("DebugEheheh", "Laaaa");

        } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            // intentAction = ACTION_GATT_DISCONNECTED;
            //mConnectionState = STATE_DISCONNECTED;
            Log.i("Status :", "Disconnected from GATT server.");
            //broadcastUpdate(intentAction);
        }
    }

    @Override
    public void onServicesDiscovered(BluetoothGatt gatt, int status) {

        WritableArray uuidArray = Arguments.createArray();
        WritableMap params = Arguments.createMap();

        if (status == BluetoothGatt.GATT_SUCCESS) {
            List<BluetoothGattService> services = gatt.getServices();

            for (BluetoothGattService bgs : services) {
                UUID uuid = bgs.getUuid();
                uuidArray.pushString(BluetoothUUIDHelper.longUUIDToShort(uuid.toString()));
            }

            params.putString("address", gatt.getDevice().getAddress());
            params.putArray("servicesUuid", uuidArray);
            sendEvent(this.mReactApplicationContext, "services", params);

        } else {
            Log.w("Services :", "onServicesDiscovered received: " + status);

            params.putInt("error", status);

            sendEvent(this.mReactApplicationContext, "services", params);
        }
    }

    @Override
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicRead(gatt, characteristic, status);
        String str;

        try {
            str = new String(characteristic.getValue(), "UTF-8");
            Log.i("Characteristic read : ", str);

            WritableMap params = Arguments.createMap();
            params.putString("address", gatt.getDevice().getAddress());
            params.putString("serviceUUID", BluetoothUUIDHelper.longUUIDToShort(characteristic.getService().getUuid().toString()));
            params.putString("data", bytesToHex(characteristic.getValue()));
            params.putString("characteristicUuid", BluetoothUUIDHelper.longUUIDToShort(characteristic.getUuid().toString()));

            sendEvent(this.mReactApplicationContext, "read", params);

        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }


    }

    public BluetoothGatt getmBluetoothGatt() {
        return mBluetoothGatt;
    }

    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for ( int j = 0; j < bytes.length; j++ ) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }
}
