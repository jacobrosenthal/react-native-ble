var events = require('events');
var util = require('util');

var a = require('./abstract/common');

function Mock(bindings, sandbox){
  this.sandbox = sandbox;
  this.nativeDataBuffer                = "MjEw";

  this.bindings = bindings;

  this.RNBLE = new RNBLE();
  this.DeviceEventEmitter = new DeviceEventEmitter();

  this.native = {
    DeviceEventEmitter: this.DeviceEventEmitter,
    RNBLE: this.RNBLE
  };

  this.bindings.init(this.native);
}


function DeviceEventEmitter() {}
util.inherits(DeviceEventEmitter, events.EventEmitter);


function RNBLE() {}
util.inherits(RNBLE, events.EventEmitter);

RNBLE.prototype.startScanning = function(){};
RNBLE.prototype.stopScanning = function(){};
RNBLE.prototype.getState = function(){};
RNBLE.prototype.connect = function(){};
RNBLE.prototype.disconnect = function(){};
RNBLE.prototype.updateRssi = function(){};
RNBLE.prototype.discoverServices = function(){};
RNBLE.prototype.discoverIncludedServices = function(){};
RNBLE.prototype.discoverCharacteristics = function(){};
RNBLE.prototype.read = function(){};
RNBLE.prototype.write = function(){};
RNBLE.prototype.readValue = function(){};
RNBLE.prototype.writeValue = function(){};
RNBLE.prototype.notify  = function(){};
RNBLE.prototype.discoverDescriptors = function(){};

module.exports = Mock;
