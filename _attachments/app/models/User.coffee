_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'
Cookies = require 'js-cookie'

class User extends Backbone.Model
  url: "/user"
  
  username: ->
    @get("_id").replace(/^user\./,"")

  district: ->
    @get("district")

  isAdmin: ->
    _(@get("roles")).include "admin"

  hasRole: (role) ->
    _(@get("roles")).include role

  nameOrUsername: ->
    @get("name") or @username()

  nameOrUsernameWithDescription: =>
    "#{@nameOrUsername()} #{if @district() then " - #{@district()}" else ""}"

  @isAdministrator = (user) ->
    return user.roles.includes "admin"
    
User.isAuthenticated = (options) ->
  username = Cookies.get('current_user')
  if username? and username isnt ""
    id = "user.#{username}"
    Coconut.database.get id,
       include_docs: true
    .catch (error) -> 
      Coconut.currentUser = null
      console.error(error)
    .then (user) -> 
      Coconut.currentUser = user 
      return options.success(user)
  else
    # Not logged in
    options.error() if options.error?
  return
  
User.login = (options) ->
  user = new User
    _id: "user.#{options.username}"
  user.fetch
    success: ->
#      if (user.get("password") is options.password)
      Coconut.currentUser = user
      Coconut.currentlogin = user.username()
      Cookies.set('current_user', Coconut.currentlogin)
      Cookies.set('current_password',user.get "password")
      $("span#username").html user.username()
      $("a#logout").show()
      $("a#login").hide()
      if user.isAdmin() then $("#admin-main").show() else $("#admin-main").hide()
      options.success()
#      else
#        options.error("Incorrect Password")
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
	
module.exports = User