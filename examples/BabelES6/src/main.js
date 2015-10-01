/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');

var {
  AppRegistry,
  Text,
  View
} = React;

// react native ble is brought in via webpack as noble so it can be used
// with the community of node ble packages that already exist
var noble = require('noble');

var bleqr = React.createClass({
  componentWillMount: function(){
    // The startup 'onstatechange' is not currently caught sadly, see
    // https://github.com/jacobrosenthal/react-native-ble/issues/1
    noble.startScanning();
    noble.on('stateChange', this._onStateChange);
    noble.on('discover', this._onPeripheralFound);
  },

  componentWillUnMount: function(){
    noble.stopScannning();
  },

  render: function() {
    return (
      <View>
      </View>
    );
  },

  _onStateChange: function(state) {
    console.log('_onStateChange', state);
    if (state === 'poweredOn') {
      noble.startScanning();
    } else {
      noble.stopScanning();
    }
  },

  _onPeripheralFound: function(peripheral) {

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
  }

});

AppRegistry.registerComponent('BabelES6', () => bleqr);
