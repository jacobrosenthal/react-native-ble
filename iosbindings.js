/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   07-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 12-04-2016
*/

var debug = require('debug')('ios-bindings');

var events        = require('events');
var util          = require('util');

var utf8 = require('utf8');

var {
  DeviceEventEmitter,
  NativeModules: { RNBLE },
} = require('react-native');

var Buffer = require('buffer').Buffer;

// Callbacks of Bluetooth functions
var _callbacks = {};

/**
 *  NobleBindings for react native
 */
var NobleBindings = function () {
  DeviceEventEmitter.addListener('discover', this.onDiscover.bind(this));
  DeviceEventEmitter.addListener('stateChange', this.onStateChange.bind(this));
  DeviceEventEmitter.addListener('connect', this.onConnect.bind(this));
  DeviceEventEmitter.addListener('services', this.onServicesDiscovered.bind(this));
  DeviceEventEmitter.addListener('characteristics', this.onCharacteristicsDiscovered.bind(this));
  DeviceEventEmitter.addListener('read', this.onRead.bind(this));
  DeviceEventEmitter.addListener('notify', this.onNotify.bind(this));
};

util.inherits(NobleBindings, events.EventEmitter);

NobleBindings.prototype.onDiscover = function (args, advertisementData, rssi) {
  if (Object.keys(args.kCBMsgArgAdvertisementData).length === 0) {
    return;
  }

  var serviceDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData, 'base64');

  var manufacturerDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataManufacturerData, 'base64');
  if (manufacturerDataBuffer.length === 0) {
    manufacturerDataBuffer = undefined;
  }

  var txPowerLevel = args.kCBMsgArgAdvertisementData.kCBAdvDataTxPowerLevel;
  if (txPowerLevel === '') {
    txPowerLevel = undefined;
  }

  // todo need to lower case and remove dashes
  var serviceUuids = args.kCBMsgArgAdvertisementData.kCBAdvDataServiceUUIDs;

  // todo need to remove dashes and lowercase?
  var deviceUuid = args.kCBMsgArgDeviceUUID;

  var localName = args.kCBMsgArgAdvertisementData.kCBAdvDataLocalName || args.kCBMsgArgName;
  if (localName === '') {
    localName = undefined;
  }

  var advertisement = {
    localName: localName,
    txPowerLevel: txPowerLevel,
    manufacturerData: manufacturerDataBuffer,
    serviceData: [],
    serviceUuids: serviceUuids,
  };
  var connectable = args.kCBMsgArgAdvertisementData.kCBAdvDataIsConnectable ? true : false;
  var rssi = args.kCBMsgArgRssi;

  var serviceData = args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData;
  for (var prop in serviceData) {
    var propData = new Buffer(serviceData[prop], 'base64');
    advertisement.serviceData.push({
      uuid: prop.toLowerCase(),
      data: propData,
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

};

NobleBindings.prototype.onStateChange = function (state) {
  // var state = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'][args.kCBMsgArgState];
  debug('state change ' + state);
  this.emit('stateChange', state);
};

NobleBindings.prototype.onConnect = function (peripheralUuid, error) {
  var peripheral = this._peripherals[peripheralUuid];

  console.log("I'm connected with " + peripheral);

  if (peripheral) {
    peripheral.state = error ? 'error' : 'connected';
    this.emit('connect', peripheralUuid);
  } else {
    this.emit('connect', null);
  }
};

NobleBindings.prototype.onServicesDiscovered = function (data) {

  if (data.servicesUuid && !data.error) {
    this.emit('servicesDiscover', data.peripheralUuid, data.servicesUuid);

  } else {
    this.emit('servicesDiscover', { error: data.error });
  }
};

NobleBindings.prototype.onCharacteristicsDiscovered = function (data) {

  if (data && data.peripheralUuid && data.serviceUuid && data.characteristics) {
    this.emit('characteristicsDiscover', data.peripheralUuid, data.serviceUuid, data.characteristics);
  } else {
    this.emit('characteristicsDiscover', { error: data.error });
  }
};

NobleBindings.prototype.onRead = function (data) {

  const buf = new Buffer(data.data, 'hex');
  console.log('Buffer :' + buf);
  if (data) {
    this.emit('read', data.peripheralUuid, data.serviceUuid, data.characteristicUuid, buf, false);
  }
};

NobleBindings.prototype.onNotify = function (data) {

  const buf = new Buffer(data, 'hex');

  if (data) {
    _callbacks['notify'](null, buf);

    //_readValueCallback(null, data);
  } else {
    _callbacks['notify']('no value to read');

    //_readValueCallback(error, null);
  }
};

var nobleBindings = new NobleBindings();
nobleBindings._peripherals = {};

/**
 * Start scanning
 * @param  {Array} serviceUuids     Scan for these UUIDs, if undefined then scan for all
 * @param  {Bool}  allowDuplicates  Scan can return duplicates
 *
 * @discussion tested
 */
nobleBindings.startScanning = function (serviceUuids, allowDuplicates) {

  var duplicates = allowDuplicates || false;

  RNBLE.startScanning(serviceUuids, duplicates);
  this.emit('scanStart');
};

/**
 * Stop scanning
 *
 * @discussion tested
 */
nobleBindings.stopScanning = function () {
  RNBLE.stopScanning();
  this.emit('scanStop');
};

nobleBindings.init = function () {
  RNBLE.setup();
};

nobleBindings.connect = function (peripheralUuid) {
  // delete peripheral['_events'];
  // delete peripheral['_noble'];
  RNBLE.connect(peripheralUuid);
};

nobleBindings.disconnect = function (deviceUuid) {
  throw new Error('disconnect not yet implemented');
};

nobleBindings.updateRssi = function (deviceUuid) {
  throw new Error('updateRssi not yet implemented');
};

nobleBindings.discoverServices = function (deviceUuid, uuids) {
  RNBLE.discoverServices(deviceUuid, uuids);
};

nobleBindings.discoverIncludedServices = function (deviceUuid, serviceUuid, serviceUuids) {
  throw new Error('discoverIncludedServices not yet implemented');
};

nobleBindings.discoverCharacteristics = function (deviceUuid, serviceUuid, characteristicUuids) {
  RNBLE.discoverCharacteristics(deviceUuid, serviceUuid, characteristicUuids);
};

nobleBindings.read = function (deviceUuid, serviceUuid, characteristicUuid, callback) {
  RNBLE.readCharacteristic(deviceUuid, serviceUuid, characteristicUuid);
};

nobleBindings.write = function (deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse) {
  throw new Error('write not yet implemented');
};

nobleBindings.broadcast = function (deviceUuid, serviceUuid, characteristicUuid, broadcast) {
  throw new Error('broadcast not yet implemented');
};

nobleBindings.notify = function (deviceUuid, serviceUuid, characteristicUuid, notify) {
  _callbacks['notify'] = notify;
  RNBLE.subscribeCharacteristic(deviceUuid, serviceUuid, characteristicUuid);
};

nobleBindings.discoverDescriptors = function (deviceUuid, serviceUuid, characteristicUuid) {
  throw new Error('discoverDescriptors not yet implemented');
};

nobleBindings.readValue = function (deviceUuid, serviceUuid, characteristicUuid, descriptorUuid) {
  throw new Error('readValue not yet implemented');
};

nobleBindings.writeValue = function (deviceUuid, serviceUuid, characteristicUuid, descriptorUuid, data) {
  throw new Error('writeValue not yet implemented');
};

nobleBindings.readHandle = function (deviceUuid, handle) {
  throw new Error('readHandle not yet implemented');
};

nobleBindings.writeHandle = function (deviceUuid, handle, data, withoutResponse) {
  throw new Error('writeHandle not yet implemented');
};

// Exports
module.exports = nobleBindings;
