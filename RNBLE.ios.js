/**
 * @providesModule RNBLE
 * @flow
 */
/*jshint esnext: true */

'use strict';

var NativeRNBLE = require('NativeModules').RNBLE;
var EventEmitter = require('events').EventEmitter;
var React = require('react-native');
var Buffer = require('buffer').Buffer;
var Peripheral = require('./peripheral');

var {
  DeviceEventEmitter
} = React;

/**
 * High-level docs for the RNBLE iOS API can be written here.
 */

// if I make it a function and put functions on the prototype get undefined is not a function
class RNBLE extends EventEmitter {

	// is there a better way to tie device events to node events?
	constructor() {
		super();
		this.state = 'unknown';

	  this._peripherals = {};
	  this._services = {};
	  this._characteristics = {};
	  this._descriptors = {};

		DeviceEventEmitter.addListener('discover', this.onDiscover.bind(this));
		DeviceEventEmitter.addListener('stateChange', this.onStateChange.bind(this));
	}

	onStateChange (state) {
  	this.state = state;
  	this.emit('stateChange', state);
	}

	onDiscover (args, advertisementData, rssi) {

		var serviceDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData, 'base64');

		var manufacturerDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataManufacturerData, 'base64');
		if(manufacturerDataBuffer.length===0){
			manufacturerDataBuffer = undefined;
		}

		var txPowerLevel = args.kCBMsgArgAdvertisementData.kCBAdvDataTxPowerLevel;
		if(txPowerLevel===''){
			txPowerLevel = undefined;
		}

		// todo need to lower case and remove dashes
		var serviceUuids = args.kCBMsgArgAdvertisementData.kCBAdvDataServiceUUIDs;

	  var advertisement = {
	    localName: args.kCBMsgArgAdvertisementData.kCBAdvDataLocalName || args.kCBMsgArgName,
	    txPowerLevel: txPowerLevel,
	    manufacturerData: manufacturerDataBuffer,
	    serviceData: [],
	    serviceUuids: serviceUuids
	  };

	  var rssi = args.kCBMsgArgRssi;

	  var serviceData = args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData;
		for (var prop in serviceData) {
			var propData = new Buffer(serviceData[prop], 'base64');
		  advertisement.serviceData.push({
		  	uuid: prop.toLowerCase(),
		  	data: propData
		  });
		}

		// todo need to remove dashes and lowercase
		var uuid = args.kCBMsgArgDeviceUUID;

		var connectable = args.kCBMsgArgAdvertisementData.kCBAdvDataIsConnectable ? true : false;


		var peripheral = this._peripherals[uuid];

	  if (!peripheral) {
	    peripheral = new Peripheral(this, uuid, 'unknown', 'unknown', connectable, advertisement, rssi)

	    this._peripherals[uuid] = peripheral;
	    this._services[uuid] = {};
	    this._characteristics[uuid] = {};
	    this._descriptors[uuid] = {};
	  } else {
	    // "or" the advertisment data with existing
	    for (var i in advertisement) {
	      if (advertisement[i] !== undefined) {
	        peripheral.advertisement[i] = advertisement[i];
	      }
	    }

	    peripheral.rssi = rssi;
	  }

	  var previouslyDiscoverd = (this._discoveredPeripheralUUids.indexOf(uuid) !== -1);

	  if (!previouslyDiscoverd) {
	    this._discoveredPeripheralUUids.push(uuid);
	  }

	  if (this._allowDuplicates || !previouslyDiscoverd) {
	    this.emit('discover', peripheral);
	  }

  }

	startScanning(serviceUUIDs, allowDuplicates, callback) {
		if (this.state !== 'poweredOn') {
		  var error = new Error('Could not start scanning, state is ' + this.state + ' (not poweredOn)');

		  if (typeof callback === 'function') {
		    callback(error);
		  } else {
		    throw error;
		  }
		} else {
		  if (callback) {
		    this.once('scanStart', callback);
		  }

		  this._discoveredPeripheralUUids = [];
		  this._allowDuplicates = allowDuplicates || false;

			var scanids = [];

			if(typeof serviceUUIDs === 'string'){
				scanids[0] = serviceUUIDs;
			}else if (Array.isArray(serviceUUIDs)){
				scanids = serviceUUIDs;
			}

			NativeRNBLE.startScanning(scanids, this._allowDuplicates);
		}	
	}

	stopScanning() {
		NativeRNBLE.stopScanning();
	}

}

module.exports = RNBLE;
