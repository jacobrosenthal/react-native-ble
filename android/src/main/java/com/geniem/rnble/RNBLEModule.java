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



class RNBLEModule extends ReactContextBaseJavaModule {
    private static final String TAG = "RNBLEModule";

    private Context context;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothManager bluetoothManager;
    private final ScanCallback callback = new ScanCallback(this);


    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
    }


    @Override
    public void initialize() {
        super.initialize();
        bluetoothManager = (BluetoothManager) this.context.getSystemService(ReactApplicationContext.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
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
    public void startScanning(ReadableArray serviceUuids, Boolean allowDuplicates) {
        // allowDuplicates can not currently be used in Android

        // Filtering by custom UUID is broken in Android 4.3 and 4.4, see:
        // http://stackoverflow.com/questions/18019161/startlescan-with-128-bit-uuids-doesnt-work-on-native-android-ble-implementation?noredirect=1#comment27879874_18019161
        // see also. https://github.com/tdicola/BTLETest/blob/master/app/src/main/java/com/tonydicola/bletest/app/MainActivity.java


        
        /*
        new Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    bluetoothAdapter.stopLeScan(callback);
                }
        }, 10*1000);
        */

        bluetoothAdapter.startLeScan(callback);
    }

    @ReactMethod
    public void stopScanning() {
        bluetoothAdapter.stopLeScan(callback);
    }

    private void sendEvent(String eventName, WritableMap params) {
        getReactApplicationContext()
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
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

    // callback for scan results

    private class ScanCallback implements BluetoothAdapter.LeScanCallback {
        private RNBLEModule rnbleModule;

        public ScanCallback(RNBLEModule rnbleModule) {
            this.rnbleModule = rnbleModule;
        }

        @Override
        public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {

            WritableMap params = Arguments.createMap();
            ScanRecord record = ScanRecord.parseFromBytes(scanRecord);
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


            ParcelUuid uuid = record.getServiceDataUuid();
            byte[] data = record.getServiceData();

            if(uuid != null && data != null){
                serviceDataMap.putString("uuid", uuid.toString());
                serviceDataMap.putString("data", Arrays.toString(data));
                serviceData.pushMap(serviceDataMap);
            }

            advertisement.putArray("serviceData", serviceData);

            //add manufacturer data to advertisement map
            byte[] manufacturerData = record.getManufacturerSpecificData();
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
            params.putInt("rssi", rssi);

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
