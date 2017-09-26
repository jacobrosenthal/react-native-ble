package com.geniem.rnble;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

/**
 * Created by Surajit Sarkar on 26/9/17.
 * Company : Bitcanny Technologies Pvt. Ltd.
 * Email   : surajit@bitcanny.com
 */

public class RnbleOperationHandler extends Handler {

    private RNBLEModule rnbleModule;
    private Object lock;

    public RnbleOperationHandler(Looper looper, RNBLEModule module){
        super(looper);
        this.rnbleModule = module;
        this.lock = module.getLock();
        Log.i(RNBLEModule.TAG,"RnbleOperationHandler Lock reference :" + lock);
    }

    @Override
    public void handleMessage(Message msg) {
        try {
            if (msg != null) {
                Bundle data = msg.getData();
                if (data == null)
                    return;
                synchronized (lock) {
                    String peripheralUuid, serviceUuid, characteristicUuid;
                    switch (msg.what) {
                        case RNBLEModule.READ:
                            peripheralUuid = data.getString("peripheralUuid", "");
                            serviceUuid = data.getString("serviceUuid", "");
                            characteristicUuid = data.getString("characteristicUuid", "");
                            rnbleModule.processRead(peripheralUuid, serviceUuid, characteristicUuid);
                            break;
                        case RNBLEModule.WRITE:
                            peripheralUuid = data.getString("peripheralUuid", "");
                            serviceUuid = data.getString("serviceUuid", "");
                            characteristicUuid = data.getString("characteristicUuid", "");
                            String str = data.getString("data", "");
                            boolean withoutResponse = data.getBoolean("withoutResponse", false);
                            rnbleModule.processWrite(peripheralUuid, serviceUuid, characteristicUuid, str, withoutResponse);
                            break;
                        case RNBLEModule.NOTIFY:
                            peripheralUuid = data.getString("peripheralUuid", "");
                            serviceUuid = data.getString("serviceUuid", "");
                            characteristicUuid = data.getString("characteristicUuid", "");
                            boolean notify = data.getBoolean("notify", false);
                            rnbleModule.processNotify(peripheralUuid, serviceUuid, characteristicUuid, notify);
                            break;
                    }
                    lock.wait();
                }
            }

        } catch (Exception e){
            Log.e(RNBLEModule.TAG,"handleMessage",e);
        }
    }
}
