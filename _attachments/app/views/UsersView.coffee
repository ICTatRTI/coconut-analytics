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

    setMode: (mode) ->
      $('input#mode').val(mode)
      if mode == 'edit'
        $('#div_password').hide()
        $('form#user input#_id').prop('readonly', true)
      else
        $('form#user input#_id').prop('readonly', false)

    createUser: (e) =>
      e.preventDefault
      dialogTitle = "Add New User"
      Dialog.create(@dialogEdit, dialogTitle)
      $('form#user input').val('')
      @user = null
      @setMode('add')
      return false

    editUser: (e) =>
      e.preventDefault
      dialogTitle = "Edit User"
      Dialog.create(@dialogEdit, dialogTitle)
      @setMode('edit')
      id = $(e.target).closest("a").attr "data-user-id"

      Coconut.database.get id,
         include_docs: true
      .catch (error) -> console.error error
      .then (user) =>
         @user = _.clone(user)
         user._id = user._id.substring(5)
         Form2js.js2form($('form#user').get(0), user)
         if(@user.roles)
           #older doc store this as string and not array
           @user.roles = @user.roles.split(',') if !($.isArray(@user.roles))
           for role in @user.roles
             document.querySelector("##{role}_label").MaterialCheckbox.check() if(role)
         if(user.inactive)
           document.querySelector('#switch-1').MaterialSwitch.on()
         Dialog.markTextfieldDirty()
       return false

    formSave: (e) =>
      errorMsg = ""
      errorMsg += 'Username, ' if $('#_id').val() == ''
      errorMsg += 'Password, ' if $('input#mode').val() == 'add' and $('#passwd').val() == ''
      errorMsg += 'District, ' if $('#district').val() == ''
      errorMsg += 'Name, ' if $('#name').val() == ''

      if errorMsg != ''
        errorMsg = 'Required field(s): ' + errorMsg.slice(0, -2)
        $('#errMsg').html(errorMsg)
        return false
      else
        if not @user
          @user = {
            _id: "user." + $("#_id").val()
          }

        console.log @user

        @user.collection = "user"
        @user.inactive = $("#inactive").is(":checked")
        @user.isApplicationDoc = true
        @user.district = $("select#district").val()
        @user.password = $('#passwd').val()
        @user.name = $('#name').val()
        @user.email = $('#email').val()
        @user.roles = $('#roles').val()
        @user.comments = $('#comments').val()
        if $('input#mode').val() is 'add'
          @user.password = (crypto.pbkdf2Sync @user.password, '', 1000, 256/8, 'sha256').toString('base64') if @user.password != ""
        roles_selected = document.getElementsByName("role")

        console.log @user

        roles = []
        _.map roles_selected, (role) ->
          roles.push(role.id) if role.checked

        @user.roles = roles
        Coconut.database.put @user
        .catch (error) ->
           console.error error
           Dialog.confirm( error, 'Error Encountered',['Ok'])
        .then =>
          @render()
        return false

    deleteDialog: (e) =>
      e.preventDefault
      dialogTitle = "Are you sure?"
      Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes'])
      return false

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


    deleteUser: (e) =>
      view = @
      e.preventDefault
      id = $(e.target).closest("a").attr "data-user-id"
      dialog.close() if dialog.open
      dialogTitle = "Are you sure?"
      Dialog.confirm("This will permanently remove the record id #{id}.", dialogTitle,['No', 'Yes'])
      dialog.addEventListener 'close', (event) ->
        if (dialog.returnValue == 'Yes')
          Coconut.database.get(id).then (doc) ->
            return Coconut.database.remove(doc)
          .then (result) =>
            Dialog.confirm( 'User Successfully Deleted..', 'Delete User',['Ok'])
#            view.render()
            Backbone.history.loadUrl(Backbone.history.fragment)
          .catch (error) ->
            console.error error
            Dialog.confirm( error, 'Error Encountered while deleting',['Ok'])
        dialog.close() if dialog.open
      return false

    formCancel: (e) =>
      e.preventDefault
      dialog.close() if dialog.open
      return false

    render: =>
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
