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

class School extends Backbone.Model
  sync: BackbonePouch.sync
     db: pouchdb

  schoolname: ->
    @get("_id").replace(/^school\./,"")

  district: ->
    @get("district")

  password: ->
    @get("password")

  districtInEnglish: ->
    GeoHierarchy.englishDistrictName @get("district")

  passwordIsValid: (password) ->
    @get("password") is password

  inActive: ->
    @get("inactive")

  hasRole: (role) ->
    _(@get("roles")).include role

  nameOrSchoolname: ->
    @get("name") or @schoolname()

  nameOrSchoolnameWithDescription: =>
    "#{@nameOrSchoolname()} #{if @district() then " - #{@district()}" else ""}"


School.isAuthenticated = (options) ->
  schoolname = Cookies.get('current_school')
  if username? and schoolname isnt ""
    id = "school.#{schoolname}"
    Coconut.currentSchool = new School()
    # id is not recognized when put in constructor for some reason
    Coconut.currentSchool.id = id
    Coconut.currentSchool.fetch
      error: (error) ->
        options.error(error)
      success: ->
        # console.log(Coconut.currentUser)
        options.success(Coconut.currentSchool)
  else
    # No cookie. Not logged in
    options.error("User not logged in")


School.inactiveStatus = (inactive) ->
    if (inactive) then "Yes" else "No"

School.token = () ->
  return Math.random().toString(36).substr(2).toUpperCase()

module.exports = School
