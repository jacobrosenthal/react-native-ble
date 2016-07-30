
var should = require('should');
var sinon = require('sinon');
var bindings = require('../bindings.ios.js');
var Mock = require('./core-bluetooth-mock');

var a = require('./abstract/common');

var Abstract = require('./abstract/test-bindings-abstract');


Abstract.emitRead(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristicUuid: a.characteristicUuidString,
    data: mock.nativeDataBuffer, 
    isNotification: false // TODO
  };

  sandbox.stub(mock.RNBLE, "read", function(){
    mock.DeviceEventEmitter.emit('ble.data', message);
  });
});

Abstract.emitWrite(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristicUuid: a.characteristicUuidString
  };

  sandbox.stub(mock.RNBLE, "write", function(){
    mock.DeviceEventEmitter.emit('ble.write', message);
  });
});

Abstract.emitNotify(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristicUuid: a.characteristicUuidString,
    state: false //TODO
  };

  sandbox.stub(mock.RNBLE, "notify", function(){
    mock.DeviceEventEmitter.emit('ble.notify', message);
  });
});

Abstract.emitDescriptorsDiscover(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristicUuid: a.characteristicUuidString,
    descriptors: [a.descriptorUuidString]
  };

  sandbox.stub(mock.RNBLE, "discoverDescriptors", function(){
    mock.DeviceEventEmitter.emit('ble.descriptorsDiscover', message);
  });
});
