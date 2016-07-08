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
      # Set role_types default values if none found on coucbdb.
      Coconut.config.role_types = if Coconut.config.role_types then Coconut.config.role_types.split(",") else ["admin", "reports"]
      options.success()
    
module.exports = Config