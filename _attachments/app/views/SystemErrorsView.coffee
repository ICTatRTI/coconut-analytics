_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
Reports = require '../models/Reports'

class SystemErrorsView extends Backbone.View
  el: "#content"

  render: =>
    @$el.html "
        <div id='dateSelector'></div>
        <h4>The following system errors have occurred in the last 2 days:</h4>
    "
    $('#analysis-spinner').show()
    Reports.systemErrors
      success: (errorsByType) =>
        $("#analysis-spinner").hide()
        if _(errorsByType).isEmpty()
          @$el.append "No system errors."
        else
          alerts = true

          @$el.append "
            <table style='border:1px solid black' class='system-errors'>
              <thead>
                <tr>
                  <th>Time of most recent error</th>
                  <th>Message</th>
                  <th>Number of errors of this type in last 24 hours</th>
                  <th>Source</th>
                </tr>
              </thead>
              <tbody>
                #{
                  _.map(errorsByType, (errorData, errorMessage) ->
                    "
                      <tr>
                        <td>#{errorData["Most Recent"]}</td>
                        <td>#{errorMessage}</td>
                        <td>#{errorData.count}</td>
                        <td>#{errorData["Source"]}</td>
                      </tr>
                    "
                  ).join("")
                }
              </tbody>
            </table>
          "
        @afterFinished()

    options = Coconut.router.reportViewOptions

module.exports = SystemErrorsView
