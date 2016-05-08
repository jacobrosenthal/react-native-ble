var debug = require('debug')('android-bindings');

var events = require('events');
var util = require('util');

var {
  DeviceEventEmitter,
  NativeModules: { RNBLE },
} = require('react-native');

var Buffer = require('buffer').Buffer;

var NobleBindings = function() {
  DeviceEventEmitter.addListener('ble.stateChange', this.onStateChange.bind(this));
  DeviceEventEmitter.addListener('ble.discover', this.onDiscover.bind(this));
};

util.inherits(NobleBindings, events.EventEmitter);


NobleBindings.prototype.onStateChange = function(params) {
  // 'unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'
  debug('state change ' + params.state);
  this.emit('stateChange', params.state);
};

NobleBindings.prototype.onDiscover = function({ id, address, addressType, advertisement, connectable, rssi }) {
  /*
  if (advertisement.manufacturerData) {
    advertisement.manufacturerData = new Buffer(advertisement.manufacturerData, 'base64');
  }

  if (advertisement.serviceData) {
    advertisement.serviceData = advertisement.serviceData.map(({ uuid, data }) => ({
      uuid,
      data: new Buffer(data, 'base64'),
    }));
  } */

  this.emit('discover', id, address, addressType, connectable, advertisement, rssi);
};

var nobleBindings = new NobleBindings();

nobleBindings.init = function() {
  setTimeout(function() {
    RNBLE.getState();
  }, 1000);
};

nobleBindings.startScanning = function(serviceUuids, allowDuplicates) {
  var duplicates = allowDuplicates || false;
  RNBLE.startScanning(serviceUuids, duplicates);
  this.emit('scanStart');
};

nobleBindings.stopScanning = function() {
  RNBLE.stopScanning();
  this.emit('scanStop');
};

// Exports
module.exports = nobleBindings;

