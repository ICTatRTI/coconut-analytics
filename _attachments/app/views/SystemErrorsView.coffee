_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
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
            <table style='border:1px solid black' class='system-errors mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
              <thead>
                <tr>
                  <th class='mdl-data-table__cell--non-numeric'>Time of most recent error</th>
                  <th class='mdl-data-table__cell--non-numeric'>Message</th>
                  <th>Number of errors of this type in last 24 hours</th>
                  <th class='mdl-data-table__cell--non-numeric'>Source</th>
                </tr>
              </thead>
              <tbody>
                #{
                  _.map(errorsByType, (errorData, errorMessage) ->
                    "
                      <tr>
                        <td class='mdl-data-table__cell--non-numeric'>#{errorData["Most Recent"]}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{errorMessage}</td>
                        <td>#{errorData.count}</td>
                        <td class='mdl-data-table__cell--non-numeric'>#{errorData["Source"]}</td>
                      </tr>
                    "
                  ).join("")
                }
              </tbody>
            </table>
          "

    options = Coconut.router.reportViewOptions

module.exports = SystemErrorsView
