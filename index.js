var Noble = require('noble/lib/noble');
var bindings = require('./bindings');

Noble.prototype.enable = function () {
    this._bindings.enable();
}

module.exports = new Noble(bindings);
