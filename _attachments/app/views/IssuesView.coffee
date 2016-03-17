_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
Reports = require '../models/Reports'

class IssuesView extends Backbone.View
  el: "#content"

  render: =>
    options = Coconut.router.reportViewOptions

    @$el.html "
      <div id='dateSelector'></div>
      <h4>Issues</h4>
        <a href='#new/issue'>
        <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' id='new-user-btn'>
          <i class='material-icons'>add</i>
        </button></a>
        
        <br/>
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
        console.log issues
        $("#issuesTable tbody").html _(issues).map (issue) ->

          date = if issue.Week
            moment(issue.Week, "GGGG-WW").format("YYYY-MM-DD")
          else
            issue["Date Created"]

          "
          <tr>
            <td><a href='#show/issue/#{issue._id}'>#{issue.Description}</a></td>
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
    
 
module.exports = IssuesView
