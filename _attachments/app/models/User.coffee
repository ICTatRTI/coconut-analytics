_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'
Cookies = require 'js-cookie'
moment = require 'moment'
crypto = require('crypto')
Config = require './Config'

class User extends Backbone.Model
  sync: BackbonePouch.sync
     db: pouchdb

  username: ->
    @get("_id").replace(/^user\./,"")

  district: ->
    @get("district")

  password: ->
    @get("password")

  districtInEnglish: ->
    GeoHierarchy.englishDistrictName @get("district")

  passwordIsValid: (password) ->
    @get("password") is password

  isAdmin: ->
    _(@get("roles")).include "admin"

  inActive: ->
    @get("inactive")

  hasRole: (role) ->
    _(@get("roles")).include role

  nameOrUsername: ->
    @get("name") or @username()

  nameOrUsernameWithDescription: =>
    "#{@nameOrUsername()} #{if @district() then " - #{@district()}" else ""}"


User.isAuthenticated = (options) ->
  console.log "AAAA"
  username = Cookies.get('current_user')
  if username? and username isnt ""
    id = "user.#{username}"
    Coconut.currentUser = new User()
    # id is not recognized when put in constructor for some reason
    Coconut.currentUser.id = id
    Coconut.currentUser.fetch
      error: (error) ->
        options.error(error)
      success: ->
        options.success(Coconut.currentUser)
  else
    # No cookie. Not logged in
    options.error("User not logged in")


User.login = (options) ->
  user = new User
    _id: "user.#{options.username}"
  user.fetch
    success: ->
      if !(user.inActive())
        hashPwd = user.get("password") || 'unknown'
        salt = ""
        console.log "salt"
        console.log salt
        hashKey = (crypto.pbkdf2Sync options.password, salt, 1000, 256/8, 'sha256').toString('base64')
        console.log hashPwd
        console.log hashKey
        if hashPwd is hashKey
          Coconut.currentUser = user
          Coconut.currentlogin = user.username()
          Cookies.set('current_user', Coconut.currentlogin)
          Cookies.set('current_password',user.get "password")
          $("span#username").html user.username()
          $("a#logout").show()
          $("a#login").hide()
          if user.isAdmin() then $("#admin-main").show() else $("#admin-main").hide()
          options.success()
        else
          options.error("Invalid username/password")
      else
        options.error("User account disabled")
    error: ->
      options.error()

User.logout = (options) ->
  Cookies.remove('current_user')
  Cookies.remove('current_password')
  $('#district').html ""
  $("a#logout").hide()
  $("a#login").show()
  Coconut.currentUser = null

User.inactiveStatus = (inactive) ->
    if (inactive) then "Yes" else "No"

User.token = () ->
  return Math.random().toString(36).substr(2).toUpperCase()

User.hashedPassword = (password) ->
  (crypto.pbkdf2Sync password, Config.salt, 1000, 256/8, 'sha256').toString('base64')

module.exports = User
