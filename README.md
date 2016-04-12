<!--
@Author: Maxime JUNGER <junger_m>
@Date:   12-04-2016
@Email:  maximejunger@gmail.com
@Last modified by:   junger_m
@Last modified time: 12-04-2016
-->

# react-native-ble

## Author
Originaly forked from [Jacob Rosenthal](https://github.com/jacobrosenthal/react-native-ble)

## Installation

```
npm install git+https://git@github.com/Shakarang/react-native-ble
```
## Linking

Next see the [react native linking guide](https://facebook.github.io/react-native/docs/linking-libraries.html) for visual instructions, but you need to open your project and from node_modules/react-native-estimote drag RNBLE.xcodeproj into your project file browser under Libraries. Then, navigate to your top level project and for your main target, click Build Phases and drag the RNBLE.a Product into the Link Binary With Libraries section. Finally, click the plus button and add CoreBluetooth.framework as well.

## Usage

It follows the [noble](https://github.com/sandeepmistry/noble/) api usage.

Only support of following usages on iOS !

#### Require the module

```javascript
var noble = ('react-native-ble');
```

#### Handle Bluetooth State

```javascript
noble.on('stateChange', function (state) {
  if (state === 'poweredOn') {
    console.log('Start Scanning');
    noble.startScanning([], false);
  } else {
    noble.stopScanning();
    console.log('Stop Scanning');
  }
});
```

#### Start Scanning

```javascript
noble.on('discover', function (peripheral) {
  // Peripheral is an object that was found
});

```

### Peripheral

#### Connect
```javascript
peripheral.connect(function (error) {

});
```

#### disconnect

When you're connected to a peripheral, you can handle the automatic disconnection by doing :
```javascript
peripheral.once('disconnect', function () {

});

If you want to disconnect manually :
```javascript
peripheral.disconnect(function (error) {

});
```

#### Discover Services
```javascript
var serviceUUIDs = ["<service UUID 1>", ...];
peripheral.discoverServices(serviceUUIDs, function (error, services) {

});
```

### Service
#### Discover characteristics
```javascript
var service = services[0];
var characteristicsUUIDs = ["<service UUID 1>", ...];
service.discoverCharacteristics(characteristicsUUIDs, function (characteristics) {

});
```
### Characteristic

#### Read
```javascript
var characteristic = characteristics[0];
characteristic.read(function (data) {
  // Data is a buffer
});
```

#### Notify
```javascript
var characteristic = characteristics[0];
characteristic.notify(function (data) {
  // Data is a buffer
});
```
