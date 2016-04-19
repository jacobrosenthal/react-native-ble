/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   12-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 19-04-2016
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

  this._bindings.init();
}

util.inherits(Noble, events.EventEmitter);

Noble.prototype.onStateChange = function (state) {
  debug('stateChange ' + state);

  this.state = state;

  this.emit('stateChange', state);
};

module.exports = Noble;
