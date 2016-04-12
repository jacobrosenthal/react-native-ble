/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   12-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 12-04-2016
*/

var debug = require('debug')('peripheral');

var events = require('events');
var util = require('util');

function Characteristic(noble, peripheralUuid, serviceUuid, characteristicUuid) {
  this._noble = noble;

  this._peripheralUuid = peripheralUuid;
  this._serviceUuid = serviceUuid;
  this._characteristicUuid = characteristicUuid;
}

util.inherits(Characteristic, events.EventEmitter);

Characteristic.prototype.toString = function () {
  return JSON.stringify({
    peripheralUuid: this._peripheralUuid,
    serviceUuid: this._serviceUuid,
    characteristicUuid: this._characteristicUuid,
  });
};

Characteristic.prototype.read = function (callback) {
  if (callback) {
    this.once('read', function (data) {
      callback(data);
    });
  }

  this._noble.read(this._peripheralUuid, this._serviceUuid, this._characteristicUuid);
};

Characteristic.prototype.notify = function (callback) {
  if (callback) {
    this.on('notify', function (data) {
      callback(data);
    });
  }

  this._noble.notify(this._peripheralUuid, this._serviceUuid, this._characteristicUuid);
};

module.exports = Characteristic;
