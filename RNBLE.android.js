/**
* @Author: Maxime JUNGER <junger_m>
* @Date:   12-04-2016
* @Email:  maximejunger@gmail.com
* @Last modified by:   junger_m
* @Last modified time: 19-04-2016
*/

'use strict';

var bindings = require('./androidbindings.js');

function Noble() {

}

Noble.prototype.hello = function () {
  console.log('hello');
  bindings.hello();
};

module.exports = Noble;
