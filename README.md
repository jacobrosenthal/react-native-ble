# react-native-ble

Central role ble for react native. Technically a shim for the excellent [noble](https://github.com/sandeepmistry/noble/) 

#install
The depenency story on react native is still very incomplete so bear with me. From your existing react native project:
```
npm i --save react-native-ble
```
Next see the [react native linking guide](https://facebook.github.io/react-native/docs/linking-libraries.html) for visual instructions, but you need to open your project and from node_modules/react-native-estimote drag RNBLE.xcodeproj into your project file browser under Libraries. Then, navigate to your top level project and for your main target, click Build Phases and drag the RNBLE.a Product into the Link Binary With Libraries section. Finally, click the plus button and add CoreBluetooth.framework as well.

#use
See the [noble](https://github.com/sandeepmistry/noble/) api for usage
```
var noble = ('react-native-ble');
```

Better yet, as in the eddystone_beacon_scanner example, include noble directly or utilize a package that does so:
```
var noble = ('noble');
```
And follow the instructions in [rn-nodeify](https://github.com/mvayngrib/rn-nodeify) to deep shim react-native-ble for noble. 