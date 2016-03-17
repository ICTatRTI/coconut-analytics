_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class ExportDataView extends Backbone.View
  el: "#content"
  
  events: 
    "click button#export": "exportData"

  exportData: =>
    console.log("Exporting Data")

  render: =>
    @$el.html "
        <div id='dateSelector'></div>
        <h3>Download Spreadsheet</h3>
        <button class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored' id='export'>Download</button>
    "

module.exports = ExportDataView