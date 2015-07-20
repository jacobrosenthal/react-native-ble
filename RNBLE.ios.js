/**
 * @providesModule RNBLE
 * @flow
 */
'use strict';

var NativeRNBLE = require('NativeModules').RNBLE;
var invariant = require('invariant');

/**
 * High-level docs for the RNBLE iOS API can be written here.
 */

var RNBLE = {
  test: function() {
    NativeRNBLE.test();
  }
};

module.exports = RNBLE;
