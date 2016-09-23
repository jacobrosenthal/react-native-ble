# react-native-ble

Central role ble for react native. Technically a shim for the excellent [noble](https://github.com/sandeepmistry/noble/) 

#install
```
npm i --save react-native-ble
```
For ios also see the [react native linking guide](https://facebook.github.io/react-native/docs/linking-libraries-ios.html), but basically
```
npm install rnpm -g
rnpm link
```
For android also see https://facebook.github.io/react-native/docs/native-modules-android.html#register-the-module in the paragraph starting "The package needs to be provided..." for the required edits to getPackages() in MainApplication.java.

#use
See the [noble](https://github.com/sandeepmistry/noble/) api for usage
```
var noble = ('react-native-ble');
```

For more advanced usage, like in the eddystone_beacon_scanner, include noble directly or utilize a package that does so:
```
var noble = ('noble');
```
And follow the instructions in [rn-nodeify](https://github.com/mvayngrib/rn-nodeify) to deep shim react-native-ble for noble. 