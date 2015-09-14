var debug = require('debug')('ios-bindings');

var events        = require('events');
var util          = require('util');

var NativeRNBLE = require('NativeModules').RNBLE;
var React = require('react-native');
var {
  DeviceEventEmitter
} = React;

var Buffer = require('buffer').Buffer;


/**
 *  NobleBindings for react native
 */
var NobleBindings = function() {
  DeviceEventEmitter.addListener('discover', this.onDiscover.bind(this));
  DeviceEventEmitter.addListener('stateChange', this.onStateChange.bind(this));
};

util.inherits(NobleBindings, events.EventEmitter);


NobleBindings.prototype.onDiscover = function (args, advertisementData, rssi) {
  if (Object.keys(args.kCBMsgArgAdvertisementData).length === 0) {
    return;
  }

  var serviceDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData, 'base64');

  var manufacturerDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataManufacturerData, 'base64');
  if(manufacturerDataBuffer.length===0){
    manufacturerDataBuffer = undefined;
  }

  var txPowerLevel = args.kCBMsgArgAdvertisementData.kCBAdvDataTxPowerLevel;
  if(txPowerLevel===''){
    txPowerLevel = undefined;
  }

  // todo need to lower case and remove dashes
  var serviceUuids = args.kCBMsgArgAdvertisementData.kCBAdvDataServiceUUIDs;

  // todo need to remove dashes and lowercase?
  var deviceUuid = args.kCBMsgArgDeviceUUID;

  var localName = args.kCBMsgArgAdvertisementData.kCBAdvDataLocalName || args.kCBMsgArgName
  if(localName===''){
    localName = undefined;
  }

  var advertisement = {
    localName: localName,
    txPowerLevel: txPowerLevel,
    manufacturerData: manufacturerDataBuffer,
    serviceData: [],
    serviceUuids: serviceUuids
  };
  var connectable = args.kCBMsgArgAdvertisementData.kCBAdvDataIsConnectable ? true : false;
  var rssi = args.kCBMsgArgRssi;

  var serviceData = args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData;
  for (var prop in serviceData) {
    var propData = new Buffer(serviceData[prop], 'base64');
    advertisement.serviceData.push({
      uuid: prop.toLowerCase(),
      data: propData
    });
  }

  debug('peripheral ' + deviceUuid + ' discovered');

  var uuid = new Buffer(deviceUuid, 'hex');
  uuid.isUuid = true;

  if (!this._peripherals[deviceUuid]) {
    this._peripherals[deviceUuid] = {};
  }

  this._peripherals[deviceUuid].uuid = uuid;
  this._peripherals[deviceUuid].connectable = connectable;
  this._peripherals[deviceUuid].advertisement = advertisement;
  this._peripherals[deviceUuid].rssi = rssi;


  address = 'unknown';
  addressType = 'unknown';

  this._peripherals[deviceUuid].address = address;
  this._peripherals[deviceUuid].addressType = addressType;

  this.emit('discover', deviceUuid, address, addressType, connectable, advertisement, rssi);


}


NobleBindings.prototype.onStateChange = function(state) {
  // var state = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'][args.kCBMsgArgState];
  debug('state change ' + state);
  this.emit('stateChange', state);
}


var nobleBindings = new NobleBindings();
nobleBindings._peripherals = {};



/**
 * Start scanning
 * @param  {Array} serviceUuids     Scan for these UUIDs, if undefined then scan for all
 * @param  {Bool}  allowDuplicates  Scan can return duplicates
 *
 * @discussion tested
 */
nobleBindings.startScanning = function(serviceUuids, allowDuplicates) {

  var duplicates = allowDuplicates || false;

  NativeRNBLE.startScanning(serviceUuids, duplicates);
  this.emit('scanStart');
};


/**
 * Stop scanning
 *
 * @discussion tested
 */
nobleBindings.stopScanning = function() {
  NativeRNBLE.stopScanning();
  this.emit('scanStop');
};



nobleBindings.connect = function(deviceUuid) {
  throw new Error('connect not yet implemented');
};

nobleBindings.disconnect = function(deviceUuid) {
  throw new Error('disconnect not yet implemented');
};

nobleBindings.updateRssi = function(deviceUuid) {
  throw new Error('updateRssi not yet implemented');
};

nobleBindings.discoverServices = function(deviceUuid, uuids) {
  throw new Error('discoverServices not yet implemented');
};

nobleBindings.discoverIncludedServices = function(deviceUuid, serviceUuid, serviceUuids) {
  throw new Error('discoverIncludedServices not yet implemented');
};

nobleBindings.discoverCharacteristics = function(deviceUuid, serviceUuid, characteristicUuids) {
  throw new Error('discoverCharacteristics not yet implemented');
};

nobleBindings.read = function(deviceUuid, serviceUuid, characteristicUuid) {
  throw new Error('read not yet implemented');
};

nobleBindings.write = function(deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse) {
  throw new Error('write not yet implemented');
};

nobleBindings.broadcast = function(deviceUuid, serviceUuid, characteristicUuid, broadcast) {
  throw new Error('broadcast not yet implemented');
};

nobleBindings.notify = function(deviceUuid, serviceUuid, characteristicUuid, notify) {
  throw new Error('notify not yet implemented');
};

nobleBindings.discoverDescriptors = function(deviceUuid, serviceUuid, characteristicUuid) {
  throw new Error('discoverDescriptors not yet implemented');
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