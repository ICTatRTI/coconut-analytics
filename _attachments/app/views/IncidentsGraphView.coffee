_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class IncidentsGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <style> 
         .y-axis-label { margin-right: 10px}
       </style>
       <div id='dateSelector'></div>
       <div class='chart-title'>Number of Cases</div>
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
    lastYearStart = moment(options.startDate).subtract(1,'year').format('YYYY-MM-DD')
    lastYearEnd = moment(options.endDate).subtract(1,'year').format('YYYY-MM-DD')

    Coconut.database.query "caseCounter",
      startkey: [startDate]
      endkey: [endDate]
      reduce: false
      include_docs: false
    .then (result) =>
      data1 = result.rows
      if (data1.length == 0 or _.isEmpty(data1[0]))
         $(".chart_container").html HTMLHelpers.noRecordFound()
         $('#analysis-spinner').hide()
      else
        data1.forEach((d) ->
          d.dateWeek = moment(d.key[0]).isoWeek()
        )
        Coconut.database.query "caseCounter",
          startkey: [lastYearStart]
          endkey: [lastYearEnd]
          reduce: false
          include_docs: false
        .then (result2) => 
          data2 = result2.rows 
          data2.forEach((d) ->
            d.dateWeek = moment(d.key[0]).isoWeek()
          )
          
          composite = dc.compositeChart("#chart")
          Graphs.incidents(data1,data2, composite, options)
          $('#analysis-spinner').hide()
          
          window.onresize = () ->
            HTMLHelpers.resizeChartContainer()
            Graphs.compositeResize(composite, 'chart_container', options)
    
          
    .catch (error) ->
      console.error error
      $('#analysis-spinner').hide()
    
module.exports = IncidentsGraphView
