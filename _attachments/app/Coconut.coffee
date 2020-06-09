global.PouchDB = require 'pouchdb-browser'
PouchDB.plugin(require('pouchdb-upsert'))
BackbonePouch = require 'backbone-pouch'
global.Cookie = require 'js-cookie'
moment = require 'moment'

class Coconut

  currentlogin: Cookies.get('current_user') || null

  reportDates:
    startDate: moment().subtract("7","days").format("YYYY-MM-DD")
    endDate: moment().format("YYYY-MM-DD")

  setupDatabases: =>
    username = Cookie.get("username") or prompt("Username:")
    password = Cookie.get("password") or prompt("Password:")

    Cookie.set("username", username)
    Cookie.set("password", password)

    databaseOptions = {ajax: timeout: 1000 * 60 * 10} # Ten minutes

    databaseURL =
      if window.location.origin.startsWith "http://localhost"
        "http://#{username}:#{password}@localhost:5984/"
      else
        "https://#{username}:#{password}@zanzibar.cococloud.co/"

    @database = new PouchDB("#{databaseURL}/zanzibar", databaseOptions)
    @reportingDatabase = new PouchDB("#{databaseURL}/zanzibar-reporting", databaseOptions)
    @cachingDatabase = new PouchDB("coconut-zanzibar-caching")
    @weeklyFacilityDatabase = new PouchDB("#{databaseURL}/zanzibar-weekly-facility")

  promptUntilCredentialsWork: =>
    @setupDatabases()
    @database.info()
    .catch (error) =>
      alert("Invalid username or password")
      Cookie.remove("username")
      Cookie.remove("password")
      @promptUntilCredentialsWork()

module.exports = Coconut
