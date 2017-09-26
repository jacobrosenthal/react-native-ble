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

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.util.Log;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanSettings;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.LifecycleEventListener;

import android.os.ParcelUuid;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.UUID;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import android.util.Base64;

class RNBLEModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
    public static final String TAG = "RNBLEModule";

    private Context context;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothManager bluetoothManager;
    private BluetoothLeScanner bluetoothLeScanner;
    private ScanCallback scanCallback;
    private BluetoothGattCallback gattCallback;
    private ReadableArray serviceUuids;
    private String bluetoothDeviceAddress;
    private BluetoothGatt bluetoothGatt;
    private int connectionState = STATE_DISCONNECTED;    
    private List<BluetoothGattService> discoveredServices;
    private List<String> scannedDeviceAddresses = new ArrayList<String>();
    private Boolean allowDuplicates = false;

    public static final int STATE_DISCONNECTED = 0;
    public static final int STATE_CONNECTING = 1;
    public static final int STATE_CONNECTED = 2;

    private HandlerThread handlerThread;
    private Handler mHandler;

    public static final int READ = 0;
    public static final int WRITE = 1;
    public static final int NOTIFY = 2;
    private Object lock;


    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
        reactContext.addLifecycleEventListener(this);
        lock = new Object();
        gattCallback = new RnbleGattCallback(this);
        scannedDeviceAddresses = new ArrayList<>();
    }

    public Object getLock(){
        return lock;
    }

    @Override
    public void initialize() {
        super.initialize();
        Log.i(TAG,"React Native BLE Module initialised");
        bluetoothManager = (BluetoothManager) this.context.getSystemService(ReactApplicationContext.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();

        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        context.registerReceiver(bleStateReceiver, filter);
    }

    private final BroadcastReceiver bleStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();

            if (action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                        BluetoothAdapter.ERROR);
                if (state == BluetoothAdapter.STATE_OFF || state == BluetoothAdapter.STATE_ON) {
                    WritableMap params = Arguments.createMap();
                    params.putString("state",stateToString(bluetoothAdapter.getState()));
                    sendEvent("ble.stateChange", params);
                }
            }
        }
    };

    @Override
    public void onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy();
        Log.i(TAG,"React Native BLE Module destroyed");
        try{
            if(context!=null && bleStateReceiver!=null){
                context.unregisterReceiver(bleStateReceiver);
            }
        } catch (Exception e){
            Log.e(TAG,"React Native BLE Module can not be destroyed",e);
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
    public void startScanning(ReadableArray serviceUuids, Boolean allowDuplicates) {
        Log.d(TAG, "RNBLE startScanning - service uuid: " + serviceUuids);
        if(bluetoothAdapter!=null && bluetoothLeScanner == null){
            bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        }
        if(bluetoothLeScanner != null){
            if (scanCallback == null) {
                this.allowDuplicates = allowDuplicates;
                scannedDeviceAddresses.clear();
                this.serviceUuids = serviceUuids;
                scanCallback = new RnbleScanCallback(this,allowDuplicates);
                bluetoothLeScanner.startScan(buildScanFilters(), buildScanSettings(), scanCallback);
            }
        }

        if(bluetoothLeScanner == null || scanCallback == null) {
             Log.e(TAG, "RNBLE startScanning - FAIlED to start scan");
        }
    }

    @ReactMethod
    public void stopScanning() {
        if(bluetoothLeScanner != null && scanCallback != null){
            bluetoothLeScanner.stopScan(scanCallback);
            scanCallback = null;            
        } else{
            Log.d(TAG, "RNBLE stopScanning - FAIlED to stop scan");
        }
    }

    @ReactMethod
    public void disconnect(final String peripheralUuid) {
        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", peripheralUuid);

        if (bluetoothGatt == null) {
            Log.w(TAG, "BluetoothGAtt not initialized");

            WritableMap error = Arguments.createMap();
            error.putInt("erroCode", -1);
            error.putString("errorMessage", "BluetoothGatt not initialized.");
            params.putMap("error", error);

        } else {
            bluetoothGatt.disconnect();
        }
        connectionState = STATE_DISCONNECTED;
        this.sendEvent("ble.disconnect.", params);
    }

    @ReactMethod
    public void connect(final String peripheralUuid) { //in android peripheralUuid is the mac address of the BLE device
        Log.d(TAG, "RNBLE Connect called");
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
/*        if (bluetoothDeviceAddress != null && peripheralUuid.equalsIgnoreCase(bluetoothDeviceAddress)
                && bluetoothGatt != null) {
            Log.d(TAG, "Trying to use an existing bluetoothGatt for connection.");
            if (bluetoothGatt.connect()) {
                connectionState = STATE_CONNECTING;
                return;
            }
        }
*/
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
        closeGatt();
        openGatt(device);
        Log.d(TAG, "Trying to create a new connection.");
        bluetoothDeviceAddress = peripheralUuid;
        connectionState = STATE_CONNECTING;
    }

    @ReactMethod
    public void discoverServices(final String peripheralUuid, ReadableArray uuids){
        Log.d(TAG, "discoverServices");
        WritableArray filteredServiceUuids = Arguments.createArray();

        if(bluetoothGatt != null && this.discoveredServices != null && uuids != null && uuids.size() > 0){
            //filter discovered services
            for(BluetoothGattService service : this.discoveredServices){
                String uuid = service.getUuid().toString();
                for(int i = 0; i < uuids.size(); i++){
                    if(uuid.equalsIgnoreCase(uuids.getString(i))){
                        filteredServiceUuids.pushString(toNobleUuid(uuid));
                    }
                }
            }
        } else if(uuids == null || uuids.size() == 0){
            //if no uuids are requested return all discovered service uuids
            for(BluetoothGattService service : this.discoveredServices){
                String uuid = service.getUuid().toString();
                filteredServiceUuids.pushString(toNobleUuid(uuid));
            }
        }
        
        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", peripheralUuid);
        params.putArray("serviceUuids", filteredServiceUuids);

        this.sendEvent("ble.servicesDiscover", params);
    }

    @ReactMethod
    public void discoverCharacteristics(final String peripheralUuid, final String serviceUuid, ReadableArray characteristicUuids){
        WritableArray requestedCharacteristics = Arguments.createArray();
        List<BluetoothGattCharacteristic> filteredCharacteristics = new ArrayList<BluetoothGattCharacteristic>(); 

        for(BluetoothGattService service : this.discoveredServices){
            String uuid = service.getUuid().toString();
            //filter requested service
            if(uuid != null && uuid.equalsIgnoreCase(serviceUuid)){      
                List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();

                //remove characteristics from the characteristics list based on requested characteristicUuids          
                if(characteristicUuids != null && characteristicUuids.size() > 0){
                    for(int i = 0; i <  characteristicUuids.size(); i++){                        
                        Iterator<BluetoothGattCharacteristic> iterator = characteristics.iterator();
                        while(iterator.hasNext()){
                            BluetoothGattCharacteristic characteristic = iterator.next();
                            if(characteristicUuids.getString(i).equalsIgnoreCase(characteristic.getUuid().toString())){
                                filteredCharacteristics.add(characteristic);
                                break;                                
                            }
                        }
                    }                    
                }

                //process characteristics 
                for(BluetoothGattCharacteristic c : filteredCharacteristics){
                    WritableArray properties = Arguments.createArray();
                    int propertyBitmask = c.getProperties();

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_BROADCAST) != 0){
                        properties.pushString("boradcast");
                    }

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_READ) != 0){
                        properties.pushString("read");
                    }

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0){
                        properties.pushString("writeWithoutResponse");
                    }

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_WRITE) != 0){
                        properties.pushString("write");
                    }

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0){
                       properties.pushString("notify");
                    }                                                

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0){
                        properties.pushString("indicaste");
                    }

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_SIGNED_WRITE) != 0){
                        properties.pushString("authenticatedSignedWrites");
                    }

                    if((propertyBitmask & BluetoothGattCharacteristic.PROPERTY_EXTENDED_PROPS) != 0){
                        properties.pushString("extendedProperties");
                    }

                    WritableMap characteristicObject = Arguments.createMap();
                    characteristicObject.putArray("properties", properties);
                    characteristicObject.putString("uuid", toNobleUuid(c.getUuid().toString()));

                    requestedCharacteristics.pushMap(characteristicObject);
                }
            break;    
            }
        }

        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", peripheralUuid);
        params.putString("serviceUuid", toNobleUuid(serviceUuid));
        params.putArray("characteristics", requestedCharacteristics);
        this.sendEvent("ble.characteristicsDiscover", params);
    }

    @ReactMethod
    public void discoverDescriptors(final String peripheralUuid, final String serviceUuid, final String characteristicUuid){
        WritableArray descriptors = Arguments.createArray();

        for(BluetoothGattService service : this.discoveredServices){
            String uuid = service.getUuid().toString();
            //filter requested service
            if(uuid != null && uuid.equalsIgnoreCase(serviceUuid)){      
                List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
                for(BluetoothGattCharacteristic characteristic : characteristics){
                    String cUuid = characteristic.getUuid().toString();
                    if(cUuid != null && cUuid.equalsIgnoreCase(characteristicUuid)){
                        List<BluetoothGattDescriptor> descriptorList = characteristic.getDescriptors();
                        for(BluetoothGattDescriptor descriptor : descriptorList){
                            descriptors.pushString(descriptor.getUuid().toString());
                        }
                        break;
                    }
                }
            break;
            }
        }

        WritableMap params = Arguments.createMap();
        params.putString("peripheralUuid", peripheralUuid);
        params.putString("serviceUuid", toNobleUuid(serviceUuid));
        params.putString("characteristicUuid", toNobleUuid(characteristicUuid));
        params.putArray("descriptors", descriptors);
        this.sendEvent("ble.descriptorsDiscover", params);
    }

    final static UUID UUID_CLIENT_CHARACTERISTIC_CONFIG = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    @ReactMethod
    public void notify(String peripheralUuid, String serviceUuid, String characteristicUuid, Boolean notify){
        if(mHandler!=null){
            Log.e(TAG,"add new notify job in queue for char :"+characteristicUuid);
            Message message = mHandler.obtainMessage(NOTIFY);
            Bundle data = new Bundle();
            data.putString("peripheralUuid",peripheralUuid);
            data.putString("serviceUuid",serviceUuid);
            data.putString("characteristicUuid",characteristicUuid);
            data.putBoolean("notify",notify);
            message.setData(data);
            message.sendToTarget();
        }
    }

    @ReactMethod
    public void read(String peripheralUuid, String serviceUuid, String characteristicUuid){
        if(mHandler!=null){
            Log.e(TAG,"add new read job in queue for char :"+characteristicUuid);
            Message message = mHandler.obtainMessage(READ);
            Bundle data = new Bundle();
            data.putString("peripheralUuid",peripheralUuid);
            data.putString("serviceUuid",serviceUuid);
            data.putString("characteristicUuid",characteristicUuid);
            message.setData(data);
            message.sendToTarget();
        }
    }

    @ReactMethod
    public void write(String deviceUuid,String serviceUuid,String characteristicUuid,String data, Boolean withoutResponse){
        if(mHandler!=null){
            Log.e(TAG,"add new write job in queue for char :"+characteristicUuid);
            Message message = mHandler.obtainMessage(WRITE);
            Bundle bundle = new Bundle();
            bundle.putString("peripheralUuid",deviceUuid);
            bundle.putString("serviceUuid",serviceUuid);
            bundle.putString("characteristicUuid",characteristicUuid);
            bundle.putString("data",data);
            bundle.putBoolean("withoutResponse",withoutResponse);
            message.setData(bundle);
            message.sendToTarget();
        }
    }

    @Override
    public void onHostResume() {
        Log.d(TAG, "onHostResume");
        handlerThread = new HandlerThread("SubscriptionThread");
        handlerThread.start();

        // Create a handler attached to the HandlerThread's Looper
        mHandler = new RnbleOperationHandler(handlerThread.getLooper(),this);
    }

    @Override
    public void onHostPause() {
        Log.v(TAG, "onHostPause");
        stopScanning();

        /*if (bluetoothGatt != null) {
            bluetoothGatt.disconnect();
            bluetoothGatt.close();
            bluetoothGatt = null;
            connectionState = STATE_DISCONNECTED;
        }*/
        if(handlerThread!=null){
            handlerThread.quit();
            handlerThread = null;
            if(mHandler!=null){
                mHandler = null;
            }
        }
    }

    @Override
    public void onHostDestroy() {
        Log.v(TAG, "onHostDestroy");
        if (bluetoothGatt != null) {
            bluetoothGatt.disconnect();
            bluetoothGatt.close();
            bluetoothGatt = null;
            connectionState = STATE_DISCONNECTED;
        }
    }

    public boolean isDuplicateDevice(String address){
        boolean isDuplicate = false;
        if(address!=null) {
            for (String s : scannedDeviceAddresses) {
                if (s.equals(address)) {
                    isDuplicate = true;
                    break;
                }
            }
        }
        return isDuplicate;
    }

    public void addScannedDevice(String address){
        scannedDeviceAddresses.add(address);
    }

    public void setConnectionState(int state){
        if(state>=0 && state <=2)
            this.connectionState = state;
    }

    public void openGatt(BluetoothDevice device){
        bluetoothGatt = device.connectGatt(context, false, gattCallback);
    }

    public void closeGatt(){
        if(bluetoothGatt != null){
            bluetoothGatt.close();
            bluetoothGatt = null;
        }
    }

    public void discoverServices(){
        if(bluetoothGatt!=null){
            bluetoothGatt.discoverServices();
        }
    }

    public void sendEvent(String eventName, WritableMap params) {
        getReactApplicationContext()
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }

    private List<ScanFilter> buildScanFilters() {
        List<ScanFilter> scanFilters = new ArrayList<>();

        ScanFilter.Builder builder = new ScanFilter.Builder();        
        for(int i = 0; i < this.serviceUuids.size(); i++){
            builder.setServiceUuid(ParcelUuid.fromString(this.serviceUuids.getString(i)));
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

     public String toNobleUuid(String uuid) {
        String result = uuid.replaceAll("[\\s\\-()]", "");
        return result.toLowerCase();
     }

     public void setDiscoveredServices(){
         this.discoveredServices = bluetoothGatt.getServices();
     }


    // Some devices reuse UUIDs across characteristics, so we can't use service.getCharacteristic(characteristicUUID)
    // instead check the UUID and properties for each characteristic in the service until we find the best match
    // This function prefers Notify over Indicate
    private BluetoothGattCharacteristic findNotifyCharacteristic(BluetoothGattService service, String characteristicUUID) {
        BluetoothGattCharacteristic characteristic = null;

        try {
            // Check for Notify first
            List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
            for (BluetoothGattCharacteristic c : characteristics) {
                if(c == null)
                    continue;
                String cUuid = c.getUuid().toString();
                if (characteristicUUID.equalsIgnoreCase(cUuid)) {
                    if(((c.getProperties() & BluetoothGattCharacteristic.PROPERTY_NOTIFY) !=0) ||
                            ((c.getProperties() & BluetoothGattCharacteristic.PROPERTY_INDICATE) !=0)
                            )
                    characteristic = c;
                    break;
                }
            }

            if (characteristic != null) return characteristic;

            // As a last resort, try and find ANY characteristic with this UUID, even if it doesn't have the correct properties
            if (characteristic == null) {
                characteristic = service.getCharacteristic(UUID.fromString(characteristicUUID));
            }

            return characteristic;
        }catch (Exception e) {
            Log.e(TAG, "Errore su caratteristica " + characteristicUUID ,e);
            return null;
        }
    }

    public void processNotify(String peripheralUuid, String serviceUuid, String characteristicUuid, boolean notify){
        Log.e(TAG,"process new notify job from queue for char :"+characteristicUuid);
        try {
            if (bluetoothGatt == null) {
                throw new Exception("BluetoothGatt instance is null");
            }
            BluetoothGattService service = bluetoothGatt.getService(UUID.fromString(serviceUuid));
            if (service == null) {
                throw new Exception("Service not found");
            }
            BluetoothGattCharacteristic characteristic = findNotifyCharacteristic(service,characteristicUuid);
            if(characteristic == null){
                throw new Exception("Notify characteristics not found");
            }

            if(bluetoothGatt.setCharacteristicNotification(characteristic, notify)){
                BluetoothGattDescriptor descriptor = characteristic.getDescriptor(UUID_CLIENT_CHARACTERISTIC_CONFIG);
                if(descriptor == null) {
                    throw new Exception("Descriptor 0x2902 not found");
                }
                boolean notifyFlag = false;
                if(((characteristic.getProperties() & BluetoothGattCharacteristic.PROPERTY_NOTIFY) !=0)){
                    notifyFlag = true;
                    descriptor.setValue(notify ? BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE : BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
                } else{
                    descriptor.setValue(notify ? BluetoothGattDescriptor.ENABLE_INDICATION_VALUE : BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
                }

                boolean result = bluetoothGatt.writeDescriptor(descriptor);
                if(result) {
                    if(notifyFlag){
                        Log.i(TAG,"Notification enabled for "+ characteristicUuid);
                    } else{
                        Log.i(TAG,"Indication enabled for "+ characteristicUuid);
                    }
                    WritableMap params = Arguments.createMap();
                    params.putString("peripheralUuid", peripheralUuid);
                    params.putString("serviceUuid", toNobleUuid(serviceUuid));
                    params.putString("characteristicUuid", toNobleUuid(characteristicUuid));
                    params.putBoolean("state", notify);
                    this.sendEvent("ble.notify", params);
                } else{
                    throw new Exception("Can not write descriptor 0x2902 value");
                }
            } else{
                throw new Exception("Can not enable/disable notification for characteristics "+characteristicUuid);
            }

        }catch (Exception e){
            Log.e(TAG,"NotifyError",e);
        }
    }

    public void processRead(String peripheralUuid, String serviceUuid, String characteristicUuid){
        Log.e(TAG,"process new read job from queue for char :"+characteristicUuid);
        for(BluetoothGattService service : this.discoveredServices){
            String uuid = service.getUuid().toString();
            //find requested service
            if(uuid != null && uuid.equalsIgnoreCase(serviceUuid)){
                List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
                //find requested characteristic
                for(BluetoothGattCharacteristic characteristic : characteristics){
                    String cUuid = characteristic.getUuid().toString();
                    if(cUuid != null && cUuid.equalsIgnoreCase(characteristicUuid)){
                        if(bluetoothGatt != null) {
                            Log.d(TAG, "Reading data from BLE characteristic");
                            if(!bluetoothGatt.readCharacteristic(characteristic)){
                                Log.e(TAG, "Error initating BLE read operation.");
                            }
                        }
                        break;
                    }
                }
                break;
            }
        }
    }

    public void processWrite(String deviceUuid,String serviceUuid,String characteristicUuid,String data, Boolean withoutResponse){
        Log.e(TAG,"process new write job from queue for char :"+characteristicUuid);
        for(BluetoothGattService service : this.discoveredServices){
            String uuid = service.getUuid().toString();
            //find requested service
            if(uuid != null && uuid.equalsIgnoreCase(serviceUuid)){
                List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
                //find requested characteristic
                for(BluetoothGattCharacteristic characteristic : characteristics){
                    String cUuid = characteristic.getUuid().toString();
                    if(cUuid != null && cUuid.equalsIgnoreCase(characteristicUuid)){
                        if(bluetoothGatt != null) {
                            Log.d(TAG, "Writing data to BLE characteristic");
                            //set new data to characteristic
                            if(withoutResponse){
                                characteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
                            } else {
                                characteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT); // TODO: not tested
                            }
                            byte[] bArr = Base64.decode(data, Base64.DEFAULT);
                            Log.d(TAG, "bArr: " + Arrays.toString(bArr) + "\n" + " bArr length: " + bArr.length);
                            characteristic.setValue(bArr);
                            //write the data to the characterustic
                            if(!bluetoothGatt.writeCharacteristic(characteristic)){
                                Log.e(TAG, "Error initating BLE write operation.");
                            }
                        }
                        break;
                    }
                }
                break;
            }
        }
    }
}
