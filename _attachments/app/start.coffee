# This is the entry point for creating bundle.js
# Only packages that get required here or inside the packages that are required here will be included in bundle.js
# New packages are added to the node_modules directory by doing npm install --save package-name

# Make these global so that they can be used from the javascript console
global.$ = require 'jquery'
global._ = require 'underscore'
global.Backbone = require 'backbone'
Backbone.$  = $
global.PouchDB = require 'pouchdb-core'
PouchDB.plugin(require('pouchdb-upsert'))
PouchDB.plugin(require('pouchdb-adapter-http'))
PouchDB.plugin(require('pouchdb-mapreduce'))
BackbonePouch = require 'backbone-pouch'
moment = require 'moment'
require 'material-design-lite'
global.Cookies = require 'js-cookie'

# These are local .coffee files
global.Coconut = new (require './Coconut')

global.Env = {
#  is_chrome: /chrome/i.test(navigator.userAgent)
  is_chrome: /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor)
}


Coconut.promptUntilCredentialsWork().then =>

  global.HTMLHelpers = require './HTMLHelpers'

  User = require './models/User'
  MenuView = require './views/MenuView'
  Config = require './models/Config'
  Router = require './Router'
  HeaderView = require './views/HeaderView'
  GeoHierarchyClass = require './models/GeoHierarchy'
  DhisOrganisationUnits = require './models/DhisOrganisationUnits'
  QuestionCollection = require './models/QuestionCollection'
  Dhis2 = require './models/Dhis2'
  ChromeView = require './views/ChromeView'


  username = Cookie.get("username")
  password = Cookie.get("password")

  # This sets a couchdb session which is necessary for lists, aka spreadsheet downloads
  fetch '/_session',
    method: 'POST',
    credentials: 'include',
    headers:
      'content-type': 'application/json',
      authorization: "Basic #{btoa("#{username}:#{password}")}"
    body: JSON.stringify({name: username, password: password})

  global.Router = require './Router'
  Coconut.router = new Router(require './AppView')

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

      global.GeoHierarchy = new GeoHierarchyClass()
      global.FacilityHierarchy = GeoHierarchy # These have been combined
      await GeoHierarchy.load()

      Coconut.questions = new QuestionCollection()
      Coconut.questions.fetch
        error: (error) -> console.error error
        success: ->

          Coconut.database.allDocs
            startkey: "user"
            endkey: "user\uf000"
            include_docs: true
          .then (result) =>
            Coconut.nameByUsername = {}
            for row in result.rows
              Coconut.nameByUsername[row.id.replace(/user./,"")] = row.doc.name

            Backbone.history.start()
            checkBrowser()

      global.Issues = require './models/Issues'
