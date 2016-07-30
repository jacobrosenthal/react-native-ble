
var should = require('should');
var sinon = require('sinon');
var bindings = require('../bindings.ios.js');
var Mock = require('./core-bluetooth-mock');

var a = require('./abstract/common');

var Abstract = require('./abstract/test-bindings-abstract');

Abstract.emitValueRead(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristicUuid: a.characteristicUuidString,
    descriptorUuid: a.descriptorUuidString,
    data: mock.nativeDataBuffer
  };

  sandbox.stub(mock.RNBLE, "readValue", function(){
    mock.DeviceEventEmitter.emit('ble.valueUpdate', message);
  });
});

Abstract.emitValueWrite(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristicUuid: a.characteristicUuidString,
    descriptorUuid: a.descriptorUuidString
  };

  sandbox.stub(mock.RNBLE, "writeValue", function(){
    mock.DeviceEventEmitter.emit('ble.valueWrite', message);
  });
});
