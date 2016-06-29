PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'

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

Config.saveConfig = (config) ->
    Coconut.database.put config
    .catch (error) -> 
      console.error error
    .then =>
      console.log("Configuration saved successful")

module.exports = Config