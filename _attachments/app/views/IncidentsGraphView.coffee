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
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='mdl-cell mdl-cell--8-col mdl-cell--4-col-tablet'>
         <div class='chart-title'>Incidence Graph</div>
         <div id='chart_container_1' class='chart_container'>
           <div id='y_axis_1' class='y_axis'></div>
           <div id='chart_1' class='chart'></div>
         </div>
       </div>
       <div class='mdl-cell mdl-cell--4-col mdl-cell--4-col-tablet'></div>
    "
    $('#analysis-spinner').show()
    options.container = 'chart_container_1'
    options.y_axis = 'y_axis_1'
    options.chart = 'chart_1'
    Graphs.IncidentsGraph options, (err, response) ->
      if (err) then console.log(err)
      $('#analysis-spinner').hide()
       
module.exports = IncidentsGraphView
