/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

var noble = require('react-native-ble');

class advertisement_discovery extends Component {
  constructor(){
    super();
    this.state = {
      devices: [],
    };
  }

  render() {
    const { devices } = this.state;

    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to Advertisement Scanning
        </Text>
        <Text style={styles.instructions}>
          Devices Scanned [{devices.length}]
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for npm dev menu
        </Text>

        <View style={{ marginTop: 25 }}>
          {devices.length ?
            devices.map((device, key) => <View key={key} style={{ borderColor: 'black', borderWidth: 1 }} ><Text onPress={this._handleDeviceClick.bind(this, device)}>Connect to {device.uuid}</Text></View>) : null
          }
        </View>
      </View>
    );
  }

  componentWillMount() {
    noble.on('stateChange', this._onStateChange);
    noble.on('discover', this._onDiscover);
  }

  _handleDeviceClick = (device) =>{
    device.connect((error) => {
      console.log(error);
      console.log('made it');
    })
  }

  _onStateChange = (state) => {
    if (state === 'poweredOn') {
      noble.startScanning([], true);
    } else {
      noble.stopScanning();
    }
  }

  _onDiscover = (peripheral) => {
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
    this.setState({
      devices: [...this.state.devices, peripheral],
    });
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});


AppRegistry.registerComponent('advertisement_discovery', () => advertisement_discovery);
