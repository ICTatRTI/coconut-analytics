# This is the entry point for creating bundle.js
# Only packages that get required here or inside the packages that are required here will be included in bundle.js
# New packages are added to the node_modules directory by doing npm install --save package-name

# Make these global so that they can be used from the javascript console
global.$ = require 'jquery'
global._ = require 'underscore'
global.Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'

require 'material-design-lite'
Cookies = require 'js-cookie'

# These are local .coffee files
Router = require './Router'
MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'

# These are views that should always be shown so render them now
menuView = new MenuView
  # Set the element that this view should render to
  el: ".coconut-drawer"
menuView.render()

headerView = new HeaderView
  el: "header.coconut-header"
headerView.render()

# Coconut is just a global object useful for keeping things in one scope
global.Coconut = {
  database: new PouchDB("http://localhost:5984/zanzibar")
  router: new Router()
  #TODO load config from a _local database doc
  config: {
    dateFormat: "YYYY-MM-DD"
    design_doc_name: "zanzibar"
  }
  currentUser: Cookies.get('current_user')
}

global.Env = {
  is_chrome: /chrome/i.test(navigator.userAgent)
}

# This is a PouchDB - Backbone connector - we only use it for a few things like getting the list of questions
Backbone.sync = BackbonePouch.sync
  db: Coconut.database
  fetch: 'query'

Backbone.Model.prototype.idAttribute = '_id'

#TODO stubbing this out until login is implemented
global.User = {
  currentUser:  {
    hasRole: -> "reports"
  }
}

_(["shehias_high_risk","shehias_received_irs"]).each (docId) ->
  Coconut.database.get docId
  .catch (error) -> console.error error
  .then (result) ->
    Coconut[docId] = result

GeoHierarchyClass = require './models/GeoHierarchy'
global.GeoHierarchy = new GeoHierarchyClass
  error: (error) -> console.error error
  success: =>
    Backbone.history.start()

global.Issues = require './models/Issues'
