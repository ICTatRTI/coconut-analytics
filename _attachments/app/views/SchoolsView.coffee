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
School = require '../models/School'
crypto = require('crypto')

class SchoolsView extends Backbone.View
    el:'#content'

    events:
      "click #new-school-btn": "createSchool"
      "click a.school-edit": "editSchool"
      "click a.school-delete": "deleteSchool"
      "click #schoolSave": "formSave"
      "click #schoolCancel": "formCancel"

    setMode: (mode) ->
      $('input#mode').val(mode)
      if mode == 'edit'
        $('#div_password').hide()
        $('form#school input#_id').prop('readonly', true)
      else
        $('form#school input#_id').prop('readonly', false)

    createSchool: (e) =>
      e.preventDefault
      dialogTitle = "Add New School"
      Dialog.create(@dialogEdit, dialogTitle)
      $('form#school input').val('')
      @school = null
      @setMode('add')
      return false

    editSchool: (e) =>
      e.preventDefault
      dialogTitle = "Edit School"
      Dialog.create(@dialogEdit, dialogTitle)
      @setMode('edit')
      id = $(e.target).closest("a").attr "data-school-id"

      Coconut.database.get id,
         include_docs: true
      .catch (error) -> console.error error
      .then (school) =>
         @school = _.clone(school)
         school._id = school._id.substring(5)
         Form2js.js2form($('form#user').get(0), school)
         if(@school.roles)
           #older doc store this as string and not array
           @school.roles = @school.roles.split(',') if !($.isArray(@school.roles))
           for role in @school.roles
             document.querySelector("##{role}_label").MaterialCheckbox.check() if(role)
         if(school.inactive)
           document.querySelector('#switch-1').MaterialSwitch.on()
         Dialog.markTextfieldDirty()
       return false

    formSave: (e) =>
      errorMsg = ""
      errorMsg += 'Username, ' if $('#_id').val() == ''
      errorMsg += 'Password, ' if $('input#mode').val() == 'add' and $('#passwd').val() == ''
      errorMsg += 'Name, ' if $('#name').val() == ''

      if errorMsg != ''
        errorMsg = 'Required field(s): ' + errorMsg.slice(0, -2)
        $('#errMsg').html(errorMsg)
        return false
      else
        if not @school
          @school = {
            _id: "school." + $("#_id").val()
          }

        @school.collection = "school"
        @school.inactive = $("#inactive").is(":checked")
        @school.isApplicationDoc = true
        @school.password = $('#passwd').val()
        @sschool.name = $('#name').val()
        @school.email = $('#email').val()
        @school.roles = $('#roles').val()
        @school.comments = $('#comments').val()
        @school.password = (crypto.pbkdf2Sync @school.password, '', 1000, 256/8, 'sha256').toString('base64') if @school.password != ""
        roles_selected = document.getElementsByName("role")

        roles = []
        _.map roles_selected, (role) ->
          roles.push(role.id) if role.checked

        @school.roles = roles
        Coconut.database.put @school
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

    deleteSchool: (e) =>
      view = @
      e.preventDefault
      id = $(e.target).closest("a").attr "data-school-id"
      dialogTitle = "Are you sure?"
      Dialog.confirm("This will permanently remove the record id #{id}.", dialogTitle,['No', 'Yes'])
      dialog.addEventListener 'close', (event) ->
        if (dialog.returnValue == 'Yes')
          Coconut.database.get(id).then (doc) ->
            return Coconut.database.remove(doc)
          .then (result) =>
            Dialog.confirm( 'School Successfully Deleted..', 'Delete School',['Ok'])
            view.render()
          .catch (error) ->
            console.error error
            Dialog.confirm( error, 'Error Encountered while deleting',['Ok'])

      return false

    formCancel: (e) =>
      e.preventDefault
      dialog.close() if dialog.open
      return false

    render: =>
      HTMLHelpers.ChangeTitle("Admin: Schools")
      Coconut.schoolsDb.allDocs
        startkey: "school-",
        endkey: "school-\ufff0"
        include_docs: true
      .catch (error) -> console.error error
      .then (result) =>
        schools = _(result.rows).pluck("doc")
        console.log(schools)
        @fields =  "_id,password,name".split(",")
        @dialogEdit = "
          <form id='school' method='dialog'>
             <div id='dialog-title'> </div>
             <div id='errMsg'></div>
             <input type='hidden' id='mode' value='' />
             #{
                _.map( @fields, (field) =>
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

        @$el.html "
            <h4>Schools <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-school-btn'>
              <i class='mdi mdi-plus mdi-36px'></i>
            </button></h4>
            <dialog id='dialog'>
              <div id='dialogContent'> </div>
            </dialog>

            <div id='results' class='result'>
              <table class='summary tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
                <thead>
                  <tr>
                  <th class='header headerSortUp mdl-data-table__cell--non-numeric'>School ID</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Name</th>
                  <th class='header mdl-data-table__cell--non-numeric'>County</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Region</th>
                  <th class='header mdl-data-table__cell--non-numeric'>District</th>
                  <th class='header mdl-data-table__cell--non-numeric'>Location</th>
                  <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  #{
                    _(schools).map (school) ->
                      console.log(school)
                      "
                      <tr>
                        <td class='mdl-data-table__cell--non-numeric'>#{school._id.substring(7)}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{school.Name}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{school.County || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{school.Region || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{school.District || ''}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{school.Location}</td>
                        <td>
                         <button id='edit-menu_#{school._id}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                            <i class='mdi mdi-dots-vertical mdi-24px'></i>
                          </button>
                          <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='edit-menu_#{school._id}'>
                            <li class='mdl-menu__item'><a href='#' class='school-edit' data-school-id='#{school._id}'><i class='mdi mdi-pencil mdi-24px'></i> Edit School</a></li>
                            <li class='mdl-menu__item'><a href='#' class='school-delete' data-school-id='#{school._id}'><i class='mdi mdi-delete mdi-24px'></i> Delete School</a></li>
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

module.exports = SchoolsView
