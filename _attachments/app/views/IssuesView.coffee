_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

moment = require 'moment'
DataTables = require( 'datatables.net' )()
# Buttons = require('datatables.net-buttons')()
# require( 'datatables.net-buttons/js/buttons.colVis.js' )() # Column visibility
# require( 'datatables.net-buttons/js/buttons.html5.js' )()  # HTML 5 file export
# require( 'datatables.net-buttons/js/buttons.flash.js' )()  # Flash file export
# require( 'datatables.net-buttons/js/buttons.print.js' )()  # Print View button

Reports = require '../models/Reports'
Issues = require '../models/Issues'
User = require '../models/User'
UserCollection = require '../models/UserCollection'
Dialog = require './Dialog'

class IssuesView extends Backbone.View
  dialogEdit = ""

  el: "#content"

  events:
    "click button#new-issue-btn": "newIssue"
    "click a.issue-edit": "editIssue"
    "click a.issue-delete": "deleteIssue"
    "click button#issueSave" : "saveIssue"
    "click button#issueCancel": "formCancel"

  formCancel: (e) =>
    dialog.close() if dialog.open
    return false

  newIssue: (e) =>
   e.preventDefault
   @mode = "create"
   dialogTitle = "New Issue"
   Dialog.create(dialogEdit, dialogTitle)
   $('form#issue input').val('')
   return false

  editIssue: (e) =>
    e.preventDefault
    @mode = "edit"
    dialogTitle = "Edit Issue"
    Dialog.create(dialogEdit, dialogTitle)
    Dialog.markTextfieldDirty()
    issueID = $(e.target).closest("a").attr "data-issue-id"
    Coconut.database.get issueID,
       include_docs: true
    .catch (error) ->
      console.error error
      Dialog.confirm(error, 'Error Encountered',['Ok'])
    .then (issue) =>
       @issue = _.clone(issue)
       $("[name=description]").val(@issue.Description)
       $("[name=assignedTo]").val(@issue["Assigned To"])
       $("[name=actionTaken]").val(@issue["Action Taken"])
       $("[name=solution]").val(@issue.Solution)
       $("[name=dateResolved]").val(@issue["Date Resolved"])

     return false

  deleteIssue: (e) =>
    view = @
    e.preventDefault
    id = $(e.target).closest("a").attr "data-issue-id"
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record id: #{id}.", dialogTitle,['No', 'Yes'])
    dialog.addEventListener 'close', (event) ->
      if (dialog.returnValue == 'Yes')
        Coconut.database.get(id).then (doc) ->
          return Coconut.database.remove(doc)
        .then (result) =>
          Dialog.confirm( 'Issue Successfully Deleted..', 'Delete Issue',['Ok'])
          Backbone.history.loadUrl(Backbone.history.fragment)
        .catch (error) ->
          console.error error
          Dialog.confirm( error, 'Error Encountered while deleting',['Ok'])

    return false

  saveIssue: =>
    description = $("[name=description]").val()
    if description is ""
      $("#alertMsg").html("Description is required").show().fadeOut(5000)
      return false
    if @mode is 'create'
      dateCreated = moment().format("YYYY-MM-DD HH:mm:ss")
      @issue = {
        _id: "issue-#{dateCreated}-#{description.substr(0,10)}"
        "Date Created": dateCreated
      }

    @issue["Updated At"] = [] unless @issue["Updated At"]
    @issue["Updated At"].push moment().format("YYYY-MM-DD HH:mm:ss")
    @issue.Description = description
    @issue["Assigned To"] = $("[name=assignedTo]").val()
    @issue["Action Taken"] = $("[name=actionTaken]").val()
    @issue.Solution = $("[name=solution]").val()
    @issue["Date Resolved"] = $("[name=dateResolved]").val()

    Coconut.database.put @issue
    .catch (error) ->
      console.error error
      Dialog.confirm(error, 'Error Encountered',['Ok'])
      #$("#message").html("Error saving issue: #{JSON.stringify error}").show().fadeOut(10000)
      return false
    .then (result) =>
      Backbone.history.loadUrl(Backbone.history.fragment)

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    $('#analysis-spinner').show()
    HTMLHelpers.ChangeTitle("Activities: Issues")
    @$el.html "
      <style>
        .errorMsg { color: red; display: none }
        td.label {vertical-align: top; padding-right: 10px}
        textarea { width: 300px; height: 50px}
      </style>
      <div id='dateSelector'></div>
      <div style='padding: 10px 0'>
        <h4>Issues <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-issue-btn'>
              <i class='mdi mdi-plus mdi-36px'></i>
            </button></h4>
      </div>
      <dialog id='dialog'>
        <div id='dialogContent'> </div>
      </dialog>
      <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='issuesTable' width='100%'>
        <thead>
          <th class='mdl-data-table__cell--non-numeric'>Description</th>
          <th class='mdl-data-table__cell--non-numeric'>Date Created</th>
          <th class='mdl-data-table__cell--non-numeric'>Assigned To</th>
          <th class='mdl-data-table__cell--non-numeric'>Date Resolved</th>
          <th class='action'>Action</th>
        </thead>
        <tbody>
        </tbody>
      </table>
      "
    users = new UserCollection()
    users.fetch
