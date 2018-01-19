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
moment = require 'moment'
require 'material-design-lite'
Cookies = require 'js-cookie'
global.pouchdb = new PouchDB('https://wusc.cococloud.co/wusc')
global.peopleDb = new PouchDB('https://wusc.cococloud.co/wusc-people')
global.schoolsDb = new PouchDB('https://wusc.cococloud.co/wusc-schools')
#global.pouchdb = new PouchDB('https://wusc.cococloud.co/wusc')
global.HTMLHelpers = require './HTMLHelpers'

# These are local .coffee files
Router = require './Router'
User = require './models/User'
Config = require './models/Config'
MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'
QuestionCollection = require './models/QuestionCollection'

# Coconut is just a global object useful for keeping things in one scope
#TODO load config from a _local database doc

global.Coconut =
  database: pouchdb
  peopleDb: peopleDb
  schoolsDb: schoolsDb
  router: new Router()
  currentlogin: Cookies.get('current_user') || null
  reportDates:
    startDate: moment().subtract("7","days").format("YYYY-MM-DD")
    endDate: moment().format("YYYY-MM-DD")
  config:
    appName: "WUSC"

global.Env = {
#  is_chrome: /chrome/i.test(navigator.userAgent)
  is_chrome: /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor)
}

# This is a PouchDB - Backbone connector - we only use it for a few things like getting the list of questions
Backbone.sync = BackbonePouch.sync
  db: Coconut.database
  fetch: 'query'

Backbone.Model.prototype.idAttribute = '_id'

checkBrowser = (callback) ->
  if !Env.is_chrome
    chromeView = new ChromeView()
    chromeView.render()
    callback?.success()
  else
    callback?.success()

User.isAuthenticated
  success: ->
    $('header.coconut-header').show()
    $('div.coconut-drawer').show()
  error: (err) ->
    console.log(err)

# Render headerView here instead of below with MenuView, otherwise the hamburger menu will be missing in smaller screen
Coconut.headerView = new HeaderView
Coconut.headerView.render()

Config.getConfig
  error: ->
    console.log("Error Retrieving Config")
  success: ->
    Config.getLogoUrl()
    .catch (error) ->
      console.error "Logo Url not setup"
      console.error error
    .then (url) ->
      Coconut.logoUrl = url
      Coconut.menuView = new MenuView
      Coconut.menuView.render()

      Backbone.history.start()
      checkBrowser()
