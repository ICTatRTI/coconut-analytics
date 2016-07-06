PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'
Dialog = require '../views/Dialog'

class Config extends Backbone.Model
  sync: BackbonePouch.sync
     db: pouchdb
  
Config.getConfig = (options) ->
  config = new Config
    _id: "coconut.config"
  config.fetch
    error: ->
      console.error error
      options.error()
    success: ->
      Coconut.config = config.attributes
      options.success()
    
module.exports = Config