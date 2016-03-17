_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
PouchDB = require 'pouchdb'
moment = require 'moment'

DataTables = require 'datatables'
Reports = require '../models/Reports'

class RainfallreportView extends Backbone.View
  el: "#content"

  render: =>
    options = Coconut.router.reportViewOptions
    $('#analysis-spinner').show()
    @$el.html "
      <div id='dateSelector'></div>
      <div id='messages'></div>
      <h3>Rainfall Data Submission</h3>
      <table class='tablesorter' id='rainfallReports'>
        <thead>
          <th>Station</th>
          <th>Year</th>
          <th>Week</th>
          <th>Amount</th>
        </thead>
        <tbody>
    "
    Coconut.database.query "zanzibar-server/rainfallDataByDateAndLocation",
      startkey: [moment(options.startDate).year(), moment(options.startDate).week()]
      endkey: [moment(options.endDate).year(), moment(options.endDate).week()] 
      include_docs: true
    .catch (error) -> console.error error
    .then (results) =>
       $('#analysis-spinner').hide()
       @$el.append "
          #{
              _(results.rows).map (row) =>
                "
                  <tr>
                    <td>#{row.value[0]}</td>
                    <td>#{row.key[0]}</td>
                    <td>#{row.key[1]}</td>
                    <td>#{row.value[1]}</td>
                  </tr>
                "
              .join("")
            }
          </tbody>
        </table>
      "

    $("#rainfallReports").dataTable
      aaSorting: [[1,"desc"],[2,"desc"]]
      iDisplayLength: 50
      dom: 'T<"clear">lfrtip'
      tableTools:
        sSwfPath: "js-libraries/copy_csv_xls.swf"
        aButtons: [
          "copy",
          "csv",
          "print"
        ]

module.exports = RainfallreportView
