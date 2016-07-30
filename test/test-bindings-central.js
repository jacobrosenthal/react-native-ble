
var should = require('should');
var sinon = require('sinon');
var bindings = require('../bindings.ios.js');
var Mock = require('./core-bluetooth-mock');

var a = require('./abstract/common');

var Abstract = require('./abstract/test-bindings-abstract');


//native doesnt need to do any setup on these
Abstract.startScanningEmitScanStart(bindings, Mock);
Abstract.stopScanningEmitScanStop(bindings, Mock);

//we need to stub/emit something for these
// Abstract.emitAddressChange(bindings, Mock, function(mock)
// {
//   var message = {
//     peripheralUuid : mock.nativePeripheralUuidString,
//     error : 
//   };
//   mock.DeviceEventEmitter.emit('ble.rssiUpdate', message);
// });

Abstract.emitStateChange(bindings, Mock, function(mock, sandbox)
{
  mock.DeviceEventEmitter.emit('ble.stateChange', a.stateString);
});

Abstract.emitConnectSuccess(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    error : a.mockError
  };

  sandbox.stub(mock.RNBLE, "connect", function(){
    mock.DeviceEventEmitter.emit('ble.connect', message);
  });
});

Abstract.emitConnectFail(bindings, Mock, function(mock, sandbox)
{
  var message = {
    peripheralUuid : a.peripheralUuidString,
    error : a.mockError
  };

  sandbox.stub(mock.RNBLE, "connect", function(){
    mock.DeviceEventEmitter.emit('ble.connect', message);
  });
});

Abstract.emitDisconnect(bindings, Mock, function(mock, sandbox){

  sandbox.stub(mock.RNBLE, "disconnect", function(){
    var message = {
      peripheralUuid : a.peripheralUuidString,
      error : a.mockError
    };
    mock.DeviceEventEmitter.emit('ble.disconnect', message);
  });
});
 
//these tests are local to the core-bluetooth binding
describe('Core Bluetooth Bindings Central', function() {
  var sandbox = sinon.sandbox.create();
  var mock;

  beforeEach(function() {
    mock = new Mock(bindings, sandbox);
  });

  afterEach(function () {
    sandbox.restore();
    mock = null;
  });

  //these native calls dont get tested by testing the emit received, as the bindings send them directly
  it('startScanning should call native', function() {
    var calledSpy = sandbox.spy(mock.RNBLE, 'startScanning');

    bindings.startScanning(a.serviceUuidsArray, a.allowDuplicatesBoolean);

    calledSpy.calledWithExactly(['A90F0252-4CA8-48BB-AE90-6BC8F541CF8C'], a.allowDuplicatesBoolean).should.equal(true);
  });

  it('stopScanning should call native', function() {
    var calledSpy = sandbox.spy(mock.RNBLE, 'stopScanning');

    bindings.stopScanning();

    calledSpy.called.should.equal(true);
  });

});
