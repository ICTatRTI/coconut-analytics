_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'

class RainfallReportView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    $('#analysis-spinner').show()
    @$el.html "
      <style>
        .tbl_col { width: 75px}
      </style>
      <div id='dateSelector'></div>
      <div id='messages'></div>
    "
    Coconut.database.query "rainfallDataByDateAndLocation",
      startkey: [moment(options.startDate).year(), moment(options.startDate).week()]
      endkey: [moment(options.endDate).year(), moment(options.endDate).week()]
      include_docs: true
    .catch (error) ->
      coconut.debug "Error: #{JSON.stringify error}"
      console.error error
    .then (results) =>
      $('#analysis-spinner').hide()
      @$el.append "
        <table class='tablesorter mdl-data-table mdl-js-data-table mdl-shadow--2dp' id='rainfallReports'>
          <thead>
            <th class='mdl-data-table__cell--non-numeric'>Station</th>
            <th class='mdl-data-table__cell--non-numeric'>Year</th>
            <th class='mdl-data-table__cell--non-numeric'>Week</th>
            <th class='tbl_col'>Amount</th>
          </thead>
          <tbody>
          #{
             if (results.rows.length == 0)
               "<tr><td colspan='4'><center>No result found...</center></td></tr>"
             else
               _(results.rows).map (row) =>
                 "
                  <tr>
                    <td class='mdl-data-table__cell--non-numeric'>#{row.value[0]}</td>
                      <td class='mdl-data-table__cell--non-numeric'>#{row.key[0]}</td>
                      <td class='mdl-data-table__cell--non-numeric'>#{row.key[1]}</td>
                      <td class='tbl_col'>#{row.value[1]}</td>
                  </tr>
                "
                .join("")
          }
          </tbody>
        </table>
      "
      if (results.rows.length > 0)
        $("#rainfallReports").dataTable
          aaSorting: [[1,"desc"],[2,"desc"]]
          iDisplayLength: 10
          dom: 'T<"clear">lfrtip'
          tableTools:
            sSwfPath: "js-libraries/copy_csv_xls.swf"
            aButtons: [
              "copy",
              "csv",
              "print"
            ]

module.exports = RainfallReportView
