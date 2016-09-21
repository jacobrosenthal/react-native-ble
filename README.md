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

#use
See the [noble](https://github.com/sandeepmistry/noble/) api for usage
```
var noble = ('react-native-ble');
```

For more advanced usage, like in the example, utilize my react-native fork with deep dependency resovling, https://github.com/jacobrosenthal/react-native/tree/deepshim
```
var noble = ('noble');
```
And in your package.json resolve noble to react native
```
  "react-native": {
    "noble": "react-native-ble"
  },
```
This way you can shim all dependencies that might have been looking for noble too.