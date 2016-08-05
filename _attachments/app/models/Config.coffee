PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'
Dialog = require '../views/Dialog'

class Config extends Backbone.Model
  sync: BackbonePouch.sync
     db: pouchdb
  
Config.getConfig = (options) ->
  Coconut.database.get "coconut.config"
  .then (doc) ->
    Coconut.config = doc
    Coconut.config.role_types = if Coconut.config.role_types then Coconut.config.role_types.split(",") else ["admin", "reports"]
    options.success()
  .catch (error) ->
    console.error error
    options.error()
    
module.exports = Config