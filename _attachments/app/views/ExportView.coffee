$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $
FileSaver = require 'file-saver'
dasherize = require("underscore.string/dasherize")

class ExportView extends Backbone.View

  events:
    "click button.downloadBtn": "exportData"

  exportData: (e) ->
    btnId = e.target.id
    btnId = btnId.replace(/-/, "") if btnId.indexOf("-") is 0
    console.log(btnId)
    debugger
    @startDate = $('#startDate').val()
    @endDate = $('#endDate').val()
    validDates
      startDate: @startDate
      endDate: @endDate
      error: (error) ->
          console.error error
      success: (result)  =>
         $('#downloadMsg').show()
         $('#analysis-spinner').show()
         Coconut.database.query "results",
           include_docs: true
           startkey: @startDate
           endkey: @endDate
         .then (result) =>
            csv = ""
            keys = []
            _(result.rows).map (row) ->
              unless keys.length > 0
                keys = _(row.doc).chain().keys().without("_id","_rev").value()
                csv = (
                  _(keys).map (key) ->
                    "\"#{key}\""
                  .join(",")
                )

              csv += "\n" + (
                _(keys).map (key) ->
                  "\"#{row.doc[key] or ""}\""
                .join(",")
              )

            blob = new Blob([csv], {type: "text/plain;charset=utf-8"})
            FileSaver.saveAs(blob, "coconut-#{@startDate}-#{@endDate}.csv")
            $('#downloadMsg').hide()
            $('#analysis-spinner').hide()
          .catch (error) -> console.error error

  validDates = (options) =>
    startDate = options.startDate
    endDate = options.endDate
    if startDate? and endDate? and moment(endDate).isAfter(startDate)
      options.success(true)
    else
      options.success(false)



  render: =>
    @$el.html "
      <style>
        .mdl-button--fab.mdl-button--mini-fab.roundBtn {
           height: 33px;
           min-width: 33px;
           width: 33px;
         }
      </style>
      <div id='dateSelector'>
        <div class='content-grid mdl-grid'>
          <div class='mdl-cell'>
            <label for='startDate'>Start Date</label>
            <input id='startDate' type='date'></input>
          </div>
          <div class='mdl-cell'>
            <label for='endDate'>End Date</label>
            <input id='endDate' type='date'></input>
          </div>
        </div>
      </div>
      <div class='scroll-div' >
        <div><small>Specify the Start and End dates and click the approprite icon to download</small></div>
        <table class='mdl-data-table mdl-js-data-table mdl-shadow--2dp'>
          <thead>
            <th></th>
            <th>Kakuma</th>
            <th>Dadaab</th>
            <th>Combined</th>
          </thead>
          <tbody>
            #{
              _([
                "Verification"
                "Enrolled Students"
              ]).map (dataType) ->
                "
                  <tr>
                    <td>#{dataType}</td>
                    <td>
                      <button class='downloadBtn mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored roundBtn'>
                        <i id='#{dasherize(dataType)}-kakuma' class='material-icons mdi-14px'>cloud_download</i>
                      </button>
                    </td>
                    <td>
                      <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored roundBtn'>
                        <i id='#{dasherize(dataType)}-dadaab' class='material-icons mdi-14px'>cloud_download</i>
                      </button>
                    </td>
                    <td>
                      <button class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored roundBtn'>
                        <i id='#{dasherize(dataType)}-combined' class='material-icons mdi-14px'>cloud_download</i>
                      </button>
                    </td>
                  </tr>
                "
              .join ""
            }
          </tbody>
        </table>
      </div>
    "
module.exports = ExportView
