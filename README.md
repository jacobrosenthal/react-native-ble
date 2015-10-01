# react-native-ble

Central role ble for react native. Technically a shim for the excellent [noble](https://github.com/sandeepmistry/noble/) Only supports scanning advertisements currently. Ive successfully tested [wimoto](https://github.com/sandeepmistry/node-wimoto) and [eddystone-beacon-scanner](https://github.com/sandeepmistry/node-eddystone-beacon-scanner/) on top of of this require.

#install
The depenency story on react native is still very incomplete so bear with me. From your existing react native project:
```
npm i --save react-native-ble
```
Next see the [react native linking guide](https://facebook.github.io/react-native/docs/linking-libraries.html) for visual instructions, but you need to open your project and from node_modules/react-native-estimote drag RNBLE.xcodeproj into your project file browser under Libraries. Next navigate to your top level project and for your main target, click Build Phases and drag the RNBLE.a Product into the Link Binary With Libraries section. 

#use
See the [noble](https://github.com/sandeepmistry/noble/) api for usage
```
var noble = ('react-native-ble');
```

#exmaple
See the example which utilizes the preferred method of using this module, aliased via webpack, allowing you you to utilize the existing ecosystem that already exists.