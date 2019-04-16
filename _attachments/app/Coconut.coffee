global.PouchDB = require 'pouchdb'
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

    @database = new PouchDB("https://#{username}:#{password}@zanzibar.cococloud.co/zanzibar")

  promptUntilCredentialsWork: =>
    @setupDatabases()
    @database.info()
    .catch (error) =>
      alert("Invalid username or password")
      Cookie.remove("username")
      Cookie.remove("password")
      @promptUntilCredentialsWork()

module.exports = Coconut
