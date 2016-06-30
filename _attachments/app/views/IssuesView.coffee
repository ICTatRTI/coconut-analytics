_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

global.jQuery = require 'jquery'
require 'tablesorter'

humanize = require 'underscore.string/humanize'
Form2js = require 'form2js'
js2form = require 'form2js'
moment = require 'moment'
Pikaday = require 'pikaday'
DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
Issues = require '../models/Issues'
UserCollection = require '../models/UserCollection'
Dialog = require './Dialog'

class IssuesView extends Backbone.View
  dialogEdit = ""
  
  el: "#content"

  events:
    "click button#new-issue-btn": "newIssue"
    "click a.issue-edit": "editIssue"
    "click a.issue-delete": "deleteDialog"
    "click button#formSave" : "saveIssue"
    "click button#formCancel": "formCancel"
    "click button#buttonYes": "deleteIssue"
	  
  formCancel: (e) =>
    dialog.close()
    return false
	
  newIssue: (e) =>
   e.preventDefault
   dialogTitle = "New Issue"
   Dialog.create(dialogEdit, dialogTitle)
   $('form#issue input').val('')
   return false
   
  editIssue: (e) =>
    e.preventDefault
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
       #Form2js.js2form($('form#issue').get(0), issue)
       
     return false

  deleteDialog: (e) =>
    e.preventDefault
    dialogTitle = "Are you sure?"
    Dialog.confirm("This will permanently remove the record.", dialogTitle,['No', 'Yes']) 
    return false
 
 #TODO Need codes to delete doc
  deleteIssue: (e) =>
    console.log("Delete initiated")
    
  saveIssue: =>
    description = $("[name=description]").val()
    if description is ""
      $("#alertMsg").html("Description is required").show().fadeOut(5000)
      return false
    if not @issue?
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
    .then () =>
      console.log("Saving successful")
      Coconut.router.navigate "#activities/type/Issues"
      @render()
#      $("#message").html("Issue saved")
#      .show()
#      .fadeOut(2000) 

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    $('#analysis-spinner').show()
    @$el.html "
      <style>
        .errorMsg { color: red; display: none }
        td.label {vertical-align: top; padding-right: 10px}
        textarea { width: 300px; height: 50px}
      </style>
      <div id='dateSelector'></div>
      <div style='padding: 10px 0'>
        <h4>Issues <button class='mdl-button mdl-js-button mdl-button--icon mdl-button--colored' id='new-issue-btn'>
              <i class='material-icons'>add_circle</i>
            </button></h4>
      </div>
      <dialog id='dialog'>
        <div id='dialogContent'> </div>
      </dialog>
      <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='issuesTable'>
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
               <button class='mdl-button mdl-js-button mdl-button--primary' id='formSave' type='submit' value='save'><i class='material-icons'>save</i> Save</button> &nbsp;
               <button class='mdl-button mdl-js-button mdl-button--primary' id='formCancel' type='submit' value='cancel'><i class='material-icons'>cancel</i> Cancel</button>
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
          $("#content").append "
            <div>No records found...</div>
          "
        else
          $("#issuesTable tbody").html _(issues).map (issue) ->
            date = if issue.Week
              moment(issue.Week, "GGGG-WW").format("YYYY-MM-DD")
            else
              issue["Date Created"]

            "
              <tr>
                <td class='mdl-data-table__cell--non-numeric'>#{issue.Description}</td>
                <td class='mdl-data-table__cell--non-numeric'>#{date}</td>
                <td><center>#{if issue['Assigned To']? then issue['Assigned To'].replace(/user\./,'') else '-'}</center></td>
                <td><center>#{issue['Date Resolved'] or '-'}</center></td>
                <td>
                  <button class='edit mdl-button mdl-js-button mdl-button--icon'>
                   <a href='#' class='issue-edit' data-issue-id='#{issue._id}'><i class='material-icons icon-24'>mode_edit</i></a>
                  </button>
                  <button class='delete mdl-button mdl-js-button mdl-button--icon'>
                  <a href='#' class='issue-delete' data-facility-id='#{issue._id}'><i class='material-icons icon-24'>delete</i></a>
                   </button>
                </td>
              </tr>
            "

          $("#issuesTable").dataTable
            aaSorting: [[1,"desc"]]
            iDisplayLength: 50
            dom: 'T<"clear">lfrtip'
            tableTools:
              sSwfPath: "js-libraries/copy_csv_xls.swf"
              aButtons: [
                "csv",
                ]

    $('#analysis-spinner').hide()

  module.exports = IssuesView
