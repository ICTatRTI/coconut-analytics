global.Cookie = require 'js-cookie'
moment = require 'moment'

class Coconut

  currentlogin: Cookies.get('current_user') || null

  reportDates:
    startDate: moment().subtract("7","days").format("YYYY-MM-DD")
    endDate: moment().format("YYYY-MM-DD")

  config:
    appName: "WUSC"

  currentlogin: Cookies.get('current_user') || null

  setupDatabases: =>
    username = Cookie.get("username") or prompt("Username:")
    password = Cookie.get("password") or prompt("Password:")

    Cookie.set("username", username)
    Cookie.set("password", password)

    databaseOptions = {ajax: timeout: 50000}

    databaseURL =
      if window.location.origin.startsWith "http://localhost"
        "http://localhost:5984/"
      else
        "https://#{username}:#{password}@coconut.wusc.ca/"

    global.pouchdb = new PouchDB("#{databaseURL}keep", databaseOptions)
    global.peopleDb = new PouchDB("#{databaseURL}keep-people", databaseOptions)
    global.schoolsDb = new PouchDB("#{databaseURL}keep-schools", databaseOptions)
    global.enrollmentsDb = new PouchDB("#{databaseURL}keep-enrollments", databaseOptions)
    global.spotchecksDb = new PouchDB("#{databaseURL}keep-spotchecks", databaseOptions)

    @database = pouchdb
    @peopleDb = peopleDb
    @peopleDB = peopleDb
    @schoolsDb = schoolsDb
    @schoolsDB = schoolsDb
    @enrollmentsDb = enrollmentsDb
    @enrollmentsDB = enrollmentsDb
    @spotchecksDb = spotchecksDb
    @spotchecksDB = spotchecksDb

  promptUntilCredentialsWork: =>
    @setupDatabases()
    @database.info()
    .catch (error) =>
      alert("Invalid username or password")
      Cookie.remove("username")
      Cookie.remove("password")
      @promptUntilCredentialsWork()

module.exports = Coconut
