/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';
import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

var EddystoneBeaconScanner = require('eddystone-beacon-scanner');

class eddystone_beacon_scanner extends Component {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native!
        </Text>
        <Text style={styles.instructions}>
          To get started, edit index.ios.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for dev menu
        </Text>
      </View>
    );
  }

  componentWillMount() {
    EddystoneBeaconScanner.on('found', this._onFound);
    EddystoneBeaconScanner.on('updated', this._onUpdated);
    EddystoneBeaconScanner.on('lost', this._onLost);
    EddystoneBeaconScanner.startScanning(true);
  }

  _onFound(beacon) {
    console.log('found Eddystone Beacon:\n', JSON.stringify(beacon, null, 2));
  }

  _onLost(beacon)  {
    console.log('lost Eddystone beacon:\n', JSON.stringify(beacon, null, 2));
  }

  _onUpdated(beacon) {
    console.log('updated Eddystone Beacon:\n', JSON.stringify(beacon, null, 2));
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  }
});

AppRegistry.registerComponent('eddystone_beacon_scanner', () => eddystone_beacon_scanner);
