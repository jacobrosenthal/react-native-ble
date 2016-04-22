package com.maximejunger.react;

import java.util.UUID;

/**
 * Project - android - BluetoothUUIDHelper
 * Created by Maxime JUNGER - junger_m on 21/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class BluetoothUUIDHelper {

    // Bluetooth Base ID
    public static final long BT_UUID_LOWER_BITS = 0x800000805F9B34FBl;
    public static final long BT_UUID_UPPER_BITS = 0x1000;

    /**
     * Long UUID String to short. Extracts the service UUID
     * @param data to get
     * @return data
     */
    static public String longUUIDToShort(String data) {

        String res = "";

        for (int i = 4; i < 8; i++) {
            res += data.charAt(i);
        }

        return res;
    }

    /**
     * Short UUID to long. Combine the service UUID to the bluetooth base UUID.
     * @param service uuid service
     * @return UUID generated
     */
    static public UUID shortUUIDToLong(String service) {

        long serviceLong = Long.parseLong(service, 16);

        return new UUID(BT_UUID_UPPER_BITS + (serviceLong << 32), BT_UUID_LOWER_BITS);
    }
}
