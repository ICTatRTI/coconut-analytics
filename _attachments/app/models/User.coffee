_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
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

User.isAuthenticated = (options) ->
  current_user_cookie = Cookies.get('current_user')
  if current_user_cookie? and current_user_cookie isnt ""
    user = new User
      _id: "user.#{Cookies.get('current_user')}"
    user.fetch
      success: ->
        options.success(user)
      error: (error) ->
        # current user is invalid (should not get here)
        console.error "Could not fetch user.#{Cookies.get('current_user')}: #{error}"
        options?.error()
  else
    # Not logged in
    options.error() if options.error?

User.login = (options) ->
  user = new User
    _id: "user.#{options.username}"
  user.fetch
    success: ->
#      if (user.get("password") is options.password)
      Coconut.currentUser = user
      Cookies.set('current_user', user.username())
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