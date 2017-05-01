var debug = require('debug')('android-bindings');

var events = require('events');
var util = require('util');

var {
  DeviceEventEmitter,
  NativeModules: { RNBLE },
} = require('react-native');

var Buffer = require('buffer').Buffer;

var NobleBindings = function() {
  DeviceEventEmitter.addListener('ble.connect', this.onConnect.bind(this));
  DeviceEventEmitter.addListener('ble.disconnect', this.onDisconnect.bind(this));  
  DeviceEventEmitter.addListener('ble.stateChange', this.onStateChange.bind(this));
  DeviceEventEmitter.addListener('ble.discover', this.onDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.servicesDiscover', this.onServicesDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.includedServicesDiscover', this.onIncludedServicesDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.characteristicsDiscover', this.onCharacteristicsDiscover.bind(this));
  DeviceEventEmitter.addListener('ble.descriptorsDiscover', this.onDescriptorsDiscover.bind(this));
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

NobleBindings.prototype.onNotify = function({ peripheralUuid, serviceUuid, characteristicUuid, notifyState }) {
  this.emit('notify', peripheralUuid, serviceUuid, characteristicUuid, notifyState);
};

NobleBindings.prototype.onData = function({ peripheralUuid, serviceUuid, characteristicUuid, data, isNotification }) {
  let processedData = new Buffer(JSON.parse(data), 'base64');
  this.emit('data', peripheralUuid, serviceUuid, characteristicUuid, processedData, isNotification);
  this.emit('read', peripheralUuid, serviceUuid, characteristicUuid, processedData, isNotification);
};

NobleBindings.prototype.onStateChange = function(params) {
  // 'unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'
  debug('state change ' + params.state);
  this.emit('stateChange', params.state);
};

NobleBindings.prototype.onDiscover = function({ id, address, addressType, advertisement, connectable, rssi }) {  
  if (advertisement.manufacturerData) {
    advertisement.manufacturerData = new Buffer(JSON.parse(advertisement.manufacturerData), 'base64');
  }

  if (advertisement.serviceData) {
    advertisement.serviceData = advertisement.serviceData.map(({ uuid, data }) => ({
      uuid,
      data: new Buffer(JSON.parse(data), 'base64'),
    }));
  } 

  this.emit('discover', id, address, addressType, connectable, advertisement, rssi);
};

NobleBindings.prototype.onWrite = function({ peripheralUuid, serviceUuid, characteristicUuid }) {
  this.emit('write', peripheralUuid, serviceUuid, characteristicUuid);
};

var nobleBindings = new NobleBindings();

nobleBindings.init = function() {
  setTimeout(function() {
    RNBLE.getState();
  }, 1000);
};

nobleBindings.connect = function(deviceUuid) {
  RNBLE.connect(deviceUuid);
};

nobleBindings.disconnect = function(deviceUuid) {
  RNBLE.disconnect(deviceUuid);
};

nobleBindings.startScanning = function(serviceUuids, allowDuplicates) {
  var duplicates = allowDuplicates || false;
  let serviceUuid = serviceUuids ? serviceUuids.pop() : null;
  RNBLE.startScanning(toAppleUuids(serviceUuids), duplicates);
  this.emit('scanStart');
};

nobleBindings.stopScanning = function() {
  RNBLE.stopScanning();
  this.emit('scanStop');
};

nobleBindings.discoverServices = function(deviceUuid, uuids) {
  RNBLE.discoverServices(deviceUuid, toAppleUuids(uuids));
};

nobleBindings.discoverIncludedServices = function(deviceUuid, serviceUuid, serviceUuids) {
  throw new Error('discoverIncludedServices not yet implemented');
};

nobleBindings.discoverCharacteristics = function(deviceUuid, serviceUuid, characteristicUuids) {
  RNBLE.discoverCharacteristics(deviceUuid, toAppleUuid(serviceUuid), toAppleUuids(characteristicUuids));
};

nobleBindings.discoverDescriptors = function(deviceUuid, serviceUuid, characteristicUuid) {
  RNBLE.discoverDescriptors(deviceUuid, toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid));
};

nobleBindings.read = function(deviceUuid, serviceUuid, characteristicUuid) {
  RNBLE.read(deviceUuid, toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid));
};

nobleBindings.write = function(deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse) {
  RNBLE.write(deviceUuid, toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid), data.toString("base64"), withoutResponse);
};

nobleBindings.notify = function(deviceUuid, serviceUuid, characteristicUuid, notify) {
  RNBLE.notify(deviceUuid, toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid), notify);
};

function toAppleUuid(uuid) {
 return uuid.replace(/(\S{8})(\S{4})(\S{4})(\S{4})(\S{12})/, "$1-$2-$3-$4-$5").toUpperCase();
}

function toAppleUuids(uuids) {
  var convertedUuids = [];

  if (uuids) {
    uuids.forEach(function(uuid) {
      convertedUuids.push(toAppleUuid(uuid));
    });
  }

  return convertedUuids;
}

// Exports
module.exports = nobleBindings;