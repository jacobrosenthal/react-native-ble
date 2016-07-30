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

RNBLE.prototype.startScanning = function(serviceUuids, duplicates){};
RNBLE.prototype.stopScanning = function(){};
RNBLE.prototype.getState = function(){};
RNBLE.prototype.connect = function(deviceUuid){};
RNBLE.prototype.disconnect = function(deviceUuid){};
RNBLE.prototype.updateRssi = function(deviceUuid){};
RNBLE.prototype.discoverServices = function(deviceUuid, uuids){};
RNBLE.prototype.discoverIncludedServices = function(deviceUuid, serviceUuid, serviceUuids){};
RNBLE.prototype.discoverCharacteristics = function(deviceUuid, serviceUuid){};
RNBLE.prototype.read = function(deviceUuid, serviceUuid, characteristicUuid){};
RNBLE.prototype.write = function(deviceUuid, serviceUuid, characteristicUuid, data, withoutResponse){};
RNBLE.prototype.readValue = function(deviceUuid, serviceUuid, characteristicUuid, descriptorUuid){};
RNBLE.prototype.writeValue = function(deviceUuid, serviceUuid, characteristicUuid, descriptorUuid, data){};
RNBLE.prototype.notify  = function(deviceUuid, serviceUuid, characteristicUuid, notify){};
RNBLE.prototype.discoverDescriptors = function(deviceUuid, serviceUuid, characteristicUuid){};

module.exports = Mock;
