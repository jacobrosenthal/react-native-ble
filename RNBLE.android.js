/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   12-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 18-04-2016
*/

'use strict';

var debug = require('debug')('react-native-ble');

//var events = require('events');
//var util = require('util');

//var warning = require('warning');

var bindings = require('./androidbindings.js');

function Noble() {

}

Noble.prototype.hello = function () {
  bindings.hello();
};

//util.inherits(NobleBindings, events.EventEmitter);

module.exports = Noble;
