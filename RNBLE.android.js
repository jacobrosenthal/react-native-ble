/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   12-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 21-04-2016
*/

'use strict';

var debug = require('debug')('react-native-ble');

var events = require('events');
var util = require('util');

var Peripheral = require('./peripheral');
var Service = require('./service');
var Characteristic = require('./characteristic');

var bindings = require('./androidbindings.js');

function Noble() {
  this.state = 'unknown';

  this._discoveredPeripheralUUids = [];
  this._bindings = bindings;
  this._peripherals = {};
  this._services = {};
  this._characteristics = {};
  this._descriptors = {};

  this._bindings.on('stateChange', this.onStateChange.bind(this));
  this._bindings.on('scanStart', this.onScanStart.bind(this));
  this._bindings.on('scanStop', this.onScanStop.bind(this));
  this._bindings.on('discover', this.onDiscover.bind(this));
  this._bindings.on('connect', this.onConnect.bind(this));
  this._bindings.on('servicesDiscover', this.onServicesDiscover.bind(this));

  //this._bindings.on('connect', this.onConnect.bind(this));

  this._bindings.init();
}

util.inherits(Noble, events.EventEmitter);

Noble.prototype.onStateChange = function (state) {
  debug('stateChange ' + state);

  this.state = state;

  this.emit('stateChange', state);
};

Noble.prototype.startScanning = function (serviceUuids, allowDuplicates, callback) {
  if (this.state !== 'poweredOn') {
    var error = new Error('Could not start scanning, state is ' + this.state + ' (not poweredOn)');

    if (typeof callback === 'function') {
      callback(error);
    } else {
      throw error;
    }
  } else {
    if (callback) {
      this.once('scanStart', callback);
    }

    this._discoveredPeripheralUUids = [];
    this._allowDuplicates = allowDuplicates;

    this._bindings.startScanning(serviceUuids, allowDuplicates);
  }
};

Noble.prototype.onScanStart = function () {
  debug('scanStart');
  this.emit('scanStart');
};

// Noble.prototype.stopScanning = function (callback) {
//   if (callback) {
//     this.once('scanStop', callback);
//   }
//
//   this._bindings.stopScanning();
// };

Noble.prototype.onScanStop = function () {
  debug('scanStop');
  this.emit('scanStop');
};

Noble.prototype.onDiscover = function (address, name, rssi, advertisement) {
  var peripheral = this._peripherals[address];

  if (!peripheral) {
    peripheral = new Peripheral(this, null, address, null, null, advertisement, rssi);

    this._peripherals[address] = peripheral;
    this._services[address] = {};
    this._characteristics[address] = {};
    this._descriptors[address] = {};
  } else {
    // "or" the advertisment data with existing
    for (var i in advertisement) {
      if (advertisement[i] !== undefined) {
        peripheral.advertisement[i] = advertisement[i];
      }
    }

    peripheral.rssi = rssi;
  }

  var previouslyDiscoverd = (this._discoveredPeripheralUUids.indexOf(address) !== -1);

  if (!previouslyDiscoverd) {
    this._discoveredPeripheralUUids.push(address);
  }

  if (this._allowDuplicates || !previouslyDiscoverd) {
    this.emit('discover', peripheral);
  }
};

Noble.prototype.connect = function (peripheralUuid, callback) {
  this._bindings.connect(peripheralUuid);
};

Noble.prototype.onConnect = function (address, error) {
  var peripheral = this._peripherals[address];

  if (peripheral) {
    peripheral.state = error ? 'error' : 'connected';
    peripheral.emit('connect', peripheral);
  } else {
    peripheral.emit('warning', 'unknown peripheral ' + address + ' connected!');
  }
};

Noble.prototype.discoverServices = function (address, uuids) {
  this._bindings.discoverServices(address, uuids);//, function (error, data) {
};

Noble.prototype.onServicesDiscover = function (peripheralUuid, serviceUuids) {
  console.log('je suis là putain');

  var peripheral = this._peripherals[peripheralUuid];

  if (peripheral) {
    var services = [];

    for (var i = 0; i < serviceUuids.length; i++) {
      var serviceUuid = serviceUuids[i];
      var service = new Service(this, peripheralUuid, serviceUuid);

      this._services[peripheralUuid][serviceUuid] = service;
      this._characteristics[peripheralUuid][serviceUuid] = {};
      this._descriptors[peripheralUuid][serviceUuid] = {};

      services.push(service);
    }

    peripheral.services = services;

    peripheral.emit('servicesDiscover', services);
  } else {
    this.emit('warning', 'unknown peripheral ' + peripheralUuid + ' services discover!');
  }
};

module.exports = Noble;
