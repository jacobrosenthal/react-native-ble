/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   11-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 12-04-2016
*/

var debug = require('debug')('peripheral');

var events = require('events');
var util = require('util');

function Service(noble, peripheralUuid, serviceUuid) {
  this._noble = noble;

  this._peripheralUuid = peripheralUuid;
  this._serviceUuid = serviceUuid;
}

util.inherits(Service, events.EventEmitter);

Service.prototype.toString = function () {
  return JSON.stringify({
    peripheralUuid: this._peripheralUuid,
    serviceUuid: this._serviceUuid,
  });
};

Service.prototype.getId = function () {
  return this._serviceUuid;
};

Service.prototype.discoverCharacteristics = function (characteristicsUuid, callback) {
  if (callback) {
    this.once('characteristicsDiscovered', function (characteristics) {
      callback(characteristics);
    });
  }

  this._noble.discoverCharacteristics(this._peripheralUuid, [this._serviceUuid], characteristicsUuid);
};

module.exports = Service;
