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

		var self = this;

		DeviceEventEmitter.addListener(
		  'discover', function(args,advertisementData,rssi){

				var serviceDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataServiceData, 'base64');
				var manufacturerDataBuffer = new Buffer(args.kCBMsgArgAdvertisementData.kCBAdvDataManufacturerData, 'base64');

			  var advertisement = {
			    localName: args.kCBMsgArgAdvertisementData.kCBAdvDataLocalName || args.kCBMsgArgName,
			    txPowerLevel: args.kCBMsgArgAdvertisementData.kCBAdvDataTxPowerLevel,
			    manufacturerData: manufacturerDataBuffer,
			    serviceData: [],
			    serviceUuids: args.kCBMsgArgAdvertisementData.kCBAdvDataServiceUUIDs
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

			  var uuid = new Buffer(args.kCBMsgArgDeviceUUID, 'hex');
			  uuid.isUuid = true;

			  var peripheral = {};
			  peripheral.advertisement = advertisement;
			  peripheral.rssi = rssi;

			  peripheral.id = uuid;
			  peripheral.address = 'unknown'; //is there a way to know this?
			  peripheral.addressType = 'unknown'; //is there a way to know this?


		  	self.emit('discover', peripheral);
		  }
		);

		DeviceEventEmitter.addListener(
		  'stateChange', function(state){
		  	self.state = state;
		  	self.emit('stateChange', state);
		  }
		);

	}

	startScanning(serviceUUIDs, allowDuplicates) {
		var scanids = [];
		var duplicates = allowDuplicates || false;

		if(typeof serviceUUIDs === 'string'){
			scanids[0] = serviceUUIDs;
		}else if (Array.isArray(serviceUUIDs)){
			scanids = serviceUUIDs;
		}

		console.log(duplicates);
		NativeRNBLE.startScanning(scanids, duplicates);
	}

	stopScanning() {
		NativeRNBLE.stopScanning();
	}

	//havent figured out a way to trigger this as part of an init yet
	getState() {
		NativeRNBLE.getState();
	}

}

module.exports = RNBLE;
