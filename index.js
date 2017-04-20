var noble = require('noble/with-bindings');
var bindings = require('./lib/bindings');
module.exports = new noble(bindings);
