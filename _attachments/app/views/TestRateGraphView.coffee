_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class TestRateGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>Test Rate</div>
       <div id='chart_container_1' class='chart_container'>
         <div class='mdl-grid'>
           <div class='mdl-cell mdl-cell--12-col mdl-cell--8-col-tablet mdl-cell--4-col-phone'>
             <div id='chart'></div>
           </div>
         </div>
       </div>
    "
    HTMLHelpers.resizeChartContainer()
    $('#analysis-spinner').show()
    options.adjustX = 10
    options.adjustY = 40
    startYear = moment(options.startDate).isoWeekYear().toString()
    startWeek = moment(options.startDate).isoWeek().toString()
    endYear = moment(options.endDate).isoWeekYear().toString()
    endWeek = moment(options.endDate).isoWeek().toString()
    Coconut.database.query "weeklyDataCounter",
      startkey: [startYear,startWeek]
      endkey: [endYear,endWeek,{}]
      reduce: true
      group: true
      include_docs: false
    .then (result) =>
      dataForGraph = result.rows
      if (dataForGraph.length == 0 or _.isEmpty(dataForGraph[0]))
         $(".chart_container").html HTMLHelpers.noRecordFound()
         $('#analysis-spinner').hide()
      else
        dataForGraph.forEach((d) ->
          d.dateWeek = moment(d.key[0] + "-" + d.key[1], "GGGG-WW")
        )
        composite = dc.compositeChart("#chart")
        Graphs.testRate(dataForGraph, composite, options)

        window.onresize = () ->
          HTMLHelpers.resizeChartContainer()
          Graphs.compositeResize(composite, 'chart_container', options)
                  
        $('#analysis-spinner').hide()
    .catch (error) ->
      console.error error
      $('#analysis-spinner').hide()
  
module.exports = TestRateGraphView
