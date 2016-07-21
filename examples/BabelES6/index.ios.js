/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';
import React, {
  AppRegistry,
  Component,
  StyleSheet,
  Text,
  View
} from 'react-native';

var noble = require('noble');

var bleqr = React.createClass({
  getInitialState: function(){
    return {heartRate:0}
  },

  componentWillMount: function(){
    noble.on('stateChange', this._onStateChange);
    noble.on('discover', this._onPeripheralFound);
  },

  componentWillUnMount: function(){
    noble.stopScannning();
  },

  render: function() {
    return (
      <View style={styles.container}>
        <Text>{this.state.heartRate}</Text>
      </View>
    );
  },

  _onStateChange: function(state) {
    if (state === 'poweredOn') {
      noble.startScanning(["180d"]);
    } else {
      noble.stopScanning();
    }
  },

  _onPeripheralFound: function(peripheral) {
    this._printPeripheral(peripheral);
    this._connectHeartRate(peripheral);
  },

  _printPeripheral: function(peripheral) {
    console.log('peripheral discovered (' + peripheral.id +
                ' with address <' + peripheral.address +  ', ' + peripheral.addressType + '>,' +
                ' connectable ' + peripheral.connectable + ',' +
                ' RSSI ' + peripheral.rssi + ':');
    console.log('\thello my local name is:');
    console.log('\t\t' + peripheral.advertisement.localName);
    console.log('\tcan I interest you in any of the following advertised services:');
    console.log('\t\t' + JSON.stringify(peripheral.advertisement.serviceUuids));

    var serviceData = peripheral.advertisement.serviceData;
    if (serviceData && serviceData.length) {
      console.log('\there is my service data:');
      for (var i in serviceData) {
        console.log('\t\t' + JSON.stringify(serviceData[i].uuid) + ': ' + JSON.stringify(serviceData[i].data.toString('hex')));
      }
    }
    if (peripheral.advertisement.manufacturerData) {
      console.log('\there is my manufacturer data:');
      console.log('\t\t' + JSON.stringify(peripheral.advertisement.manufacturerData.toString('hex')));
    }
    if (peripheral.advertisement.txPowerLevel !== undefined) {
      console.log('\tmy TX power level is:');
      console.log('\t\t' + peripheral.advertisement.txPowerLevel);
    }

    console.log();
  },

  _connectHeartRate: function(peripheral){

    const HEART_RATE_VALUE_FORMAT = 1;
    function parseHR (bytes) {
      //Check for data
      if (bytes.length == 0)
      {
          return 0;
      }

      //Get the first byte that contains flags
      var flag = bytes[0];

      //Check if u8 or u16 and get heart rate
      var hr;
      if ((flag & 0x01) == 1)
      {
          var u16bytes = bytes.buffer.slice(1, 3);
          var u16 = new Uint16Array(u16bytes)[0];
          hr = u16;
      }
      else
      {
          var u8bytes = bytes.buffer.slice(1, 2);
          var u8 = new Uint8Array(u8bytes)[0];
          hr = u8;
      }
      return hr;
    }

    var self = this;
    function print(data, notification){
      var heartRate = parseHR(data)
      console.log(heartRate);
      self.setState({
        heartRate:heartRate
      });
    }

    var characteristic;
    function notify(error, services, characteristics){
        console.log("discovered characteristics", services[0].uuid, characteristics[0].uuid);
        self.characteristic = characteristics[0];
        self.characteristic.notify(true);
        self.characteristic.on("data", print);
    };

    function disconnected(){
      console.log("disconnected");
      self.characteristic.removeListener('data', print);
      self._connectHeartRate(peripheral);
      self.setState({
        heartRate:0
      });
      noble.startScanning(["180d"]);
    };

    function discover(error){
        peripheral.once('disconnect', disconnected);
        console.log("connect", error);
        peripheral.discoverSomeServicesAndCharacteristics(["180d"], ["2a37"], notify);
    }
    peripheral.connect(discover);
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  }
});

AppRegistry.registerComponent('BabelES6', () => bleqr);
