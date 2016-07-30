
var should = require('should');
var sinon = require('sinon');
var bindings = require('../bindings.ios.js');
var Mock = require('./core-bluetooth-mock');

var a = require('./abstract/common');

var Abstract = require('./abstract/test-bindings-abstract');


Abstract.emitIncludedServicesDiscover(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    includedServiceUuids: [a.includedServiceUuidString]
  };

  sandbox.stub(mock.RNBLE, "discoverIncludedServices", function(){
    mock.DeviceEventEmitter.emit('ble.includedServicesDiscover', message);
  });
});

Abstract.emitCharacteristicsDiscover(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    serviceUuid : a.serviceUuidString,
    characteristics: [a.bindingsCharacteristicObject]
  };

  sandbox.stub(mock.RNBLE, "discoverCharacteristics", function(){
    mock.DeviceEventEmitter.emit('ble.characteristicsDiscover', message);
  });
});
