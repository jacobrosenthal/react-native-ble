/**
* @Author            : Maxime JUNGER <junger_m>
* @Date              : 18-04-2016
* @Email             : maximejunger@gmail.com
* @Last modified by  : junger_m
* @Last modified time: 21-04-2016
*/

var debug  = require('debug')('android-bindings');

var events = require('events');
var util   = require('util');

var utf8   = require('utf8');

var {
  DeviceEventEmitter,
  NativeModules      : { RNBLE },
} = require('react-native');

var Buffer = require('buffer').Buffer;

/**
 * NobleBindings for react native
 */
var NobleBindings = function () {
  DeviceEventEmitter.addListener('stateChange', this.onStateChange.bind(this));
  DeviceEventEmitter.addListener('discover', this.onDiscover.bind(this));
  DeviceEventEmitter.addListener('connect', this.onConnect.bind(this));
  DeviceEventEmitter.addListener('services', this.onServicesDiscovered.bind(this));

  // DeviceEventEmitter.addListener('discover', this.onDiscover.bind(this));
  // DeviceEventEmitter.addListener('stateChange', this.onStateChange.bind(this));
  // DeviceEventEmitter.addListener('connect', this.onConnect.bind(this));
  // DeviceEventEmitter.addListener('disconnect', this.onDisconnect.bind(this));
  // DeviceEventEmitter.addListener('services', this.onServicesDiscovered.bind(this));
  // DeviceEventEmitter.addListener('characteristics', this.onCharacteristicsDiscovered.bind(this));
  // DeviceEventEmitter.addListener('read', this.onRead.bind(this));
  // DeviceEventEmitter.addListener('notify', this.onNotify.bind(this));

};

util.inherits(NobleBindings, events.EventEmitter);

NobleBindings.prototype.onStateChange = function (state) {
  // var state = ['unknown', 'resetting', 'unsupported', 'unauthorized', 'poweredOff', 'poweredOn'][args.kCBMsgArgState];
  debug('state change ' + state);

  this.emit('stateChange', state.state);
};

NobleBindings.prototype.onDiscover = function (args) {

  console.log('eh lol j ai : ' + args);

  if (!this._peripherals[args.address])
    this._peripherals[args.address] = args;

  var advertisement = {
      localName: args.name,
      txPowerLevel: null,
      manufacturerData: null,
      serviceData: [],
      serviceUuids: null,
    };

  this.emit('discover', args.address, args.name, args.rssi, advertisement);
};

NobleBindings.prototype.onConnect = function (args) {
  var peripheral = this._peripherals[args.address];

  console.log("I'm connected with " + peripheral);

  if (peripheral) {
    peripheral.state = args.error ? 'error' : 'connected';
    this.emit('connect', args.address, null);
  } else {
    this.emit('connect', null, 'Peripheral Not Found');
  }
};

NobleBindings.prototype.onServicesDiscovered = function (data) {
  console.log('j ai trouvé des services');
  if (data.servicesUuid && !data.error) {
    this.emit('servicesDiscover', data.address, data.servicesUuid);

  } else {
    this.emit('servicesDiscover', { error: data.error });
  }
};

var nobleBindings = new NobleBindings();
nobleBindings._peripherals = {};

nobleBindings.init = function () {
  RNBLE.setup();
};

nobleBindings.startScanning = function (serviceUuids, allowDuplicates) {

  var duplicates = allowDuplicates || false;

  RNBLE.startScanning(serviceUuids, duplicates);
  this.emit('scanStart');
};

nobleBindings.connect = function (peripheralUuid) {
  // delete peripheral['_events'];
  // delete peripheral['_noble'];
  console.log('--------\nConnexion on ' + peripheralUuid + '\n---------\n');
  RNBLE.connect(peripheralUuid);
};

nobleBindings.discoverServices = function (address, uuids) {
  RNBLE.discoverServices(address, uuids);
};

// Exports
module.exports = nobleBindings;
