_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require './Dialog'

class ExportDataView extends Backbone.View
  el: "#content"
  
  events: 
    "click button#export": "exportData"

  exportData: =>
    @startDate = Coconut.dateSelectorView.startDate
    @endDate = Coconut.dateSelectorView.endDate
    $('#downloadMsg').show()
    $('#analysis-spinner').show()
    url = "http://spreadsheet.zmcp.org/spreadsheet_cleaned/#{@startDate}/#{@endDate}"  

    startDownload url, (err,response) ->
      if (err)
        console.log("Error Downloading file...")
      else
        console.log(response)
        $('#downloadMsg').html('')
        $('#analysis-spinner').hide()
        Dialog.createDialogWrap()
        Dialog.confirm("File download successfully completed...", "Success",["Ok"])
 
  startDownload = (url, callback) ->
    window.location.href = url
    # Need to find a way to detect completion of download before hidng the following message.
    window.setTimeout ->
     callback(null, 'Download complete')
    ,10000

      
  render: =>
     @$el.html "
        <style>
          #downloadMsg { font-size: 1.2em}
        </style>
        <div id='dateSelector'></div>
        <h4>Download Spreadsheet</h4>
        <button class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored' id='export'><i class='material-icons'>cloud_download</i>&nbsp; Download</button>
        <div id='downloadMsg' class='hide m-t-30'>Downloading file now. Please wait...</div>
    "

module.exports = ExportDataView