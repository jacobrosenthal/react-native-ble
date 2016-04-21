package com.maximejunger.react;

/**
 * Project - android - BluetoothUUIDHelper
 * Created by Maxime JUNGER - junger_m on 21/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class BluetoothUUIDHelper {

    static public String longUUIDToShort(String data) {

        String res = "";

        for (int i = 4; i < 8; i++) {
            res += data.charAt(i);
        }

        return res;
    }

}
