var debug = require('debug')('ios-bindings');

var util = require('util');
var events = require('events');

var Buffer = require('buffer').Buffer;
var NativeEventEmitter = require('react-native').NativeEventEmitter;

/**
 *  NobleBindings for react native
 */
var NobleBindings = function() {

  this.RNBLE = null;
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

NobleBindings.prototype.onRead = function(message) {
  var processedData = new Buffer(message.data);

  this.emit('data', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, processedData, message.isNotification);
  this.emit('read', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, processedData, message.isNotification);
};

NobleBindings.prototype.onWrite = function(message) {
  this.emit('write', message.peripheralUuid, message.serviceUuid, message.characteristicUuid);
};

NobleBindings.prototype.onValueWrite = function(message) {
  var processedData = new Buffer(message.data, 'base64');

  this.emit('valueWrite', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.descriptorUuid);
};

NobleBindings.prototype.onValueUpdate = function(message) {
  this.emit('valueRead', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.descriptorUuid, message.data);
};

NobleBindings.prototype.onNotify = function(message) {
  this.emit('notify', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.state);
};

NobleBindings.prototype.onDiscover = function(message) {
  debug('peripheral ' + message.uuid + ' discovered');

  if (message.advertisement.manufacturerData) {
  message.advertisement.manufacturerData = new Buffer(message.advertisement.manufacturerData, 'base64');
  }

  if (message.advertisement.serviceData) {
  message.advertisement.serviceData = message.advertisement.serviceData.map((ad) => ({
    uuid: toNobleUuid(ad.uuid),
    data: new Buffer(ad.data, 'base64'),
  }));
  }

  // We don't know these values because iOS doesn't want to give us
  // this information. Only random UUIDs are generated from them
  // under the hood
  var address = 'unknown';
  var addressType = 'unknown';

  this.emit('discover', toNobleUuid(message.uuid), address, addressType, message.connectable, message.advertisement, message.rssi);
};

NobleBindings.prototype.onStateChange = function(stateEvent) {
  // var state = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'][args.kCBMsgArgState];
  debug('state change ' + stateEvent.state);
  this.emit('stateChange', stateEvent.state);
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

  this.RNBLE.startScanning(toAppleUuids(serviceUuids), { allowDuplicates: duplicates });
  this.emit('scanStart');
};

/**
 * Stop scanning
 *
 * @discussion tested
 */
nobleBindings.stopScanning = function() {
  this.RNBLE.stopScanning();
  this.emit('scanStop');
};

nobleBindings.init = function(native) {

  if(native) {
    this.RNBLE = native.RNBLE;
    this.DeviceEventEmitter = native.DeviceEventEmitter;
  }else {
    this.RNBLE = require('react-native').NativeModules.BLEManager;

    // Initialize the BLEManager module
    this.RNBLE.createManager();

    // Register that this will have an event emitter.
    this.DeviceEventEmitter = new NativeEventEmitter(this.RNBLE);
  }

  this.DeviceEventEmitter.addListener('connectEvent', this.onConnect.bind(this));
  this.DeviceEventEmitter.addListener('disconnectEvent', this.onDisconnect.bind(this));
  this.DeviceEventEmitter.addListener('discoverEvent', this.onDiscover.bind(this));
  this.DeviceEventEmitter.addListener('rssiUpdateEvent', this.onRssiUpdate.bind(this));
  this.DeviceEventEmitter.addListener('servicesDiscoverEvent', this.onServicesDiscover.bind(this));
  this.DeviceEventEmitter.addListener('includedServicesDiscoverEvent', this.onIncludedServicesDiscover.bind(this));
  this.DeviceEventEmitter.addListener('characteristicsDiscoverEvent', this.onCharacteristicsDiscover.bind(this));
  this.DeviceEventEmitter.addListener('descriptorsDiscoverEvent', this.onDescriptorsDiscover.bind(this));
  this.DeviceEventEmitter.addListener('stateChangeEvent', this.onStateChange.bind(this));

  // Characteristic Operations
  this.DeviceEventEmitter.addListener('readEvent', this.onRead.bind(this))
  this.DeviceEventEmitter.addListener('writeEvent', this.onWrite.bind(this));
  this.DeviceEventEmitter.addListener('notifyEvent', this.onNotify.bind(this));

  // Descriptor operations
  this.DeviceEventEmitter.addListener('valueReadEvent', this.onValueUpdate.bind(this));
  this.DeviceEventEmitter.addListener('valueWriteEvent', this.onValueWrite.bind(this));
};

nobleBindings.connect = function(deviceUuid, options) {
  this.RNBLE.connect(toAppleUuid(deviceUuid), options);
};

nobleBindings.disconnect = function(deviceUuid) {
  this.RNBLE.disconnect(toAppleUuid(deviceUuid));
};

nobleBindings.updateRssi = function(deviceUuid) {
  this.RNBLE.updateRssi(toAppleUuid(deviceUuid));
};

nobleBindings.discoverServices = function(deviceUuid, uuids) {
  this.RNBLE.discoverServices(toAppleUuid(deviceUuid), toAppleUuids(uuids));
};

nobleBindings.discoverIncludedServices = function(deviceUuid, serviceUuid, serviceUuids) {
  this.RNBLE.discoverIncludedServices(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuids(serviceUuids));
};

nobleBindings.discoverCharacteristics = function(deviceUuid, serviceUuid, characteristicUuids) {
  this.RNBLE.discoverCharacteristics(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuids(characteristicUuids));
};

nobleBindings.read = function(deviceUuid, serviceUuid, characteristicUuid) {
  this.RNBLE.read(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid));
};

nobleBindings.write = function(deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse) {
  this.RNBLE.write(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid), data.toString(), withoutResponse);
};

nobleBindings.notify = function(deviceUuid, serviceUuid, characteristicUuid, notify) {
  this.RNBLE.notify(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid), notify);
};

nobleBindings.discoverDescriptors = function(deviceUuid, serviceUuid, characteristicUuid) {
  this.RNBLE.discoverDescriptors(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid));
};

nobleBindings.readValue = function(deviceUuid, serviceUuid, characteristicUuid, descriptorUuid) {
  this.RNBLE.readValue(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid), toAppleUuid(descriptorUuid));
};

nobleBindings.writeValue = function(deviceUuid, serviceUuid, characteristicUuid, descriptorUuid, data) {
  this.RNBLE.writeValue(toAppleUuid(deviceUuid), toAppleUuid(serviceUuid), toAppleUuid(characteristicUuid), toAppleUuid(descriptorUuid), data.toString(), withoutResponse);
};

nobleBindings.readHandle = function(deviceUuid, handle) {
  throw new Error('readHandle not implemented on ios');
};

nobleBindings.writeHandle = function(deviceUuid, handle, data, withoutResponse) {
  throw new Error('writeHandle not implemented on ios');
};

function toNobleUuid(uuid) {
  return uuid.split('-').join('');
}

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
