_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class ExportDataView extends Backbone.View
  el: "#content"
  
  events: 
    "click button#export": "exportData"

  exportData: =>
    $('#downloadMsg').show()
    $('#analysis-spinner').show()
    window.location.href = "http://spreadsheet.zmcp.org/spreadsheet_cleaned/#{@startDate}/#{@endDate}"
    # Need to find a way to detect completion of download before hidng the following message.
    window.setTimeout ->
      $('#downloadMsg').hide()
      $('#analysis-spinner').hide()
    ,10000
    
  render: =>
     @$el.html "
        <div id='dateSelector'></div>
        <h4>Download Spreadsheet</h4>
        <button class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored' id='export'><i class='material-icons'>cloud_download</i>&nbsp; Download</button>
        <div id='downloadMsg' class='hide m-t-30'>Download file now. Please wait...</div>
    "

module.exports = ExportDataView