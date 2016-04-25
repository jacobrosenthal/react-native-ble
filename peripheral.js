/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   07-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 25-04-2016
*/

/*jshint loopfunc: true */
var debug = require('debug')('peripheral');

var events = require('events');
var util = require('util');

function Peripheral(noble, id, address, addressType, connectable, advertisement, rssi) {
  this._noble = noble;

  this.id = id;
  this.uuid = id; // for legacy
  this.address = address;
  this.addressType = addressType;
  this.connectable = connectable;
  this.advertisement = advertisement;
  this.rssi = rssi;
  this.services = null;
  this.state = 'disconnected';
}

Peripheral.prototype = {
  _noble: null,
  id: null,
  uuid: null, // for legacy
  address: null,
  addressType: null,
  connectable: null,
  advertisement: null,
  rssi: null,
  services: null,
  state: 'disconnected',
};

Peripheral.prototype.initAndroid = function (noble, address, name, rssi) {
  this._noble = noble;
  this.address = address;
  this.name = name;
  this.rssi = rssi;

  return this;
};

util.inherits(Peripheral, events.EventEmitter);

Peripheral.prototype.toString = function () {
  return JSON.stringify({
    id: this.id,
    address: this.address,
    addressType: this.addressType,
    connectable: this.connectable,
    advertisement: this.advertisement,
    rssi: this.rssi,
    state: this.state,
  });
};

Peripheral.prototype.connect = function (callback) {
  console.log('Je vais me connecter.....\n');
  if (callback) {
    this.once('connect', function (data) {
      console.log('Hello guys');
      this.once('disconnect', this.onDisconnect);
      if (data instanceof Peripheral) {
        callback(data);
      } else {
        callback(new Error('Error on connection'));
      }

    });
  }

  if (this.state === 'connected') {
    this.emit('connect', new Error('Peripheral already connected'));
  } else {
    this.state = 'connecting';
    if (this.id != null) {
      this._noble.connect(this.id);
    } else {
      this._noble.connect(this.address);
    }
  }
};

Peripheral.prototype.disconnect = function (callback) {
  if (callback) {
    this.once('disconnect', function () {
      this.state = 'disconnected';
      callback(null);
    });
  }

  this.state = 'disconnecting';
  if (this.id != undefined) {
    this._noble.disconnect(this.id);
  } else {
    this._noble.disconnect(this.address);
  }
};

// Called when device disconnected without user wants
Peripheral.prototype.onDisconnect = function () {
  this.emit('disconnect', this);
};

Peripheral.prototype.updateRssi = function (callback) {
  if (callback) {
    this.once('rssiUpdate', function (rssi) {
      callback(null, rssi);
    });
  }

  this._noble.updateRssi(this.id);
};

Peripheral.prototype.discoverServices = function (uuids, callback) {
  if (callback) {
    this.once('servicesDiscover', function (services) {
      callback(null, services);
    });
  }

  if (this.id != null) {
    this._noble.discoverServices(this.id, uuids);
  }  else {
    this._noble.discoverServices(this.address, uuids);
  }
};

Peripheral.prototype.discoverSomeServicesAndCharacteristics = function (serviceUuids, characteristicsUuids, callback) {
  this.discoverServices(serviceUuids, function (err, services) {
    var numDiscovered = 0;
    var allCharacteristics = [];

    for (var i in services) {
      var service = services[i];

      service.discoverCharacteristics(characteristicsUuids, function (error, characteristics) {
        numDiscovered++;

        if (error === null) {
          for (var j in characteristics) {
            var characteristic = characteristics[j];

            allCharacteristics.push(characteristic);
          }
        }

        if (numDiscovered === services.length) {
          if (callback) {
            callback(null, services, allCharacteristics);
          }
        }
      }.bind(this));
    }
  }.bind(this));
};

Peripheral.prototype.discoverAllServicesAndCharacteristics = function (callback) {
  this.discoverSomeServicesAndCharacteristics([], [], callback);
};

Peripheral.prototype.readHandle = function (handle, callback) {
  if (callback) {
    this.once('handleRead' + handle, function (data) {
      callback(null, data);
    });
  }

  this._noble.readHandle(this.id, handle);
};

Peripheral.prototype.writeHandle = function (handle, data, withoutResponse, callback) {
  if (!(data instanceof Buffer)) {
    throw new Error('data must be a Buffer');
  }

  if (callback) {
    this.once('handleWrite' + handle, function () {
      callback(null);
    });
  }

  this._noble.writeHandle(this.id, handle, data, withoutResponse);
};

module.exports = Peripheral;
