_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Graphs = require '../models/Graphs'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class TimeToCompleteGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>Time To Complete</div>
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
        dataForGraph.forEach((d) ->
          UssdDate = moment(d['Ussd Notification: Date']?.substring(0,10))
          CaseNotify = moment(d['Case Notification: Created At']?.substring(0,10))
          d.threshold = CaseNotify.diff(UssdDate,'days')
          d.dateICD = new Date(d['Index Case Diagnosis Date'])
        )
        
        composite = dc.compositeChart("#chart")
        Graphs.timeToComplete(dataForGraph, composite, options)

        window.onresize = () ->
          HTMLHelpers.resizeChartContainer()
          Graphs.compositeResize(composite, 'chart_container', options)
          
        $('#analysis-spinner').hide()
        
    .catch (error) ->
      console.error error
      $('#analysis-spinner').hide()
    
       
module.exports = TimeToCompleteGraphView
