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
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothHeadset;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanSettings;
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
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;

import javax.annotation.Nullable;

/**
 * Project - android - RNBLE
 * Created by Maxime JUNGER - junger_m on 18/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class RNBLEModule extends ReactContextBaseJavaModule implements BluetoothAdapter.LeScanCallback {

    private Map<String, BluetoothDevice> mPeripherals;
    private BluetoothAdapter mBluetoothAdapter;
    private BluetoothGattCallbackHandler mBluetoothGattCallbackHandler;

    private static final UUID CLIENT_CHARACTERISTIC_CONFIG_DESCRIPTOR_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    // Options
    private boolean scanAllowingDuplicate = true;

    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNBLE";
    }

    // use this as an inner class like here or as a top-level class
//    public class MyBroadCastReceiver extends BroadcastReceiver {
//
//        ReactApplicationContext mReactApplicationContext;
//
//        @Override
//        public void onReceive(Context context, Intent intent) {
//            // do something
//            String action = intent.getAction();
//
//            if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
//
//                int extraCode = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1);
//                WritableMap params = Arguments.createMap();
//
//                switch (extraCode) {
//                    case BluetoothAdapter.STATE_OFF:
//                        params.putString("state", "poweredOff");
//                        break;
//                    case BluetoothAdapter.STATE_ON:
//                        params.putString("state", "poweredOn");
//                        break;
//                }
//
//
//                if (params.hasKey("state") && params.getString("state") != null) {
//                    sendEvent(this.mReactApplicationContext, "stateChange", params);
//                }
//            } else if (BluetoothDevice.ACTION_FOUND.equals(action)) {
//                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
//                // Create a new device item
//                int i = 0;
//                System.out.print(device.getName());
//
//                ParcelUuid[] pcl = device.getUuids();
//
//                System.out.println(device.getAddress());
//
//                System.out.println(device.getType());
//                // DeviceItem newDevice = new DeviceItem(device.getName(), device.getAddress(), "false");
//                // Add it to our adapter
//                // mAdapter.add(newDevice);
//            } else if (BluetoothDevice.ACTION_UUID.equals(action)) {
//                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
//                Parcelable[] uuids = intent.getParcelableArrayExtra(BluetoothDevice.EXTRA_UUID);
//                System.out.print("JE SUIS LA EHEHHEHE");
//                for (Parcelable ep : uuids) {
//                    System.out.print("UUID Records : " + ep.toString());
//                    //Utilities.print("UUID records : "+ ep.toString());
//                }
//            }
//        }
//
//        public MyBroadCastReceiver(ReactApplicationContext reactApplicationContext) {
//            mReactApplicationContext = reactApplicationContext;
//        }
//    }

    /**
     * Send events to Javascript
     *
     * @param reactContext context of react
     * @param eventName    name of event that Javascript is listening
     * @param params       WritableMap of params
     */
    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    /**
     * Prepare the Bluetooth and set the stateChange handler
     * Send event of the current Bluetooth state to React
     */
    @ReactMethod
    public void getState() {

        mPeripherals = new HashMap<String, BluetoothDevice>();

        BluetoothManager manager = (BluetoothManager) this.getReactApplicationContext().getSystemService(Context.BLUETOOTH_SERVICE);
        mBluetoothAdapter = manager.getAdapter();

        WritableMap params = Arguments.createMap();

        if (mBluetoothAdapter == null || !this.getReactApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            params.putString("state", "unsupported");
        } else {
            if (!mBluetoothAdapter.isEnabled()) {
                params.putString("state", "poweredOff");
            } else {
                params.putString("state", "poweredOn");
            }
        }

        sendEvent(this.getReactApplicationContext(), "ble.stateChange", params);

//        this.mReceiver = new MyBroadCastReceiver(this.getReactApplicationContext());
//        this.getReactApplicationContext().registerReceiver(this.mReceiver, new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED));
    }

    /**
     * Start scanning for needed uuids
     * @param uuids UUIDS needed
     * @param allowDuplicates true/false
     */
    @ReactMethod
    public void startScanning(ReadableArray uuids, Boolean allowDuplicates) {

        this.mPeripherals.clear();

        UUID[] arrayUUIDS = new UUID[uuids.size()];

        for (int i = 0; i < uuids.size(); i++) {
            arrayUUIDS[i] =  BluetoothUUIDHelper.shortUUIDToLong(uuids.getString(i));
        }
        this.scanAllowingDuplicate = allowDuplicates;
        this.mBluetoothAdapter.startLeScan(arrayUUIDS, this);
    }

    /**
     * Stop Scanning for LE
     */
    @ReactMethod
    public void stopScanning() {
        this.mBluetoothAdapter.stopLeScan(this);
    }

    /**
     * Called when a device is found
     * @param device device found
     * @param rssi Signal strength
     * @param scanRecord record
     */
    @Override
    public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {

        WritableMap params = Arguments.createMap();

        if (!this.mPeripherals.containsKey(device.getAddress()))
            this.mPeripherals.put(device.getAddress(), device);
        else {
            if (!this.scanAllowingDuplicate) return;
        }

        params.putString("name", device.getName());
        params.putString("peripheralUuid", device.getAddress());
        params.putString("address", device.getAddress());
        params.putInt("rssi", rssi);
        params.putBoolean("connectable", true);

        sendEvent(this.getReactApplicationContext(), "ble.discover", params);
    }

    /**
     * Connect to device
     * @param address of the device
     */
    @ReactMethod
    public void connect(String address) {

        BluetoothDevice device = this.mPeripherals.get(address);
        WritableMap params = Arguments.createMap();

        if (mBluetoothGattCallbackHandler != null && mBluetoothGattCallbackHandler.getmBluetoothGatt() != null) {
            mBluetoothGattCallbackHandler.getmBluetoothGatt().close();
            mBluetoothGattCallbackHandler = null;
        }

        if (device != null) {
            mBluetoothGattCallbackHandler = new BluetoothGattCallbackHandler(this.getReactApplicationContext());
            device.connectGatt(this.getReactApplicationContext(), true, mBluetoothGattCallbackHandler);
        } else {
            params.putString("error", "Device not found");
            sendEvent(this.getReactApplicationContext(), "ble.connect", params);
        }

    }

    @ReactMethod
    public void disconnect(String address) {
        BluetoothDevice device = this.mPeripherals.get(address);
        WritableMap params = Arguments.createMap();

        if (device != null) {
            if (this.mBluetoothGattCallbackHandler != null) {
                this.mBluetoothGattCallbackHandler.getmBluetoothGatt().close();
                params.putString("peripheralUuid", device.getAddress());
                sendEvent(this.getReactApplicationContext(), "ble.disconnect", params);
            }
        }
    }

    /**
     * Discover services of device
     * @param address of the device
     * @param uuids wanted
     */
    @ReactMethod
    public void discoverServices(String address, ReadableArray uuids) {

        BluetoothDevice device = this.mPeripherals.get(address);
        WritableMap params = Arguments.createMap();

        List<String> uuidsList = new ArrayList<>();

        for (int i = 0; i < uuids.size(); i++) {
            uuidsList.add(uuids.getString(i));
        }
        mBluetoothGattCallbackHandler.setServicesUuidSearched(uuidsList);

        if (device != null && this.mBluetoothGattCallbackHandler.getmBluetoothGatt().getDevice().getAddress().equals(device.getAddress())) {
            this.mBluetoothGattCallbackHandler.getmBluetoothGatt().discoverServices();
        } else {
            params.putString("error", "Device not found");
            sendEvent(this.getReactApplicationContext(), "ble.servicesDiscover", params);
        }
    }

    /**
     * Discover Characteristics for service
     * @param address of device
     * @param serviceUUID UUID of service where characteristics are
     * @param characteristicsUUIDs Characteristics wanted
     */
    @ReactMethod
    public void discoverCharacteristics(String address, String serviceUUID, ReadableArray characteristicsUUIDs) {

        BluetoothDevice device = this.mPeripherals.get(address);
        WritableMap params = Arguments.createMap();
        WritableArray characteristics = Arguments.createArray();
        if (device != null && this.mBluetoothGattCallbackHandler.getmBluetoothGatt().getDevice().getAddress().equals(device.getAddress())) {

           BluetoothGattService service = mBluetoothGattCallbackHandler.getmBluetoothGatt().getService(BluetoothUUIDHelper.shortUUIDToLong(serviceUUID));
           if (service != null) {

                params.putString("peripheralUuid", address);
                params.putString("serviceUuid", serviceUUID);

                if (characteristicsUUIDs.size() == 0) {
                    List<BluetoothGattCharacteristic> characs = service.getCharacteristics();

                    for (BluetoothGattCharacteristic blc : characs) {
                        String uuidStr = BluetoothUUIDHelper.longUUIDToShort(blc.getUuid().toString()).toUpperCase();
                        characteristics.pushString(uuidStr);
                    }

                } else {
                    for (int i = 0; i < characteristicsUUIDs.size(); i++) {
                        UUID uuid = BluetoothUUIDHelper.shortUUIDToLong(characteristicsUUIDs.getString(i));

                        BluetoothGattCharacteristic charac = service.getCharacteristic(uuid);

                        if (charac != null) {
                            UUID characteristicUuid = charac.getUuid();
                            String uuidStr = BluetoothUUIDHelper.longUUIDToShort(characteristicUuid.toString()).toUpperCase();
                            WritableMap map = Arguments.createMap();
                            map.putString("uuid", uuidStr);
                            characteristics.pushMap(map);
                        }
                    }
                }
                params.putArray("characteristics", characteristics);

                sendEvent(this.getReactApplicationContext(), "ble.characteristicsDiscover", params);
            } else {
                params.putString("error", "Device not found");
                sendEvent(this.getReactApplicationContext(), "ble.characteristicsDiscover", params);
            }
        }
    }

    /**
     * Read value of characteristic
     * @param address of the device
     * @param serviceUUID UUID of service where characteristic is
     * @param characteristicUUID Characteristic we want to read
     */
    @ReactMethod
    public void read(String address, String serviceUUID, String characteristicUUID) {

        BluetoothDevice device = this.mPeripherals.get(address);
        WritableMap params = Arguments.createMap();

        if (device == null) {
            params.putString("error", "Device not found");
            return;
        }

        BluetoothGattService service = this.mBluetoothGattCallbackHandler.getmBluetoothGatt().getService(BluetoothUUIDHelper.shortUUIDToLong(serviceUUID));

        if (service == null) {
            params.putString("error", "Service not found");
            return;
        }

        BluetoothGattCharacteristic characteristic = service.getCharacteristic(BluetoothUUIDHelper.shortUUIDToLong(characteristicUUID));

        if (characteristic == null) {
            params.putString("error", "Characteristic not found");
            return;
        }

        this.mBluetoothGattCallbackHandler.getmBluetoothGatt().readCharacteristic(characteristic);

    }

    @ReactMethod
    public void notify(String address, String serviceUUID, String characteristicUUID, boolean notify) {

        WritableMap params = Arguments.createMap();

        BluetoothDevice device = this.mPeripherals.get(address);

        if (device == null) {
            params.putString("error", "Device not found");
            return;
        }

        BluetoothGattService service = this.mBluetoothGattCallbackHandler.getmBluetoothGatt().getService(BluetoothUUIDHelper.shortUUIDToLong(serviceUUID));

        if (service == null) {
            params.putString("error", "Service not found");
            return;
        }

        BluetoothGattCharacteristic characteristic = service.getCharacteristic(BluetoothUUIDHelper.shortUUIDToLong(characteristicUUID));

        if (characteristic == null) {
            params.putString("error", "Characteristic not found");
            return;
        }


        // Check characteristic property
        final int properties = characteristic.getProperties();
        if ((properties & BluetoothGattCharacteristic.PROPERTY_NOTIFY) == 0)
            return;

        this.mBluetoothGattCallbackHandler.getmBluetoothGatt().setCharacteristicNotification(characteristic, notify);

        final BluetoothGattDescriptor descriptor = characteristic.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG_DESCRIPTOR_UUID);

        if (descriptor != null) {
            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
            this.mBluetoothGattCallbackHandler.getmBluetoothGatt().writeDescriptor(descriptor);
        }
    }

    @ReactMethod
    public void test() {
        Log.i("TEST", "TEST HELLO");
    }

}