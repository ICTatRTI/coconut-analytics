# This is the entry point for creating bundle.js
# Only packages that get required here or inside the packages that are required here will be included in bundle.js
# New packages are added to the node_modules directory by doing npm install --save package-name

# Make these global so that they can be used from the javascript console
global.$ = require 'jquery'
global._ = require 'underscore'
global.Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'

# These are local .coffee files
Router = require './Router'
MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'

# These are views that should always be shown so render them now
menuView = new MenuView
  # Set the element that this view should render to
  el: "header.coconut-drawer-header"
menuView.render()

headerView = new HeaderView
  el: "header.coconut-header"
headerView.render()

# Coconut is just a global object useful for keeping things in one scope
global.Coconut = {}
Coconut.database = new PouchDB("http://localhost:5984/zanzibar")
Coconut.router = new Router()
Backbone.history.start()
