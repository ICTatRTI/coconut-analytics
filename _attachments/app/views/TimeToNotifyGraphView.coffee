_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'

class TimeToNotifyGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    title= "Time To Notify"
    HTMLHelpers.ChangeTitle("Graphs: " + title)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>#{title} (#{Coconut.config.case_notification} hours)</div>
       <div id='chart_container_1' class='chart_container'>
         <div class='mdl-grid'>
           <div class='mdl-cell mdl-cell--12-col mdl-cell--8-col-tablet mdl-cell--4-col-phone'>
             <div id='errMsg'></div>
             <div id='chart'></div>
           </div>
         </div>
       </div>
       <br />
       <hr />
       <div id='chart_container_2' class='chart_container'>
         <div class='mdl-grid'>
           <div class='mdl-cell mdl-cell--12-col mdl-cell--8-col-tablet mdl-cell--4-col-phone'>
             <div id='errMsg'></div>
             <div id='chart2'></div>
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
    Coconut.reportingDatabase.query "caseCounter",
      startkey: [startDate]
      endkey: [endDate,{}]
      reduce: false
      include_docs: false
    .then (result) =>
      dataForGraph = for row in result.rows
        row.key = [row.key[0],row.key[2]] # remove district info
        row
      chart = dc.barChart("#chart")
      options.pct100 = false
      Graphs.timeToNotify(dataForGraph, chart, 'chart_container_1', options)
      chart2 = dc.barChart("#chart2")
      options.pct100 = true
      Graphs.timeToNotify(dataForGraph, chart2, 'chart_container_2', options)
      window.onresize = () ->
        HTMLHelpers.resizeChartContainer()
        Graphs.chartResize(chart, 'chart_container',options)
        Graphs.chartResize(chart2, 'chart_container',options)
        
      $('#analysis-spinner').hide()
        
    .catch (error) ->
      console.error error
      $('#errMsg').html("Sorry. Unable to complete due to an error: </br>"+error)
      $('#analysis-spinner').hide()
    
       
module.exports = TimeToNotifyGraphView
