package com.geniem.rnble;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;
import android.os.Build;
import android.os.ParcelUuid;
import android.support.annotation.RequiresApi;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.Arrays;
import java.util.List;

/**
 * Created by Surajit Sarkar on 26/9/17.
 * Company : Bitcanny Technologies Pvt. Ltd.
 * Email   : surajit@bitcanny.com
 */

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class RnbleScanCallback extends ScanCallback {

    private RNBLEModule rnbleModule;
    private boolean allowDuplicates;

    public RnbleScanCallback(RNBLEModule rnbleModule,boolean allowDuplicates) {
        this.rnbleModule = rnbleModule;
        this.allowDuplicates = allowDuplicates;
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
        boolean isDuplicate = false;
        BluetoothDevice device = result.getDevice();
        String address = device.getAddress();
        //filter out duplicate entries if requested
        if(!allowDuplicates){
            isDuplicate = rnbleModule.isDuplicateDevice(address);
        }

        if(!isDuplicate){
            rnbleModule.addScannedDevice(address);
            super.onScanResult(callbackType, result);
            processScanResult(result);
        }
    }

    @Override
    public void onScanFailed(int errorCode) {
        super.onScanFailed(errorCode);
        Log.d(RNBLEModule.TAG, "Scan failed with error: " + errorCode);
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
                    serviceUuids.pushString(rnbleModule.toNobleUuid(uuid.toString()));
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
                        serviceDataMap.putString("uuid", rnbleModule.toNobleUuid(uuid.toString()));
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

            Log.d(RNBLEModule.TAG, params.toString());
            rnbleModule.sendEvent("ble.discover", params);
        }
    }
}
