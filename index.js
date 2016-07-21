var noble = require('noble/with-bindings');
var bindings = require('./bindings');
module.exports = new noble(bindings);