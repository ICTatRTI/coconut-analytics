_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require './Dialog'
FileSaver = require 'file-saver'


class ExportDataView extends Backbone.View
  el: "#content"

  events:
    "click button#export": "exportData"

  exportData: =>

    @startDate = Coconut.dateSelectorView.startDate
    @endDate = Coconut.dateSelectorView.endDate
    $('#downloadMsg').show()
    $('#analysis-spinner').show()

    Coconut.database.query "caseIDsByDate",
      include_docs: true
      startkey: @startDate
      endkey: @endDate
    .then (result) ->
      csv = ""
      _(result.rows).map (row) ->
        unless keys.length > 0
          keys = _(row.doc).chain().keys().without("_id","_rev").value()
          csv = (
            _(keys).map (key) ->
              "\"#{key}\""
            .join(",")
          )

        csv += (
          _(keys).map (key) ->
            "\"#{row.doc[key] or ""}\""
          .join(",")
        )

        blob = new Blob([csv], {type: "text/plain;charset=utf-8"})
        saveAs(blob, "coconut-#{@startDate}-#{@endDate}.csv")
        $('#downloadMsg').hide()
        $('#analysis-spinner').hide()
    .catch (error) -> console.error error
    
#    url = "http://spreadsheet.zmcp.org/spreadsheet_cleaned/#{@startDate}/#{@endDate}"
#
#    startDownload url, (err,response) ->
#      if (err)
#        console.log("Error Downloading file...")
#      else
#        console.log(response)
#        $('#downloadMsg').html('')
#        $('#analysis-spinner').hide()
#        Dialog.createDialogWrap()
#        Dialog.confirm("File download successfully completed...", "Success",["Ok"])
#
#  startDownload = (url, callback) ->
#    window.location.href = url
#    # Need to find a way to detect completion of download before hidng the following message.
#    window.setTimeout ->
#     callback(null, 'Download complete')
#    ,10000


  render: =>
     HTMLHelpers.ChangeTitle("Data Export")
     @$el.html "
        <style>
          #downloadMsg { font-size: 1.2em}
        </style>
        <div id='dateSelector'></div>
        <h4>Download Spreadsheet</h4>
        <button class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored' id='export'><i class='mdi mdi-cloud-download mdi-24px'></i>&nbsp; Download</button>
        <div id='downloadMsg' class='hide m-t-30'>Downloading file now. Please wait...</div>
    "

module.exports = ExportDataView
