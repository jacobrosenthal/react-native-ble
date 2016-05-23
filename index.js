var Characteristic = require('noble/lib/characteristic');

Characteristic.prototype.write = function(data, withoutResponse, callback) {
  if (callback) {
    this.once('write', function() {
      callback(null);
    });
  }

  this._noble.write(
    this._peripheralId,
    this._serviceUuid,
    this.uuid,
    data,
    withoutResponse
  );
};

var Descriptor = require('noble/lib/descriptor');

Descriptor.prototype.writeValue = function(data, callback) {
  if (callback) {
    this.once('valueWrite', function() {
      callback(null);
    });
  }
  this._noble.writeValue(
    this._peripheralId,
    this._serviceUuid,
    this._characteristicUuid,
    this.uuid,
    data
  );
};

var noble = require('noble/with-bindings');
var bindings = require('./bindings');
module.exports = new noble(bindings);