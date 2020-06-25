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
        Click on a cell to edit the user. Districts and roles allow for multiple options to be selected, just press the tab button when you have made your selections.<br/>
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
              values: ["reports","admin","researcher"]
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


    renderOld: =>
      HTMLHelpers.ChangeTitle("Admin: Users")
      Coconut.database.query "users",
        include_docs: true
      .catch (error) -> console.error error
      .then (result) =>
        users = _(result.rows).pluck("doc")

        @fields =  "_id,password,district,name".split(",")
        @dialogEdit = "
          <form id='user' method='dialog'>
             <div id='dialog-title'> </div>
             <div>
                <ul>
                  <li>We recommend a username that corresponds to the users phone number.</li>
                  <li>If a user is no longer working, mark their account as inactive to stop notification messages from being sent to the user.</li>
                </ul>
             </div>
             <div id='errMsg'></div>
             <input type='hidden' id='mode' value='' />
             #{
              _.map( @fields, (field) =>
                if field is 'district'
                  selectList = GeoHierarchy.allDistricts()
                  "
                  <div class='mdl-select mdl-js-select mdl-select--floating-label'>
                      <select class='mdl-select__input' id='#{field}' name='#{field}'>
                        <option value=''></option>
                        #{
                          selectList.map (list) =>
                            "<option value='#{list}'>
                              #{list}
                             </option>"
                          .join ""
                        }
                      </select>
                      <label class='mdl-select__label' for='#{field}'>#{humanize(field)}</label>
                  </div>
                  "
                else
                  "
                     <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='div_#{field}'>
                       <input class='mdl-textfield__input' type='text' id='#{if field is 'password' then 'passwd' else field }' name='#{field}' #{if (field is "_id" and not @user) then "readonly='true'" else ""} #{ if field is "_id" then "style='text-transform:lowercase;' onkeyup='javascript:this.value=this.value.toLowerCase()'"}></input>
                       <label class='mdl-textfield__label' for='#{field}'>#{if field is '_id' then 'Username' else humanize(field)}</label>
                     </div>
                  "
                ).join("")
              }
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='div_email' style='margin-bottom: 10px'>
                <input class='mdl-textfield__input' type='text' pattern='^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$' id='email' name='email'</input>
                <label class='mdl-textfield__label' for='email'>Email</label>
                <span class='mdl-textfield__error'>Email is not valid!</span>
              </div>
              <div style='color: rgb(33,150,243)'>Roles:</div>
              <div class='m-l-10 m-b-20'>
                #{
                   _.map(Coconut.config.role_types, (role) =>
                     "
                      <label class='mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect' for='#{role}' id='#{role}_label'>
                        <input type='checkbox' name='role' id='#{role}' class='mdl-checkbox__input' value='#{role}'>
                        <span class='mdl-checkbox__label'>#{humanize(role)}</span>
                      </label>
                     "
                     ).join("")
                }

              </div>
              <label class='mdl-switch mdl-js-switch mdl-js-ripple-effect' for='inactive' id='switch-1'>
                   <input type='checkbox' id='inactive' class='mdl-switch__input'>
                   <span class='mdl-switch__label'>Inactive</span>
              </label>
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='div_comments'>
                <input class='mdl-textfield__input' type='text' id='comments' name='comments'></input>
                <label class='mdl-textfield__label' for='comments'>Comments</label>
              </div>
              <div id='dialogActions'>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='userSave' type='submit' value='save'><i class='mdi mdi-content-save mdi-24px'></i> Save</button> &nbsp;
               <button class='mdl-button mdl-js-button mdl-button--primary' id='userCancel' type='submit' value='cancel'><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
              </div>
          </form>
        "
        @dialogPass = "
          <div id='dialog-title'> </div>
          <div class='m-b-10'>User: <span id='resetname'></span></div>
          <form id='resetForm' method='dialog'>
             <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                 <input class='mdl-textfield__input' type='text' id='newPass' name='newPass' autofocus>
                 <label class='mdl-textfield__label' for='newPass'>New Password*</label>
             </div>
             <div class='coconut-mdl-card__title'></div>
            <div id='dialogActions'>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='btnSubmit' type='submit' ><i class='mdi mdi-check-circle mdi-24px'></i> Submit</button>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='btnCancel' type='submit' ><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
            </div>
          </form>
        "
        @$el.html "
            <h4>Users <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-user-btn'>
              <i class='mdi mdi-plus mdi-14px'></i>
            </button></h4>
            <dialog id='dialog'>
              <div id='dialogContent'> </div>
            </dialog>

            <div id='results' class='result'>
              <table class='summary tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
                <thead>
                  <tr>
                  <th class='header headerSortUp mdl-data-table__cell--non-numeric'>Username</th>
                  <th class='header mdl-data-table__cell--non-numeric'>District</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Name</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Email</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Roles</th>
                  <th class='mdl-data-table__cell--non-numeric'>Comments</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Inactive</th>
                  <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  #{
                    _(users).map (user) ->
                      "
                      <tr>
                        <td class='mdl-data-table__cell--non-numeric'>#{user._id.substring(5)}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{user.district}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{user.name}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{user.email || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{user.roles || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{user.comments || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{User.inactiveStatus(user.inactive)}</td>
                        <td>
                         <button id='edit-menu_#{user._id}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                            <i class='mdi mdi-dots-vertical mdi-24px'></i>
                          </button>
                          <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='edit-menu_#{user._id}'>
                            <li class='mdl-menu__item'><a href='#' class='user-pw-reset' data-user-id='#{user._id}'><i class='mdi mdi-key mdi-24px'></i> Reset Passwd</a></li>
                            <li class='mdl-menu__item'><a href='#' class='user-edit' data-user-id='#{user._id}'><i class='mdi mdi-pencil mdi-24px'></i> Edit User</a></li>
                            <li class='mdl-menu__item'><a href='#' class='user-delete' data-user-id='#{user._id}'><i class='mdi mdi-delete mdi-24px'></i> Delete User</a></li>
                          </ul>
                        </td>
                     </tr>
                     "
                    .join("")
                  }
                </tbody>
              </table>
            </div>
        "
        componentHandler.upgradeDom()
       # $("table.summary").tablesorter({sortList: [[0,0]]})
        @dataTable = $("table.summary").dataTable
          aaSorting: [[0,"asc"]]
          iDisplayLength: 10
          dom: 'T<"clear">lfrtip'
          tableTools:
            sSwfPath: "js-libraries/copy_csv_xls.swf"
            aButtons: [
              "copy",
              "csv",
              "print"
            ]

module.exports = UsersView
