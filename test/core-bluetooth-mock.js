var events = require('events');
var util = require('util');

var a = require('./abstract/common');

function Mock(bindings, sandbox){
  this.sandbox = sandbox;
  this.nativePeripheralUuidString      = 'DFE12BB4-4E7F-460D-8C1D-112914E21D9E';
  this.nativeServiceUuidString         = 'A90F0252-4CA8-48BB-AE90-6BC8F541CF8C';
  this.nativeIncludedServiceUuidString = '2D0F40D7-6C81-4336-A1AA-60CBD111317E';
  this.nativeCharacteristicUuidString  = 'E365F8C8-A49D-4B30-8547-FCC791860697';
  this.nativeDescriptorUuidString      = '7DE1AEC6-D5FB-433B-A3D0-77B4E4845CA4';

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
RNBLE.prototype.notify  = function(deviceUuid, serviceUuid, characteristicUuid, notify){};
RNBLE.prototype.discoverDescriptors = function(deviceUuid, serviceUuid, characteristicUuid){};



module.exports = Mock;
