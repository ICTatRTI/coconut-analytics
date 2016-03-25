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
DataTables = require 'datatables'
Reports = require '../models/Reports'
Issues = require '../models/Issues'
UserCollection = require '../models/UserCollection'

class IssuesView extends Backbone.View
  el: "#content"

  events:
    "click button#new-issue-btn": "newIssue"
    "click a.issue-edit": "editIssue"
    "click button#formSave" : "saveIssue"
    "click button#formCancel": "formCancel"

  render: =>
    options = Coconut.router.reportViewOptions
    global.Users = new UserCollection()
    Users.fetch()

    @$el.html "
      <style>
        .errorMsg { color: red; display: none }
        td.label {vertical-align: top; padding-right: 10px}
        textarea { width: 300px; height: 50px}
      </style>
      <div id='dateSelector'></div>
        <div style='padding: 10px 0'>
          <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-issue-btn'>
            <i class='material-icons'>add</i>
          </button></a>
        </div>
        <div id='IssueForm'>
           <div id='issue-form'>
              <div id='form-title'> </div>
              <div class='errorMsg' id='message'></div>
              <form id='issue'>
                <table>
                  <tr>
                    <td class='label'>Description</td>
                    <td><textarea name='description'>#{@issue?.Description || ""}</textarea></td>
                  </tr>
                  <tr>
                    <td class='label'>Assigned To</td>
                    <td><select name='assignedTo'>
                          <option></option>
                         #{
                           Users.map (user) =>
                             userId = user.get "_id"
                             console.log(user)
                             "<option value='#{userId}' #{if @issue?["Assigned To"] is userId then "selected='true'" else ""}>
                                #{user.nameOrUsernameWithDescription()}
                              </option>"
                             .join ""
                          }
                       </select>
                    </td>
                  </tr>
                  <tr>
                    <td class='label'>Action Taken</td>
                    <td><textarea name='actionTaken'>#{@issue?['Action Taken'] || ""}</textarea></td>
                  </tr>
                  <tr>
                    <td class='label'>Solution</td>
                    <td><textarea name='solution'>#{@issue?['Solution'] || ""}</textarea></td>
                  </tr>
                  <tr>
                    <td style='padding-right: 10px'>Date Resolved</td>
                    <td>
                      <input type='date' name='dateResolved' #{
                         if @issue?['Date Resolved']
                           "value = '#{@issue['Date Resolved']}'"
                         else ""
                       }
                    </td>
                  </tr>
                  <tr>
                    <td> </td>
                    <td>
                      <div style='margin-top: 10px; float: right'>
                        <button class='mdl-button mdl-js-button mdl-button--primary' id='formSave'>Save</button> &nbsp;
                        <button class='mdl-button mdl-js-button mdl-button--primary' id='formCancel'>Cancel</button>
                      </div>   
                    </td>
                  </tr>
                </table>
             </form>
          </div>  
        </div>
        <br/>
        <table class='tablesorter' id='issuesTable'>
          <thead>
            <th>Description</th>
            <th>Date Created</th>
            <th>Assigned To</th>
            <th>Date Resolved</th>
          </thead>
          <tbody>
          </tbody>
        </table>	  
    "
    Reports.getIssues
      startDate: options.startDate
      endDate: options.endDate
      error: (error) -> console.log error
      success: (issues) ->
        $("#issuesTable tbody").html _(issues).map (issue) ->

          date = if issue.Week
            moment(issue.Week, "GGGG-WW").format("YYYY-MM-DD")
          else
            issue["Date Created"]

          "
          <tr>
            <td><a href='#' class='issue-edit' data-issue-id='#{issue._id}'>#{issue.Description}</a></td>
            <td>#{date}</td>
            <td>#{issue["Assigned To"] or "-"}</td>
            <td>#{issue["Date Resolved"] or "-"}</td>
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

  issueForm: => "
    <div>
      <label for='description'>Description</label>
      <textarea name='description'>#{@issue?.Description || ""}</textarea>
    </div>

    <div>
      <label for='assignedTo'>Assigned To</label>
      <select name='assignedTo'>
        <option></option>
        #{
          Users.map (user) =>
            userId = user.get "_id"
            "<option value='#{userId}' #{if @issue?["Assigned To"] is userId then "selected='true'" else ""}>
              #{user.nameOrUsernameWithDescription()}
             </option>"
          .join ""
        }
      </select>
    </div>

    <div>
      <label for='actionTaken'>Action Taken</label>
      <textarea name='actionTaken'>#{@issue?['Action Taken'] || ""}</textarea>
    </div>

    <div>
      <label for='solution'>Solution</label>
      <textarea name='solution'>#{@issue?['Solution'] || ""}</textarea>
    </div>

    <div>
      <label for='dateResolved'>Date Resolved</label>
      <input type='date' name='dateResolved' #{
        if @issue?['Date Resolved']
          "value = '#{@issue['Date Resolved']}'"
        else ""
      }
    </div>
    <div>
      <button id='save'>Save</button>
    </div>
    </input>
  "
  
  formCancel: (e) =>
    e.preventDefault
    $('#IssueForm').slideUp()
	
  newIssue: (e) =>
   e.preventDefault
   $('#form-title').html("New Issue")
   $('#IssueForm').slideToggle()
   $('form#issue input').val('')
   
  editIssue: (e) =>
    $('#form-title').html("Edit Issue")
    $('#IssueForm').slideDown()

    issueID = $(e.target).closest("a").attr "data-issue-id"
    Coconut.database.get issueID,
       include_docs: true
    .catch (error) -> console.error error
    .then (issue) =>
       @issue = _.clone(issue)
       Form2js.js2form($('form#issue').get(0), issue)
     return false

  saveIssue: =>
    description = $("[name=description]").val()
    if description is ""
      $("#message").html("Issue must have a description to be saved")
      .show()
      .fadeOut(5000)
      return

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
      $("#message").html("Error saving issue: #{JSON.stringify error}")
      .show()
      .fadeOut(10000)
    .then () =>
      Coconut.router.navigate "#activities/type/Issues"
      @render()
#      $("#message").html("Issue saved")
#      .show()
#      .fadeOut(2000) 

module.exports = IssuesView
