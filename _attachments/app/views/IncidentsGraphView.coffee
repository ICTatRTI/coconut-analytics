_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
moment = require 'moment'
Graphs = require '../models/Graphs'

class IncidentsGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = Coconut.router.reportViewOptions
    @$el.html "
       <div id='dateSelector'></div>
       <div id='chart_container'>
         <div id='y_axis'></div>
         <div id='chart'></div>
       </div>
    "
    $('#analysis-spinner').show()
    options.container = 'chart_container'
    options.y_axis = 'y_axis'
    options.chart = 'chart'
    Graphs.IncidentsGraph options, (err, response) ->
      if (err) then console.log(err)
      $('#analysis-spinner').hide()
       
module.exports = IncidentsGraphView
