_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'
Reports = require '../models/Reports'

class WeeklysummaryView extends Backbone.View
  el: "#content"

  events:
    "click button#dateFilter": "showForm"
  
  showForm: (e) =>
    e.preventDefault
    $("div#filters-section").slideToggle()

  render: =>
      options = Coconut.router.reportViewOptions
      $('#analysis-spinner').show()
      @$el.html "
        <div id='dateSelector'></div>
        <div id='messages'></div>
        <h3>Data Summary</h3>
      "
      $('#analysis-spinner').hide()
module.exports = WeeklysummaryView
