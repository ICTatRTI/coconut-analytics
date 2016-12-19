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
         .y-axis-label { margin-right: 20px}
       </style>
       <div class='chart-title'>Number of Positive Cases for Current and Last Year</div>
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
#    startDate = options.startDate
#    endDate = options.endDate
#    lastYearStart = moment(options.startDate).subtract(1,'year').format('YYYY-MM-DD')
#    lastYearEnd = moment(options.endDate).subtract(1,'year').format('YYYY-MM-DD')
    startDate = (moment().year()+'-01-01')
    endDate = (moment().year()+'-12-31')
    lastYearStart = moment(startDate).subtract(1,'year').format('YYYY-MM-DD')
    lastYearEnd = moment(endDate).subtract(1,'year').format('YYYY-MM-DD')


    Coconut.database.query "caseCounter",
      startkey: [lastYearStart]
      endkey: [endDate]
      reduce: false
      include_docs: false
    .then (result) =>
      data = result.rows
      if (data.length == 0 or _.isEmpty(data[0]))
         $(".chart_container").html HTMLHelpers.noRecordFound()
         $('#analysis-spinner').hide()
      else
        dataForGraph1 = _.filter(data, (d) ->
          return d.key[1] is "Number Positive Cases Including Index" and d.key[0] >= startDate
        )
        dataForGraph2 = _.filter(data, (d) ->
          return d.key[1] is "Number Positive Cases Including Index" and d.key[0] < startDate
        )
        composite = dc.compositeChart("#chart")
        Graphs.incidents(dataForGraph1, dataForGraph2, composite, 'container_1', options, () ->
          $('#analysis-spinner').hide()
        )

        window.onresize = () ->
          HTMLHelpers.resizeChartContainer()
          Graphs.compositeResize(composite, 'chart_container', options)
          
    .catch (error) ->
      console.error error
      $('#analysis-spinner').hide()
    
module.exports = IncidentsGraphView
