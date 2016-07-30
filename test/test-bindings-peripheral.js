
var should = require('should');
var sinon = require('sinon');
var bindings = require('../bindings.ios.js');
var Mock = require('./core-bluetooth-mock');

var a = require('./abstract/common');

var Abstract = require('./abstract/test-bindings-abstract');


Abstract.emitRssiUpdate(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    rssi : a.rssiNumber
  };

  sandbox.stub(mock.RNBLE, "updateRssi", function(){
    mock.DeviceEventEmitter.emit('ble.rssiUpdate', message);
  });
});

Abstract.emitServicesDiscover(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuids : [a.serviceUuidString]
  };

  sandbox.stub(mock.RNBLE, "discoverServices", function(){
    mock.DeviceEventEmitter.emit('ble.servicesDiscover', message);
  });
});
