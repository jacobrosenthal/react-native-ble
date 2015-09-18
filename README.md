# react-native-ble

Only supports advertisements currently. Ive successfully tested [wimoto](https://github.com/sandeepmistry/node-wimoto) and [eddystone-beacon-scanner](https://github.com/sandeepmistry/node-eddystone-beacon-scanner/) on top of of this require.

#install
The depenency story on react native is still very incomplete so bear with me. From your existing react native project:
```
npm i --save react-native-ble
```
Next see the [react native linking guide](https://facebook.github.io/react-native/docs/linking-libraries.html) for visual instructions, but you need to open your project and from node_modules/react-native-estimote drag RNBLE.xcodeproj into your project file browser. Next navigate to your top level project and for your main target, click Build Phases and drag the RNBLE.a product into the Link Binary With Libraries section. 

Then click the + button at the bottom to add the CoreBluetooth Framework. 

#use
Just use instead of noble
```
var noble = require('react-native-ble');

See this example [index.ios.js](https://gist.github.com/jacobrosenthal/85bb514ade5b62d4b02a)
