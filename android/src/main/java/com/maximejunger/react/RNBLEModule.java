/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   18-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 18-04-2016
*/



package com.maximejunger.react;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

/**
 * Project - android - RNBLE
 * Created by Maxime JUNGER - junger_m on 18/04/16.
 * Email : maxime.junger@epitech.eu
 */

public class RNBLEModule extends ReactContextBaseJavaModule {

    public RNBLEModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNBLE";
    }
}
