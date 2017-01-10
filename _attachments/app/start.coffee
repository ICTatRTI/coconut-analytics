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
global.pouchdb = new PouchDB("http://localhost:5984/zanzibar")
AppView = require './AppView'
global.HTMLHelpers = require './HTMLHelpers'

# These are local .coffee files
Router = require './Router'
User = require './models/User'
Config = require './models/Config'
MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'
GeoHierarchyClass = require './models/GeoHierarchy'
DhisOrganisationUnits = require './models/DhisOrganisationUnits'
QuestionCollection = require './models/QuestionCollection'
Dhis2 = require './models/Dhis2'
ChromeView = require './views/ChromeView'

# Coconut is just a global object useful for keeping things in one scope
#TODO load config from a _local database doc

global.Coconut =
  database: pouchdb
  router: new Router(AppView)
  currentlogin: Cookies.get('current_user') || null
  reportDates:
    startDate: moment().subtract("7","days").format("YYYY-MM-DD")
    endDate: moment().format("YYYY-MM-DD")
  
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
    callback.success()
  else
    callback.success()  

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
      _(["shehias_high_risk","shehias_received_irs"]).each (docId) ->
        Coconut.database.get docId
        .catch (error) -> console.error error
        .then (result) ->
          Coconut[docId] = result


    Coconut.dhis2 = new Dhis2()
    Coconut.dhis2.loadFromDatabase
      error: (error) -> console.error error
      success: ->
        dhisOrganisationUnits = new DhisOrganisationUnits()
        dhisOrganisationUnits.rawData = Coconut.dhis2.dhis2Doc
        dhisOrganisationUnits.extendExport
          error: (error) -> console.error error
          success: (result) ->
            global.GeoHierarchy = new GeoHierarchyClass(result)
            global.FacilityHierarchy = GeoHierarchy # These have been combined
            Coconut.questions = new QuestionCollection()
            Coconut.questions.fetch
              error: (error) -> console.error error
              success: ->
                Backbone.history.start()
                checkBrowser()

    global.Issues = require './models/Issues'


