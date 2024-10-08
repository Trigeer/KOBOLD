local newdecoder = require 'lib.dependencies.lunajson.decoder'
local newencoder = require 'lib.dependencies.lunajson.encoder'
local sax = require 'lib.dependencies.lunajson.sax'
-- If you need multiple contexts of decoder and/or encoder,
-- you can require lunajson.decoder and/or lunajson.encoder directly.
return {
	decode = newdecoder(),
	encode = newencoder(),
	newparser = sax.newparser,
	newfileparser = sax.newfileparser,
}
