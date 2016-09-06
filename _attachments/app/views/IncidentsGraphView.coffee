_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class IncidentsGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
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
    adjustX = 10
    adjustY = 40
    startDate = options.startDate
    endDate = options.endDate
    Coconut.database.query "caseIndexIncludingSecondary/caseIndexIncludingSecondary",
      startkey: [startDate]
      endkey: [endDate]
      include_docs: true
    .then (result) =>
      dataForGraph = _.pluck(result.rows, 'doc')
      if (dataForGraph.length == 0 or _.isEmpty(dataForGraph[0]))
         $(".chart_container").html HTMLHelpers.noRecordFound()
         $('#analysis-spinner').hide()
      else
        dataForGraph.forEach((d) ->
          d.dateICD = new Date(d['Index Case Diagnosis Date']+' ') # extra space at end cause it to use UTC format.
        )
        chart = dc.lineChart("#chart")
        ndx = crossfilter(dataForGraph)
        dim = ndx.dimension((d) ->
          return d['Index Case Diagnosis Date Iso Week']
        )
        grp = dim.group()
        chart
          .width($('.chart_container').width()-adjustX)
          .height($('.chart_container').height()-adjustY)
          .x(d3.scale.linear())
          .y(d3.scale.linear().domain([0,120]))
          .yAxisLabel("Number of Incidents")
          .xAxisLabel("Weeks")
          .elasticY(true)
          .renderHorizontalGridLines(true)
          .renderArea(true)
          .dimension(dim)
          .colors('red')
          .group(grp)
          .xyTipsOn(true)
          .xUnits(d3.time.weeks)
          .elasticX(true)
          .renderDataPoints(false)
          .title((d) ->
            return 'Week: '+ d.key + ": " + d.value
          )
          .brushOn(false)

        chart.render()

        window.onresize = () ->
          HTMLHelpers.resizeChartContainer()
          chart
            .width($('.chart_container').width()-adjustX)
            .height($('.chart_container').height()-adjustY)
            .rescale()
            .redraw();
                  
        $('#analysis-spinner').hide()
    .catch (error) ->
      console.error error
      $('#analysis-spinner').hide()
    
module.exports = IncidentsGraphView
