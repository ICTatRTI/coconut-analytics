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

require 'material-design-lite'

moment = require 'moment'

DataTables = require( 'datatables.net' )()
User = require '../models/User'
UserCollection = require '../models/UserCollection'
bcrypt = require 'bcryptjs'
CONST = require "../Constants"

class UsersView extends Backbone.View
    el:'#content'
    events:
      "click #new-user-btn": "createUser"
      "click a.user-edit": "editUser"
      "click a.user-delete": "deleteDialog"
      "click #formSave": "formSave"
      "click #formCancel": "formCancel"
      "click button#buttonYes": "deleteUser"
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
         if (user.roles)
           for role in user.roles
             $("[name=role][value=#{role}]").prop("checked", true)
         if(user.inactive)
           document.querySelector('#switch-1').MaterialSwitch.on()
         Dialog.markTextfieldDirty()
       return false
	   
    formSave: =>
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

        @user.inactive = $("#inactive").is(":checked")
        @user.isApplicationDoc = true
        @user.district = $("#district").val().toUpperCase()
        @user.password = $('#passwd').val()
        @user.name = $('#name').val()
        @user.roles = $('#roles').val()
        @user.comments = $('#comments').val()
        @user.hash = bcrypt.hashSync(@user.password, CONST.SaltRounds) if @user.password != ""

        Coconut.database.put @user
        .then =>
          @render()
        .catch (error) -> 
           console.error error
           Dialog.confirm( error, 'Error Encountered',['Ok'])
        
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
        $('.coconut-mdl-card__title').html("<i class='material-icons'>error_outline</i> Please enter new password...").show()
      else
        hash = bcrypt.hashSync newPass, CONST.SaltRounds
        Coconut.database.get id,
           include_docs: true
        .catch (error) => 
          view.displayErrorMsg('Error encountered resetting password...')
          console.error error
        .then (user) =>
          user.hash = hash
          Coconut.database.put user
          .catch (error) -> console.error error
          .then ->
            Dialog.confirm("Password has been reset...", 'Password Reset',['Ok'])
      return false
      
## TODO Need the codes to delete user record
    deleteUser: (e) =>
      e.preventDefault
      console.log("User Deleted")
      dialog.close()
      return false
	
    formCancel: (e) =>
      e.preventDefault
      dialog.close()
      return false

    render: =>
      Coconut.database.query "zanzibar-server/users",
        include_docs: true
      .catch (error) -> console.error error
      .then (result) =>
        users = _(result.rows).pluck("doc")

        @fields =  "_id,password,district,name,roles,comments".split(",")
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
                "
                   <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label' id='div_#{field}'>
                     <input class='mdl-textfield__input' type='text' id='#{if field is 'password' then 'passwd' else field }' name='#{field}' #{if field is "_id" and not @user then "readonly='true'" else ""}></input>
                     <label class='mdl-textfield__label' for='#{field}'>#{if field is '_id' then 'Username' else humanize(field)}</label>
                   </div>
                "
                ).join("")
              }
              <label class='mdl-switch mdl-js-switch mdl-js-ripple-effect' for='inactive' id='switch-1'>
                   <input type='checkbox' id='inactive' class='mdl-switch__input'>
                   <span class='mdl-switch__label'>Inactive</span>
              </label>
              <div id='dialogActions'>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='formSave' type='submit' value='save'><i class='material-icons'>save</i> Save</button> &nbsp;
               <button class='mdl-button mdl-js-button mdl-button--primary' id='formCancel' type='submit' value='cancel'><i class='material-icons'>cancel</i> Cancel</button>
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
               <button class='mdl-button mdl-js-button mdl-button--primary' id='btnSubmit' type='submit' ><i class='material-icons'>loop</i> Submit</button>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='btnCancel' type='submit' ><i class='material-icons'>cancel</i> Cancel</button>
            </div> 
          </form>
        "
        @$el.html "
            <h4>Users <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--colored' id='new-user-btn'>
              <i class='material-icons'>add_circle</i>
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
                        <td class='mdl-data-table__cell--non-numeric'>#{user.roles || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{user.comments || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{User.inactiveStatus(user.inactive)}</td>
                        <td>
                           <button class='edit mdl-button mdl-js-button mdl-button--icon'>
                           <a href='#' class='user-pw-reset' data-user-id='#{user._id}' title='Reset password'><i class='material-icons icon-24'>vpn_key</i></a></button>
                           <button class='edit mdl-button mdl-js-button mdl-button--icon'>
                           <a href='#' class='user-edit' data-user-id='#{user._id}' title='Edit user'><i class='material-icons icon-24'>mode_edit</i></a></button>
                           <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                           <a href='#' class='user-delete' data-user-id='#{user._id}' title='Delete user'><i class='material-icons icon-24'>delete</i></a></button>
                        </td>
                     </tr> 
                     "
                    .join("")
                  }
                </tbody>
              </table>
            </div>
        "
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
