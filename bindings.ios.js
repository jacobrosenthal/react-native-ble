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
};

util.inherits(NobleBindings, events.EventEmitter);

NobleBindings.prototype.onConnect = function({ peripheralUuid, error = null }) {
  this.emit('connect', peripheralUuid, error);
};

NobleBindings.prototype.onDisconnect = function({ peripheralUuid, error = null }) {
  this.emit('disconnect', peripheralUuid, error);
};

NobleBindings.prototype.onRssiUpdate = function({ peripheralUuid, rssi }) {
  this.emit('rssiUpdate', peripheralUuid, rssi);
};

NobleBindings.prototype.onServicesDiscover = function({ peripheralUuid, serviceUuids }) {
  this.emit('servicesDiscover', peripheralUuid, serviceUuids);
};

NobleBindings.prototype.onIncludedServicesDiscover = function({ peripheralUuid, serviceUuid, includedServiceUuids }) {
  this.emit('includedServicesDiscover', peripheralUuid, serviceUuid, includedServiceUuids);
};

NobleBindings.prototype.onCharacteristicsDiscover = function({ peripheralUuid, serviceUuid, characteristics }) {
  this.emit(
    'characteristicsDiscover', 
    peripheralUuid, 
    serviceUuid, 
    characteristics
  );
};

NobleBindings.prototype.onDescriptorsDiscover = function({ peripheralUuid, serviceUuid, characteristicUuid, descriptors }) {
  this.emit('descriptorsDiscover', peripheralUuid, serviceUuid, characteristicUuid, descriptors);
};

NobleBindings.prototype.onData = function({ peripheralUuid, serviceUuid, characteristicUuid, data, isNotification }) {
  var processedData = new Buffer(data, 'base64');
  this.emit('data', peripheralUuid, serviceUuid, characteristicUuid, processedData, isNotification);
  this.emit('read', peripheralUuid, serviceUuid, characteristicUuid, processedData, isNotification);
};

NobleBindings.prototype.onWrite = function({ peripheralUuid, serviceUuid, characteristicUuid }) {
  this.emit('write', peripheralUuid, serviceUuid, characteristicUuid);
};

NobleBindings.prototype.onNotify = function({ peripheralUuid, serviceUuid, characteristicUuid, state }) {
  this.emit('notify', peripheralUuid, serviceUuid, characteristicUuid, state);
};

NobleBindings.prototype.onDiscover = function({ peripheralUuid, advertisement, connectable, rssi }) {
  debug('peripheral ' + peripheralUuid + ' discovered');

  if (advertisement.manufacturerData) {
    advertisement.manufacturerData = new Buffer(advertisement.manufacturerData, 'base64');
  }

  if (advertisement.serviceData) {
    advertisement.serviceData = advertisement.serviceData.map(({ uuid, data }) => ({
      uuid,
      data: new Buffer(data, 'base64'),
    }));
  }

  // We don't know these values because iOS doesn't want to give us 
  // this information. Only random UUIDs are generated from them 
  // under the hood
  var address = 'unknown';
  var addressType = 'unknown';

  this.emit('discover', peripheralUuid, address, addressType, connectable, advertisement, rssi);
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
  RNBLE.setup();
  RNBLE.getState();
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
  RNBLE.discoverCharacteristics(deviceUuid, serviceUuid);
};

nobleBindings.read = function(deviceUuid, serviceUuid, characteristicUuid) {
  RNBLE.read(deviceUuid, serviceUuid, characteristicUuid);
};

nobleBindings.write = function(deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse) {
  RNBLE.write(deviceUuid, serviceUuid, characteristicUuid, data.toString('base64'), withoutResponse);
};

nobleBindings.broadcast = function(deviceUuid, serviceUuid, characteristicUuid, broadcast) {
  throw new Error('broadcast not yet implemented');
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
  throw new Error('readHandle not yet implemented');
};

nobleBindings.writeHandle = function(deviceUuid, handle, data, withoutResponse) {
  throw new Error('writeHandle not yet implemented');
};

// Exports
module.exports = nobleBindings;