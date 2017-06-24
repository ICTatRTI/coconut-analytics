PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'
Dialog = require '../views/Dialog'

class Config extends Backbone.Model
  sync: BackbonePouch.sync
     db: pouchdb

Config.salt = ->
   "HAInmlF250kCAQnM"

Config.getConfig = (options) ->
  Coconut.database.get "coconut.config"
  .then (doc) ->
    Coconut.config = doc
    Coconut.config.role_types = if Coconut.config.role_types then Coconut.config.role_types.split(",") else ["admin", "reports"]
    options.success()
  .catch (error) ->
    console.error error
    options.error()

Config.getLogoUrl = (options) ->
  return new Promise (resolve,reject) ->
    Coconut.database.getAttachment('coconut.config',Coconut.config.appIcon)
    .then (blob) ->
      url = URL.createObjectURL(blob)
      resolve(url)
    .catch (error) ->
      reject(error)

module.exports = Config
