_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'
Dialog = require './Dialog'
humanize = require 'underscore.string/humanize'
Form2js = require 'form2js'
js2form = require 'form2js'
Config = require '../models/Config'
crypto = require('crypto')

require 'material-design-lite'

moment = require 'moment'

DataTables = require( 'datatables.net' )()
User = require '../models/User'
UserCollection = require '../models/UserCollection'
crypto = require('crypto')
CONST = require "../Constants"
Tabulator = require 'tabulator-tables'

class UsersView extends Backbone.View
    el:'#content'

    initialize: =>
      @salt = Config.salt()

    events:
      "click #new-user-btn": "createUser"
      "click a.user-edit": "editUser"
      "click a.user-delete": "deleteUser"
      "click #userSave": "formSave"
      "click #userCancel": "formCancel"
      "click a.user-pw-reset": "showResetView"
      "click button#btnSubmit": "resetPassword"

      "click button#addUser": "addUser"

    addUser: =>
      username = prompt "What is the new username (phone number for DMSOs)?"
      username = "user.#{username}"
      password = prompt "What is the new password?"
      password = (crypto.pbkdf2Sync password, '', 1000, 256/8, 'sha256').toString('base64')


      @tabulator.addRow
        _id: username
        district: []
        name: ""
        email: ""
        roles: []
        comments: ""
        inactive: false
        collection: "user"
        isApplicationDoc: true
        password: password
        
    showResetView: (e) ->
      e.preventDefault
      dialogTitle = "Reset Password"
      Dialog.create(@dialogPass, dialogTitle)
      id = $(e.target).closest("a").attr "data-user-id"
      username = id.substring(5)
      $('#resetname').html(username)
      return false

    resetPassword: (e) =>
      e.preventDefault
      id = "user.#{$("#resetname").html()}"
      newPass = $("#newPass").val()
      if newPass is ""
        $('.coconut-mdl-card__title').html("<i class='mdi mdi-information-outline'></i> Please enter new password...").show()
      else
        Coconut.database.get id,
           include_docs: true
        .catch (error) =>
          view.displayErrorMsg('Error encountered resetting password...')
          console.error error
        .then (user) =>
          user.password = (crypto.pbkdf2Sync newPass, '', 1000, 256/8, 'sha256').toString('base64')
          Coconut.database.put user
          .catch (error) -> console.error error
          .then ->
            Dialog.confirm("Password has been reset...", 'Password Reset',['Ok'])
      return false


    render: =>
      @$el.html "
        <h2>Users</h2>
        Click on a cell to edit the user. Districts and roles allow for multiple options to be selected, just press the tab button after the selection have been made.<br/>
        <button id='addUser'>Add a new user</button>

        <div id='userTabulator'/>
      "


      users = await Coconut.database.query "users",
        include_docs: true
      .catch (error) -> console.error error
      .then (result) =>
        Promise.resolve _(result.rows).pluck("doc")

      columns = for field in [
          "_id"
          "district"
          "name"
          "email"
          "roles"
          "comments"
          "inactive"
        ]

        result = {
          title: field
          field: field
          headerFilter: "input"
        }

        result.editor = switch field
          when "_id" then null
          when "inactive" then "tickCross"
          when "district"
            result.editorParams = 
              values: GeoHierarchy.allDistricts()
              multiselect: true
            "select"
          when "roles"
            result.editorParams = 
              values: ["reports","admin","researcher","DMSO"]
              multiselect: true
            "select"
          else "input"

        result


      @tabulator = new Tabulator "#userTabulator",
        height: 400
        columns: columns
        data: users
        cellEdited: (cell) =>
          oldValue = cell.getOldValue()
          value = cell.getValue()
          isUpdated = if _(value).isArray()
            not _(oldValue).isEqual(value)
          else
            cell.getOldValue() isnt cell.getValue() and
            cell.getOldValue() isnt null and 
            cell.getValue() isnt ""


          if isUpdated and confirm("Are you sure you want to change #{cell.getField()} for #{cell.getData()._id} from '#{oldValue}' to '#{value}'")
            data = cell.getRow().getData()
            delete data._rev
            Coconut.database.upsert data._id,  =>
              data
          else
            cell.restoreOldValue()

module.exports = UsersView
