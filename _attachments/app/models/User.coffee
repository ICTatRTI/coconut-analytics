_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Cookie = require 'js-cookie'

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

  login: ->
    Coconut.currentUser = @
    Cookie('current_user', @username())
    Cookie('current_password', @get "password")
    $("span#user").html @username()
    $('#district').html @get "district"
    $("a[href=#logout]").show()
    $("a[href=#login]").hide()
    if @isAdmin() then $("#manage-button").show() else $("#manage-button").hide()
    if @hasRole "reports"
      $("#top-menu").hide()
      $("#bottom-menu").hide()

User.isAuthenticated = (options) ->
  Coconut.isValidDatabase
    error:  (error) ->
      # See if we have cookies that can login
      userCookie = Cookie('current_user')
      passwordCookie = Cookie('current_password')

      if userCookie and userCookie isnt "" and passwordCookie and passwordCookie isnt ""
        Coconut.openDatabase
          username: userCookie
          password: passwordCookie
          success: ->
            options.success()
          error: ->
            options.error()
      else
        options.error()
    success: ->
      if Coconut.currentUser?
        options.success()
      else
        options.error()

User.login = (options) ->
  user = new User
    _id: "user.#{options.username}"
  user.fetch
    success: =>
      Coconut.currentUser = user
      Cookie('current_user', user.username())
      Cookie('current_password',user.get "password")
      $("span#user").html user.username()
      $("a[href=#logout]").show()
      $("a[href=#login]").hide()
      if user.isAdmin() then $("#manage-button").show() else $("#manage-button").hide()
      if user.hasRole "reports"
        $("#top-menu").hide()
        $("#bottom-menu").hide()


      options.success()
    error: =>
      options.error()

User.logout = ->
  Cookie('current_user',"")
  Cookie('current_password',"")
  $("span#user").html ""
  $('#district').html ""
  $("a[href=#logout]").hide()
  $("a[href=#login]").show()
  Coconut.currentUser = null

module.exports = User