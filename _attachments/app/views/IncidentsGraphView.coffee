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
    startDate = moment(options.startDate).format('YYYY-MM-DD')
    endDate = moment(options.endDate).format('YYYY-MM-DD')
    Coconut.database.query "caseCountIncludingSecondary/caseCountIncludingSecondary",
      startkey: [startDate]
      endkey: [endDate]
      include_docs: true
    .then (result) =>
      data1ForGraph = _.pluck(result.rows, 'doc')
      if (data1ForGraph.length == 0 or _.isEmpty(data1ForGraph[0]))
         $(".chart_container").html HTMLHelpers.noRecordFound()
         $('#analysis-spinner').hide()
      else
        data1ForGraph.forEach((d) ->
          d.datePR = new Date(d['Index Case Diagnosis Date'])
        )
        chart = dc.lineChart("#chart")
        ndx = crossfilter(data1ForGraph)
        
        dim = ndx.dimension((d) ->
          return d3.time.week(d.datePR)
        )

        grp = dim.group((d) ->
          return d3.time.week(d)
        )

        chart
          .width($('.chart_container').width()-adjustX)
          .height($('.chart_container').height()-adjustY)
          .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
          .y(d3.scale.linear().domain([0,120]))
          .yAxisLabel("Number of Incidents")
          .xAxisLabel("Week")
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
            week = moment(d.key).week()
            return 'Week: '+ week + ": " + d.value
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
