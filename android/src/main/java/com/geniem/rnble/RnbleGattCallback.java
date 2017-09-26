package com.geniem.rnble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothProfile;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import java.util.Arrays;

/**
 * Created by Surajit Sarkar on 26/9/17.
 * Company : Bitcanny Technologies Pvt. Ltd.
 * Email   : surajit@bitcanny.com
 */

public class RnbleGattCallback extends BluetoothGattCallback {

    private RNBLEModule rnbleModule;
    private Object lock;

    public RnbleGattCallback(RNBLEModule rnbleModule) {
        this.rnbleModule = rnbleModule;
        this.lock = rnbleModule.getLock();
        Log.i(RNBLEModule.TAG,"RnbleGattCallback Lock reference :" + lock);
    }

    @Override
    public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
        BluetoothDevice remoteDevice = gatt.getDevice();
        String remoteAddress = remoteDevice.getAddress();
        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", remoteAddress); //remote address used here instead of uuid, not converted to noble format

        if (newState == BluetoothProfile.STATE_CONNECTED) {
            Log.i(RNBLEModule.TAG, "Connected to GATT server. Discovering services.");
            rnbleModule.setConnectionState(RNBLEModule.STATE_CONNECTED);
            // Attempts to discover services after successful connection.
            rnbleModule.discoverServices();
        } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            rnbleModule.setConnectionState(RNBLEModule.STATE_DISCONNECTED);
            rnbleModule.closeGatt();
            Log.i(RNBLEModule.TAG, "Disconnected from GATT server.");
            rnbleModule.sendEvent("ble.disconnect", params);
        }
    }

    @Override
    public void onServicesDiscovered(BluetoothGatt gatt, int status) {
        Log.i(RNBLEModule.TAG, "onServicesDiscovered");
        if (status == BluetoothGatt.GATT_SUCCESS) {
            rnbleModule.setDiscoveredServices();
        } else {
            Log.w(RNBLEModule.TAG, "onServicesDiscovered received: " + status);
        }

        rnbleModule.setConnectionState(RNBLEModule.STATE_CONNECTED);

        BluetoothDevice remoteDevice = gatt.getDevice();
        String remoteAddress = remoteDevice.getAddress();

        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", remoteAddress);
        rnbleModule.sendEvent("ble.connect", params);
    }

    @Override
    public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        Log.i(RNBLEModule.TAG, "onCharacteristicNotify");
        try {
            byte[] characteristicValue = characteristic.getValue();
            if (characteristicValue != null) {
                WritableMap params = Arguments.createMap();

                BluetoothDevice remoteDevice = gatt.getDevice();
                String remoteAddress = remoteDevice.getAddress();

                params.putString("peripheralUuid", remoteAddress);

                params.putString("serviceUuid", rnbleModule.toNobleUuid(characteristic.getService().getUuid().toString()));
                params.putString("characteristicUuid", rnbleModule.toNobleUuid(characteristic.getUuid().toString()));
                params.putString("data", Arrays.toString(characteristicValue));
                params.putBoolean("isNotification", true);
                rnbleModule.sendEvent("ble.data", params);
            }
        } catch (Exception e) {
            Log.e(RNBLEModule.TAG, "onCharacteristicNotify", e);
        }
    }

    @Override
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        Log.i(RNBLEModule.TAG, "onCharacteristicRead");
        synchronized (lock) {
            try {
                byte[] characteristicValue = null;
                Boolean notification = false;
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    Log.w(RNBLEModule.TAG, "!!! characteristic read!!!");
                    characteristicValue = characteristic.getValue();
                } else {
                    Log.e(RNBLEModule.TAG, "onCharacteristicRead received: " + status);
                }

                WritableMap params = Arguments.createMap();

                BluetoothDevice remoteDevice = gatt.getDevice();
                String remoteAddress = remoteDevice.getAddress();

                params.putString("peripheralUuid", remoteAddress);

                params.putString("serviceUuid", rnbleModule.toNobleUuid(characteristic.getService().getUuid().toString()));
                params.putString("characteristicUuid", rnbleModule.toNobleUuid(characteristic.getUuid().toString()));
                params.putString("data", Arrays.toString(characteristicValue));
                params.putBoolean("isNotification", notification);
                rnbleModule.sendEvent("ble.data", params);

            } catch (Exception e) {
                Log.e(RNBLEModule.TAG, "onCharacteristicRead", e);
            }
            lock.notifyAll();
        }
    }


    @Override
    public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        Log.i(RNBLEModule.TAG, "onCharacteristicWrite");
        synchronized (lock) {
            try {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    Log.d(RNBLEModule.TAG, "characteristic written successfully");
                    WritableMap params = Arguments.createMap();

                    BluetoothDevice remoteDevice = gatt.getDevice();
                    String remoteAddress = remoteDevice.getAddress();

                    params.putString("peripheralUuid", remoteAddress);
                    params.putString("serviceUuid", rnbleModule.toNobleUuid(characteristic.getService().getUuid().toString()));
                    params.putString("characteristicUuid", rnbleModule.toNobleUuid(characteristic.getUuid().toString()));

                    Log.w(RNBLEModule.TAG, "sending ble.write callback");
                    rnbleModule.sendEvent("ble.write", params);
                } else {
                    Log.e(RNBLEModule.TAG, "onServicesDiscovered received: " + status);
                }


            } catch (Exception e) {
                Log.e(RNBLEModule.TAG, "onCharacteristicWrite", e);
            }
            lock.notifyAll();
        }
    }

    @Override
    public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        super.onDescriptorWrite(gatt, descriptor, status);
        Log.i(RNBLEModule.TAG, "onDescriptorWrite");
        synchronized (lock) {
            try {
                byte[] descriptorValue = descriptor.getValue();
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    Log.d(RNBLEModule.TAG, "descriptor written successfully :"+Arrays.toString(descriptorValue));
                } else {
                    Log.e(RNBLEModule.TAG, "onDescriptorWrite received: " + status);
                }

            } catch (Exception e) {
                Log.e(RNBLEModule.TAG, "onDescriptorWrite", e);
            }
            lock.notifyAll();
        }
    }
}
