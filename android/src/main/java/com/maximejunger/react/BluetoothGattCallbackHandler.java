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

    /**
     * Called when the connection state has changes
     * @param gatt
     * @param status
     * @param newState
     */
    @Override
    public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {

        WritableMap params = Arguments.createMap();

        mBluetoothGatt = gatt;

        if (newState == BluetoothProfile.STATE_CONNECTED) {
            params.putString("peripheralUuid", gatt.getDevice().getAddress());
            sendEvent(this.mReactApplicationContext, "ble.connect", params);
        } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            Log.i("Status :", "Disconnected from GATT server.");
        }
    }

    /**
     * Called when we discovered some services
     * @param gatt gatt
     * @param status status
     */
    @Override
    public void onServicesDiscovered(BluetoothGatt gatt, int status) {

        WritableArray uuidArray = Arguments.createArray();
        WritableMap params = Arguments.createMap();

        if (status == BluetoothGatt.GATT_SUCCESS) {
            List<BluetoothGattService> services = gatt.getServices();

            for (BluetoothGattService bgs : services) {
                UUID uuid = bgs.getUuid();
                String uuidStr = BluetoothUUIDHelper.longUUIDToShort(uuid.toString()).toUpperCase();
                uuidArray.pushString(uuidStr);
            }

            params.putString("peripheralUuid", gatt.getDevice().getAddress());
            params.putArray("servicesUuid", uuidArray);
            sendEvent(this.mReactApplicationContext, "services", params);

        } else {
            Log.w("Services :", "onServicesDiscovered received: " + status);

            params.putInt("error", status);

            sendEvent(this.mReactApplicationContext, "services", params);
        }
    }

    /**
     * Called when a characteristic is read
     * @param gatt Gatt
     * @param characteristic Characteristic that has been read
     * @param status of read
     */
    @Override
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        super.onCharacteristicRead(gatt, characteristic, status);

        WritableMap params = Arguments.createMap();

        String serviceUUIDStr = BluetoothUUIDHelper.longUUIDToShort(characteristic.getService().getUuid().toString()).toUpperCase();
        String characteristicUUIDStr = BluetoothUUIDHelper.longUUIDToShort(characteristic.getUuid().toString()).toUpperCase();

        params.putString("address", gatt.getDevice().getAddress());
        params.putString("serviceUUID", serviceUUIDStr);
        params.putString("data", bytesToHex(characteristic.getValue()));
        params.putString("characteristicUuid", characteristicUUIDStr);

        sendEvent(this.mReactApplicationContext, "read", params);
    }

    @Override
    public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        super.onCharacteristicChanged(gatt, characteristic);

        WritableMap params = Arguments.createMap();

        String serviceUUIDStr = BluetoothUUIDHelper.longUUIDToShort(characteristic.getService().getUuid().toString()).toUpperCase();
        String characteristicUUIDStr = BluetoothUUIDHelper.longUUIDToShort(characteristic.getUuid().toString()).toUpperCase();

        params.putString("address", gatt.getDevice().getAddress());
        params.putString("serviceUUID", serviceUUIDStr);
        params.putString("data", bytesToHex(characteristic.getValue()));
        params.putString("characteristicUUID", characteristicUUIDStr);

        sendEvent(this.mReactApplicationContext, "notify", params);
    }

    /**
     * Get the BluetoothGatt instance
     * @return mBluetoothGatt
     */
    public BluetoothGatt getmBluetoothGatt() {
        return mBluetoothGatt;
    }

    /**
     * Convert byte array to String
     * @param bytes to convert
     * @return array converted
     */
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
