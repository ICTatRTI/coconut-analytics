_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'

class AttendanceGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    title= "Attendance"
    HTMLHelpers.ChangeTitle("Graphs: " + title)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>#{title}</div>
       <div id='chart_container_1' class='chart_container'>
         <div class='mdl-grid'>
           <div class='mdl-cell mdl-cell--12-col mdl-cell--8-col-tablet mdl-cell--4-col-phone'>
             <div id='errMsg'></div>
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
    startWeek = ("00" + moment(options.startDate).isoWeek().toString()).slice(-2)
    endYear = moment(options.endDate).isoWeekYear().toString()
    endWeek = ("00" + moment(options.endDate).isoWeek().toString()).slice(-2)
    Coconut.weeklyFacilityDatabase.query "weeklyDataCounter",
      start_key: [startYear, startWeek]
      end_key: [endYear,endWeek,{}]
      reduce: true
      group: true
      include_docs: false
    .then (result) =>
      dataForGraph = result.rows
      composite = dc.compositeChart("#chart")
      Graphs.attendance(dataForGraph, composite, 'chart_container_1', options)
      $('#analysis-spinner').hide()
      
      window.onresize = () ->
        HTMLHelpers.resizeChartContainer()
        Graphs.compositeResize(composite, 'chart_container', options)
                    
    .catch (error) ->
      console.error error
      $('#errMsg').html("Sorry. Unable to complete due to an error: </br>"+error)
      $('#analysis-spinner').hide()
    
module.exports = AttendanceGraphView
