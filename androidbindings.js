/**
* @Author            : Maxime JUNGER <junger_m>
* @Date              : 18-04-2016
* @Email             : maximejunger@gmail.com
* @Last modified by  : junger_m
* @Last modified time: 19-04-2016
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

  this.emit('stateChange', state);
};

var nobleBindings = new NobleBindings();
nobleBindings._peripherals = {};

nobleBindings.init = function () {
  RNBLE.setup();
};

// Exports
module.exports = nobleBindings;
