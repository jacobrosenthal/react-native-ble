var debug = require('debug')('ios-bindings');

var events = require('events');
var util = require('util');

var {
  DeviceEventEmitter,
  NativeModules: { RNBLE },
} = require('react-native');

var Buffer = require('buffer').Buffer;

/**
 *  NobleBindings for react native
 */
var NobleBindings = function() {

};

util.inherits(NobleBindings, events.EventEmitter);

NobleBindings.prototype.onConnect = function(message) {
  this.emit('connect', message.peripheralUuid, message.error);
};

NobleBindings.prototype.onDisconnect = function(message) {
  this.emit('disconnect', message.peripheralUuid);
};

NobleBindings.prototype.onRssiUpdate = function(message) {
  this.emit('rssiUpdate', message.peripheralUuid, message.rssi);
};

NobleBindings.prototype.onServicesDiscover = function(message) {
  this.emit('servicesDiscover', message.peripheralUuid, message.serviceUuids);
};


NobleBindings.prototype.onIncludedServicesDiscover = function(message) {
  this.emit('includedServicesDiscover', message.peripheralUuid, message.serviceUuid, message.includedServiceUuids);
};

NobleBindings.prototype.onCharacteristicsDiscover = function(message) {
  this.emit('characteristicsDiscover', message.peripheralUuid, message.serviceUuid, message.characteristics);
};

NobleBindings.prototype.onDescriptorsDiscover = function(message) {
  this.emit('descriptorsDiscover', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.descriptors);
};

NobleBindings.prototype.onData = function(message) {
  var processedData = new Buffer(message.data, 'base64');

  this.emit('data', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, processedData, message.isNotification);
  this.emit('read', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, processedData, message.isNotification);
};

NobleBindings.prototype.onWrite = function(message) {
  this.emit('write', message.peripheralUuid, message.serviceUuid, message.characteristicUuid);
};

NobleBindings.prototype.onNotify = function(message) {
  this.emit('notify', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.state);
};

NobleBindings.prototype.onDiscover = function(message) {
  debug('peripheral ' + message.peripheralUuid + ' discovered');

  if (message.advertisement.manufacturerData) {
  message.advertisement.manufacturerData = new Buffer(message.advertisement.manufacturerData, 'base64');
  }

  if (message.advertisement.serviceData) {
  message.advertisement.serviceData = message.advertisement.serviceData.map((ad) => ({
    uuid: ad.uuid,
    data: new Buffer(ad.data, 'base64'),
  }));
  }

  // We don't know these values because iOS doesn't want to give us 
  // this information. Only random UUIDs are generated from them 
  // under the hood
  var address = 'unknown';
  var addressType = 'unknown';

  this.emit('discover', message.peripheralUuid, address, addressType, message.connectable, message.advertisement, message.rssi);
};

NobleBindings.prototype.onStateChange = function(state) {
  // var state = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'][args.kCBMsgArgState];
  debug('state change ' + state);
  this.emit('stateChange', state);
};

var nobleBindings = new NobleBindings();

/**
 * Start scanning
 * @param  {Array} serviceUuids     Scan for these UUIDs, if undefined then scan for all
 * @param  {Bool}  allowDuplicates  Scan can return duplicates
 *
 * @discussion tested
 */
nobleBindings.startScanning = function(serviceUuids, allowDuplicates) {

  var duplicates = allowDuplicates || false;

  RNBLE.startScanning(serviceUuids, duplicates);
  this.emit('scanStart');
};

/**
 * Stop scanning
 *
 * @discussion tested
 */
nobleBindings.stopScanning = function() {
  RNBLE.stopScanning();
  this.emit('scanStop');
};

nobleBindings.init = function() {

  DeviceEventEmitter.addListener('ble.connect', this.onConnect.bind(this));
  DeviceEventEmitter.addListener('ble.disconnect', this.onDisconnect.bind(this));
  DeviceEventEmitter.addListener('ble.discover', this.onDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.rssiUpdate', this.onRssiUpdate.bind(this));
  DeviceEventEmitter.addListener('ble.servicesDiscover', this.onServicesDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.includedServicesDiscover', this.onIncludedServicesDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.characteristicsDiscover', this.onCharacteristicsDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.descriptorsDiscover', this.onDescriptorsDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.stateChange', this.onStateChange.bind(this));
  DeviceEventEmitter.addListener('ble.data', this.onData.bind(this));
  DeviceEventEmitter.addListener('ble.write', this.onWrite.bind(this));
  DeviceEventEmitter.addListener('ble.notify', this.onNotify.bind(this));

  setTimeout(function() {
  RNBLE.getState();
  }.bind(this), 1000);
};

nobleBindings.connect = function(deviceUuid) {
  RNBLE.connect(deviceUuid);
};

nobleBindings.disconnect = function(deviceUuid) {
  RNBLE.disconnect(deviceUuid);
};

nobleBindings.updateRssi = function(deviceUuid) {
  RNBLE.updateRssi(deviceUuid);
};

nobleBindings.discoverServices = function(deviceUuid, uuids) {
  RNBLE.discoverServices(deviceUuid, uuids);
};

nobleBindings.discoverIncludedServices = function(deviceUuid, serviceUuid, serviceUuids) {
  RNBLE.discoverIncludedServices(deviceUuid, serviceUuid, serviceUuids);
};

nobleBindings.discoverCharacteristics = function(deviceUuid, serviceUuid, characteristicUuids) {
  //TODO this isnt sending in characteristics??
  RNBLE.discoverCharacteristics(deviceUuid, serviceUuid);
};

nobleBindings.read = function(deviceUuid, serviceUuid, characteristicUuid) {
  RNBLE.read(deviceUuid, serviceUuid, characteristicUuid);
};

nobleBindings.write = function(deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse) {
  RNBLE.write(deviceUuid, serviceUuid, characteristicUuid, data.toString('base64'), withoutResponse);
};

nobleBindings.notify = function(deviceUuid, serviceUuid, characteristicUuid, notify) {
  RNBLE.notify(deviceUuid, serviceUuid, characteristicUuid, notify);
};

nobleBindings.discoverDescriptors = function(deviceUuid, serviceUuid, characteristicUuid) {
  RNBLE.discoverDescriptors(deviceUuid, serviceUuid, characteristicUuid);
};

nobleBindings.readValue = function(deviceUuid, serviceUuid, characteristicUuid, descriptorUuid) {
  throw new Error('readValue not yet implemented');
};

nobleBindings.writeValue = function(deviceUuid, serviceUuid, characteristicUuid, descriptorUuid, data) {
  throw new Error('writeValue not yet implemented');
};

nobleBindings.readHandle = function(deviceUuid, handle) {
  throw new Error('readHandle not implemented on ios');
};

nobleBindings.writeHandle = function(deviceUuid, handle, data, withoutResponse) {
  throw new Error('writeHandle not implemented on ios');
};


// Exports
module.exports = nobleBindings;