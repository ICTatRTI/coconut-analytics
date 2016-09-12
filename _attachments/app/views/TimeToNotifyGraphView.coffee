_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class TimeToNotifyGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>Time To Notify</div>
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
    startDate = options.startDate
    endDate = options.endDate
    Coconut.database.query "caseCountIncludingSecondary",
      startkey: [startDate]
      endkey: [endDate]
      reduce: false
      include_docs: true
    .then (result) =>
      dataForGraph = _.pluck(result.rows, 'doc')
      if (dataForGraph.length == 0  or _.isEmpty(dataForGraph[0]))
        $(".chart_container").html HTMLHelpers.noRecordFound()
        $('#analysis-spinner').hide()
      else
        console.log(dataForGraph)
        dataForGraph.forEach((d) ->
            d.dateICD = new Date(d['Index Case Diagnosis Date']+' ') # extra space at end cause it to use UTC format.
        )
        composite = dc.compositeChart("#chart")
        Graphs.timeToNotify(dataForGraph, composite, options)

        window.onresize = () ->
          HTMLHelpers.resizeChartContainer()
          Graphs.compositeResize(composite, 'chart_container', options)
          
        $('#analysis-spinner').hide()
        
    .catch (error) ->
      console.error error
      $('#analysis-spinner').hide()
    
       
module.exports = TimeToNotifyGraphView
