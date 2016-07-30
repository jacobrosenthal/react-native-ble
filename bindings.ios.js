var debug = require('debug')('ios-bindings');

var util = require('util');
var events = require('events');

var Buffer = require('buffer').Buffer;

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

NobleBindings.prototype.onData = function(message) {
  var dataBuffer = new Buffer(message.data, 'base64');

  this.emit('data', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, dataBuffer, message.isNotification);
  this.emit('read', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, dataBuffer, message.isNotification);
};

NobleBindings.prototype.onWrite = function(message) {
  this.emit('write', message.peripheralUuid, message.serviceUuid, message.characteristicUuid);
};

NobleBindings.prototype.onValueWrite = function(message) {
  this.emit('valueWrite', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.descriptorUuid);
};

NobleBindings.prototype.onValueUpdate = function(message) {
  var dataBuffer = new Buffer(message.data, 'base64');

  this.emit('valueRead', message.peripheralUuid, message.serviceUuid, message.characteristicUuid, message.descriptorUuid, dataBuffer);
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

nobleBindings.startScanning = function(serviceIdentifierStringArray, allowDuplicates) {

  var duplicates = allowDuplicates || false;

  this.RNBLE.startScanning(toAppleIdentifiers(serviceIdentifierStringArray), duplicates);
  this.emit('scanStart');
};

nobleBindings.stopScanning = function() {
  this.RNBLE.stopScanning();
  this.emit('scanStop');
};

nobleBindings.init = function(native) {

  if(native) {
    this.RNBLE = native.RNBLE;
    this.DeviceEventEmitter = native.DeviceEventEmitter;
  }else {
    this.RNBLE = require('react-native').NativeModules.RNBLE;
    this.DeviceEventEmitter = require('react-native').DeviceEventEmitter;
  }

  this.DeviceEventEmitter.addListener('ble.connect', this.onConnect.bind(this));
  this.DeviceEventEmitter.addListener('ble.disconnect', this.onDisconnect.bind(this));
  this.DeviceEventEmitter.addListener('ble.discover', this.onDiscover.bind(this));
  this.DeviceEventEmitter.addListener('ble.rssiUpdate', this.onRssiUpdate.bind(this));
  this.DeviceEventEmitter.addListener('ble.servicesDiscover', this.onServicesDiscover.bind(this));
  this.DeviceEventEmitter.addListener('ble.includedServicesDiscover', this.onIncludedServicesDiscover.bind(this));
  this.DeviceEventEmitter.addListener('ble.characteristicsDiscover', this.onCharacteristicsDiscover.bind(this));
  this.DeviceEventEmitter.addListener('ble.descriptorsDiscover', this.onDescriptorsDiscover.bind(this));
  this.DeviceEventEmitter.addListener('ble.stateChange', this.onStateChange.bind(this));
  this.DeviceEventEmitter.addListener('ble.data', this.onData.bind(this));
  this.DeviceEventEmitter.addListener('ble.write', this.onWrite.bind(this));
  this.DeviceEventEmitter.addListener('ble.notify', this.onNotify.bind(this));
  this.DeviceEventEmitter.addListener('ble.valueUpdate', this.onValueUpdate.bind(this));
  this.DeviceEventEmitter.addListener('ble.valueWrite', this.onValueWrite.bind(this));

  setTimeout(function() {
  this.RNBLE.getState();
  }.bind(this), 1000);
};

nobleBindings.connect = function(peripheralIdentifierString) {
  this.RNBLE.connect(toAppleIdentifier(peripheralIdentifierString));
};

nobleBindings.disconnect = function(peripheralIdentifierString) {
  this.RNBLE.disconnect(toAppleIdentifier(peripheralIdentifierString));
};

nobleBindings.updateRssi = function(peripheralIdentifierString) {
  this.RNBLE.updateRssi(toAppleIdentifier(peripheralIdentifierString));
};

nobleBindings.discoverServices = function(peripheralIdentifierString, serviceIdentifierStringArray) {
  this.RNBLE.discoverServices(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifiers(serviceIdentifierStringArray));
};

nobleBindings.discoverIncludedServices = function(peripheralIdentifierString, serviceIdentifierString, serviceIdentifierStringArray) {
  this.RNBLE.discoverIncludedServices(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifiers(serviceIdentifierStringArray));
};

nobleBindings.discoverCharacteristics = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierStringArray) {
  this.RNBLE.discoverCharacteristics(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifiers(characteristicIdentifierStringArray));
};

nobleBindings.read = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierString) {
  this.RNBLE.read(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifier(characteristicIdentifierString));
};

nobleBindings.write = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierString, dataBuffer, withoutResponse) {
  this.RNBLE.write(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifier(characteristicIdentifierString), dataBuffer.toString('base64'), withoutResponse);
};

nobleBindings.notify = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierString, notify) {
  this.RNBLE.notify(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifier(characteristicIdentifierString), notify);
};

nobleBindings.discoverDescriptors = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierString) {
  this.RNBLE.discoverDescriptors(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifier(characteristicIdentifierString));
};

nobleBindings.readValue = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierString, descriptorIdentifierString) {
  this.RNBLE.readValue(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifier(characteristicIdentifierString), toAppleIdentifier(descriptorIdentifierString));
};

nobleBindings.writeValue = function(peripheralIdentifierString, serviceIdentifierString, characteristicIdentifierString, descriptorIdentifierString, dataBuffer) {
  this.RNBLE.writeValue(toAppleIdentifier(peripheralIdentifierString), toAppleIdentifier(serviceIdentifierString), toAppleIdentifier(characteristicIdentifierString), toAppleIdentifier(descriptorIdentifierString), dataBuffer.toString('base64'));
};

nobleBindings.readHandle = function(peripheralIdentifierString, handle) {
  throw new Error('readHandle not implemented on ios');
};

nobleBindings.writeHandle = function(peripheralIdentifierString, handle, dataBuffer, withoutResponse) {
  throw new Error('writeHandle not implemented on ios');
};


function toAppleIdentifier(identifier) {
 return identifier.replace(/(\S{8})(\S{4})(\S{4})(\S{4})(\S{12})/, "$1-$2-$3-$4-$5").toUpperCase();
}

function toAppleIdentifiers(identifiers) {
  var convertedIdentifiers = [];

  if (identifiers) {
    identifiers.forEach(function(identifier) {
      convertedIdentifiers.push(toAppleIdentifier(identifier));
    });
  }

  return convertedIdentifiers;
}


// Exports
module.exports = nobleBindings;