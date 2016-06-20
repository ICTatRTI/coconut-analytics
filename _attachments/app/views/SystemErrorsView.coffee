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
        <div id='resultMsg'><h6>The following system errors have occurred in the date range specified:</h6></div>
        <table id='sysErrors' style='border:1px solid black' class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <thead>
            <tr>
              <th class='mdl-data-table__cell--non-numeric'>Time of most recent error</th>
              <th class='mdl-data-table__cell--non-numeric'>Message</th>
              <th>Number of errors of this type in last 24 hours</th>
              <th class='mdl-data-table__cell--non-numeric'>Source</th>
            </tr>
          </thead>
          <tbody></tbody>
        </table>
    "
    $('#analysis-spinner').show()
    options = Coconut.router.reportViewOptions
    Reports.systemErrors
      startDate: options.startDate
      endDate: options.endDate
      success: (errorsByType) =>
        $("#analysis-spinner").hide()
        if _(errorsByType).isEmpty()
          $('table#sysErrors tbody').html "<tr><td colspan='4'><center>No system errors found...</td></tr>"
        else
          alerts = true
          $('table#sysErrors tbody').html "
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
          "

    options = Coconut.router.reportViewOptions

module.exports = SystemErrorsView
