/* 

The MIT License (MIT)

Copyright (c) 2016 Esa Riihinen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


*/

package com.geniem.rnble;

import android.content.Context;
import android.os.Handler;
import android.util.Log;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import android.os.ParcelUuid;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;



class RNBLEModule extends ReactContextBaseJavaModule {
    private static final String TAG = "RNBLEModule";

    private Context context;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothManager bluetoothManager;
    private BluetoothLeScanner bluetoothLeScanner;
    private ScanCallback scanCallback;
    private final BluetoothGattCallback gattCallback = new RnbleGattCallback(this);
    private String deviceAddress;
    private String bluetoothDeviceAddress;
    private BluetoothGatt bluetoothGatt;
    private int connectionState = STATE_DISCONNECTED;    
    private List<BluetoothGattService> discoveredServices;

    private static final int STATE_DISCONNECTED = 0;
    private static final int STATE_CONNECTING = 1;
    private static final int STATE_CONNECTED = 2;

    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
    }


    @Override
    public void initialize() {
        super.initialize();
        bluetoothManager = (BluetoothManager) this.context.getSystemService(ReactApplicationContext.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
        if(bluetoothAdapter != null){
            bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        }
    }

    /**
     * @return the name of this module. This will be the name used to {@code require()} this module
     * from javascript.
     */
    @Override
    public String getName() {
        return "RNBLE";
    }

    @ReactMethod
    public void getState() {
        WritableMap params = Arguments.createMap();
        if (bluetoothAdapter == null) {
            params.putString("state", "unsupported");            
        } else {
            params.putString("state",stateToString(bluetoothAdapter.getState()));            
        }
        sendEvent("ble.stateChange", params);
    }

    @ReactMethod
    public void startScanning(String deviceAddress, Boolean allowDuplicates) {
        // allowDuplicates can not currently be used in Android

        if(bluetoothLeScanner != null){
            if (scanCallback == null) {
                this.deviceAddress = deviceAddress;
                scanCallback = new RnbleScanCallback(this);
                bluetoothLeScanner.startScan(buildScanFilters(), buildScanSettings(), scanCallback);
            }
        }
    }

    @ReactMethod
    public void stopScanning() {
        if(bluetoothLeScanner != null){
            bluetoothLeScanner.stopScan(scanCallback);
            scanCallback = null;
        }
    }

    @ReactMethod
    public void disconnect(final String peripheralUuid) {
        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", peripheralUuid);

        if (bluetoothAdapter == null || bluetoothGatt == null) {
            Log.w(TAG, "BluetoothAdapter not initialized");

            WritableMap error = Arguments.createMap();
            error.putInt("erroCode", -1);
            error.putString("errorMessage", "BluetoothAdapter not initialized.");
            params.putMap("error", error);
            return;
        }
        bluetoothGatt.disconnect();
        bluetoothGatt.close();
        bluetoothGatt = null;
        discoveredServices = null;
        connectionState = STATE_DISCONNECTED;

        this.sendEvent("ble.disconnect.", params);
    }

    @ReactMethod
    public void connect(final String peripheralUuid) { //in android peripheralUuid is the mac address of the BLE device
        if (bluetoothAdapter == null || peripheralUuid == null) {
            Log.w(TAG, "BluetoothAdapter not initialized or unspecified peripheralUuid.");
            
            WritableMap error = Arguments.createMap();
            error.putInt("erroCode", -1);
            error.putString("errorMessage", "BluetoothAdapter not initialized or unspecified peripheralUuid.");
            
            WritableMap params = Arguments.createMap();
            params.putString("peripheralUuid", peripheralUuid);
            params.putMap("error", error);

            this.sendEvent("ble.connect", params);
            return;
        }

        // Previously connected device.  Try to reconnect.
        if (bluetoothDeviceAddress != null && peripheralUuid.equals(bluetoothDeviceAddress)
                && bluetoothGatt != null) {
            Log.d(TAG, "Trying to use an existing bluetoothGatt for connection.");
            if (bluetoothGatt.connect()) {
                connectionState = STATE_CONNECTING;
                return;
            }
        }

        final BluetoothDevice device = bluetoothAdapter.getRemoteDevice(peripheralUuid);
        if (device == null) {
            Log.w(TAG, "Device not found.  Unable to connect.");
            connectionState = STATE_DISCONNECTED;

            WritableMap error = Arguments.createMap();
            error.putInt("erroCode", -2);
            error.putString("errorMessage", "Device not found.  Unable to connect.");

            WritableMap params = Arguments.createMap();
            params.putString("peripheralUuid", peripheralUuid);
            params.putMap("error", error);

            this.sendEvent("ble.connect", params);
            return;
        }
    
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        bluetoothGatt = device.connectGatt(context, false, gattCallback);
        Log.d(TAG, "Trying to create a new connection.");
        bluetoothDeviceAddress = peripheralUuid;
        connectionState = STATE_CONNECTING;
    }

    @ReactMethod
    public void discoverServices(final String peripheralUuid, ReadableArray uuids){
        WritableArray filteredServiceUuids = Arguments.createArray();

        if(bluetoothGatt != null && this.discoveredServices != null && uuids != null && uuids.size() > 0){
            //filter discovered services
            for(BluetoothGattService service : this.discoveredServices){
                String uuid = service.getUuid().toString();
                for(int i = 0; i < uuids.size(); i++){
                    if(uuid.equals(uuids.getString(i))){
                        filteredServiceUuids.pushString(uuid);
                    }
                }
            }
        } else if(uuids == null || uuids.size() == 0){
            //if no uuids are requested return all discovered service uuids
            for(BluetoothGattService service : this.discoveredServices){
                String uuid = service.getUuid().toString();
                filteredServiceUuids.pushString(uuid);
            }
        }
        
        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", peripheralUuid);
        params.putArray("serviceUuids", filteredServiceUuids);

        this.sendEvent("ble.servicesDiscover", params);
    }

    private void sendEvent(String eventName, WritableMap params) {
        getReactApplicationContext()
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }

    private List<ScanFilter> buildScanFilters() {
        List<ScanFilter> scanFilters = new ArrayList<>();

        ScanFilter.Builder builder = new ScanFilter.Builder();
        // Comment out the below line to see all BLE devices around you
        //builder.setServiceUuid("add service uuid");
        if(deviceAddress != null){
            builder.setDeviceAddress(deviceAddress);
        }
        scanFilters.add(builder.build());

        return scanFilters;
    }

    private ScanSettings buildScanSettings() {
        ScanSettings.Builder builder = new ScanSettings.Builder();
        builder.setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY);
        return builder.build();
    }    

    private String stateToString(int state){
        switch (state) {
            case BluetoothAdapter.STATE_OFF:
                return "poweredOff";
            case BluetoothAdapter.STATE_TURNING_OFF:
                return "turningOff";
            case BluetoothAdapter.STATE_ON:
                return "poweredOn";
            case BluetoothAdapter.STATE_TURNING_ON:
                return "turningOn";
            default:
                return "unknown";
        }
    }


    // GATT callback and methods
    private class RnbleGattCallback extends BluetoothGattCallback {
        private RNBLEModule rnbleModule;
 
        public RnbleGattCallback(RNBLEModule rnbleModule) {
            this.rnbleModule = rnbleModule;
        }

        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            BluetoothDevice remoteDevice = gatt.getDevice();
            String remoteAddress = remoteDevice.getAddress();
            WritableMap params = Arguments.createMap();
            params.putString("peripheralUuid", remoteAddress);

            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.i(TAG, "Connected to GATT server.");
                // Attempts to discover services after successful connection.
                bluetoothGatt.discoverServices();
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                connectionState = STATE_DISCONNECTED;
                Log.i(TAG, "Disconnected from GATT server.");
                rnbleModule.sendEvent("ble.disconnect", params);
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                rnbleModule.discoveredServices = bluetoothGatt.getServices();
            } else {
                Log.w(TAG, "onServicesDiscovered received: " + status);
            }
  
            connectionState = STATE_CONNECTED;

            BluetoothDevice remoteDevice = gatt.getDevice();
            String remoteAddress = remoteDevice.getAddress();

            WritableMap params = Arguments.createMap();
            params.putString("peripheralUuid", remoteAddress);
            rnbleModule.sendEvent("ble.connect", params);
        }
    };    


    //RnbleScanCallback scan callback
    private class RnbleScanCallback extends ScanCallback {
        private RNBLEModule rnbleModule;

        public RnbleScanCallback(RNBLEModule rnbleModule) {
            this.rnbleModule = rnbleModule;
        }


        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            super.onBatchScanResults(results);
            for (ScanResult result : results) {
                processScanResult(result);
            }
        }

        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            super.onScanResult(callbackType, result);
            processScanResult(result);
        }

        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
            Log.d(TAG, "Scan failed with error: " + errorCode);
        }

        private void processScanResult(ScanResult scanResult) {

            if(scanResult == null) {return;}

            ScanRecord record = scanResult.getScanRecord();
            BluetoothDevice device = scanResult.getDevice();

            if(record != null){
                WritableMap params = Arguments.createMap();
                WritableMap advertisement = Arguments.createMap();

                //add service uuids to advertisement map
                WritableArray serviceUuids = Arguments.createArray();
                List<ParcelUuid> uuids = record.getServiceUuids();
                if(uuids != null){
                   for(ParcelUuid uuid : uuids){
                        serviceUuids.pushString(uuid.toString());
                    }
                }
    
                advertisement.putArray("serviceUuids", serviceUuids);

                //add serviceData array to advetisement map
                WritableArray serviceData = Arguments.createArray();
                WritableMap serviceDataMap = Arguments.createMap();

                if(uuids != null) {
                    for(ParcelUuid uuid : uuids){
                        byte[] data = record.getServiceData(uuid);
                        if(uuid != null && data != null){
                            serviceDataMap.putString("uuid", uuid.toString());
                            serviceDataMap.putString("data", Arrays.toString(data));
                            serviceData.pushMap(serviceDataMap);
                        }
                    }
                }
                advertisement.putArray("serviceData", serviceData);

                //add manufacturer data to advertisement map
                byte[] manufacturerData = null;
                if(record.getManufacturerSpecificData() != null){
                    manufacturerData = record.getManufacturerSpecificData().valueAt(0);
                }
                if(manufacturerData != null){
                    advertisement.putString("manufacturerData", Arrays.toString(manufacturerData));
                } else {
                    advertisement.putNull("manufacturerData");
                }

                //add local name to advertisement map
                advertisement.putString("localName", record.getDeviceName());

                //add tx power level to advertisement map
                advertisement.putInt("txPowerLevel", record.getTxPowerLevel());

                params.putMap("advertisement", advertisement);

                //add rssi to params
                params.putInt("rssi", scanResult.getRssi());

                // add id to params
                params.putString("id", device.getAddress());

                // add address to params
                params.putString("address", device.getAddress());

                // add address type to params
                params.putString("addressType", "unknown");

                //add connectable to params
                int flags = record.getAdvertiseFlags();
                params.putBoolean("connectable", (flags & 2) == 2); //TODO: double check this to ensure it is correct

                Log.d(TAG, params.toString());
                rnbleModule.sendEvent("ble.discover", params);
            }
        }
    } 
}