# Could be a bug in puchdb-backbone that it does not recognize error or success. It will execute error function regardless.
#      error: (error) ->
#        console.log JSON.stringify error
#        console.log("Error received")

      success: () ->
        dialogEdit = "
          <form id='issue' method='dialog'>
             <div id='dialog-title'> </div>
             <div id='message' class='errorMsg'></div>
             <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <textarea class='mdl-textfield__input' type='text' rows='3' id='description' name='description'>#{@issue?.Description || ""}</textarea>
               <label class='mdl-textfield__label' for='description'>Description</label>
               <div id='alertMsg' class='errorMsg'></div>
             </div>
             <div class='mdl-select mdl-js-select mdl-select--floating-label'>
               <select class='mdl-select__input' id='assignedTo' name='assignedTo'>
                 <option value=''></option>
                 #{
                   users.map (user) =>
                     userId = user.get "_id"
                     "<option value='#{userId}' #{if @issue?["Assigned To"] is userId then "selected='true'" else ""}>
                       #{user.nameOrUsernameWithDescription()}
                      </option>"
                   .join ""
                 }
               </select>
               <label class='mdl-select__label' for='assignedTo'>Assigned To</label>
             </div>
             <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <textarea class='mdl-textfield__input' type='text' rows='3' id='actionTaken' name='actionTaken'>#{@issue?['Action Taken'] || ""}</textarea>
               <label class='mdl-textfield__label' for='actionTaken'>Action Taken</label>
             </div>
             <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
               <textarea class='mdl-textfield__input' type='text' rows='3' id='solution' name='solution'>#{@issue?['Solution'] || ""}</textarea>
               <label class='mdl-textfield__label' for='solution'>Solution</label>
             </div>
             <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                <input class='mdl-textfield__input datepicker' type='text'' id='dateResolved' #{
                     if @issue?['Date Resolved']
                       "value = '#{@issue['Date Resolved']}'"
                     else ""
                     } >
                 <label class='mdl-textfield__label' for='dateResolved'>Date Resolved</label>
             </div>
             <div id='dialogActions'>
               <button class='mdl-button mdl-js-button mdl-button--primary' id='issueSave' type='submit' value='save'><i class='mdi mdi-content-save mdi-24px'></i> Save</button> &nbsp;
               <button class='mdl-button mdl-js-button mdl-button--primary' id='issueCancel' type='submit' value='cancel'><i class='mdi mdi-close-circle mdi-24px'></i> Cancel</button>
             </div>
          </form>
        "
        @dialogConfirm = "
          <form method='dialog'>
            <div id='dialog-title'> </div>
            <div>This will permanently remove the record.</div>
            <div id='dialogActions'>
              <button type='submit' id='buttonYes' class='mdl-button mdl-js-button mdl-button--primary' value='yes'>Yes</button>
              <button type='submit' id='buttonNo' class='mdl-button mdl-js-button mdl-button--primary' value='no' autofocus>No</button>
            </div>
          </form>
        "

    Reports.getIssues
      startDate: options.startDate
      endDate: options.endDate
      error: (error) -> console.error error
      success: (issues) ->
        if (issues.length == 0)
          $("#issuesTable tbody").html "<tr><td colspan='5'><center>No records found...</center></td></tr>"
          $('#analysis-spinner').hide()
        else
          completed = _.after issues.length, ->
            $("#issuesTable tbody").html("")
            _(issues).map (Issue) =>
              $("#issuesTable tbody").append "
                 <tr>
                   <td class='mdl-data-table__cell--non-numeric'>#{Issue.Description}</td>
                   <td class='mdl-data-table__cell--non-numeric'>#{Issue["Date Created"]}</td>
                   <td class='mdl-data-table__cell--non-numeric'>#{Issue.FullName}</td>
                   <td class='mdl-data-table__cell--non-numeric'>#{Issue['Date Resolved'] or '-'}</td>
                   <td>
                     <button id='edit-menu_#{Issue._id}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                        <i class='mdi mdi-dots-vertical mdi-24px'></i>
                     </button>
                     <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='edit-menu_#{Issue._id}'>
                        <li class='mdl-menu__item'><a href='#' class='issue-edit' data-issue-id='#{Issue._id}'><i class='mdi mdi-pencil mdi-24px'></i> Edit</a></li>
                        <li class='mdl-menu__item'><a href='#' class='issue-delete' data-issue-id='#{Issue._id}'><i class='mdi mdi-delete mdi-24px'></i> Delete</a></li>
                     </ul>
                   </td>
                 </tr>
              "
            componentHandler.upgradeDom()
            datatable = $("#issuesTable").DataTable
              'order': [[1,"desc"]]
              "pagingType": "full_numbers"
              "dom": '<"top"fl>rt<"bottom"ip><"clear">'
              "lengthMenu": [[10, 25, 50, -1], [10, 25, 50, "All"]]
              "retrieve": true
              "buttons": [
                "csv",'excel','pdf'
                ]

            $('#analysis-spinner').hide()

          _(issues).map (issue) ->
            if (issue['Assigned To'] is "" or issue['Assigned To'] is undefined)
              issue.FullName = '-'
              completed()
            else
             Coconut.database.get issue['Assigned To']
              .catch (error) ->
                  console.error error
                  issue.FullName = '-'
                  completed()
              .then (user) =>
                if user?._id == undefined
                  issue.FullName = '-'
                else
                  issue.FullName=  "#{user.name}#{ if user.district then ' - ' + user.district else ''}".trim()
                completed()

  module.exports = IssuesView
