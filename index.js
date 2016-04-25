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

var noble = require('noble/with-bindings');
var bindings = require('./bindings');
module.exports = new noble(bindings);