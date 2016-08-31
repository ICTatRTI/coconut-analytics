_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'
moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class PositiveCasesGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <style>
         .chart_container {height: 600px}
       </style>
       <div id='dateSelector'></div>
       <div class='chart-title'>Number of Positive Malaria Cases</div>
       <div id='chart_container_1' class='chart_container'>
         <div class='mdl-grid'>
           <div class='mdl-cell mdl-cell--12-col mdl-cell--8-col-tablet mdl-cell--4-col-phone'>
             <div id='chart'></div>
           </div>
         </div>
       </div>
    "

    $('#analysis-spinner').show()
    adjustX = 10
    adjustY = 40
    container = 'chart_container_1'
    options.y_axis = 'y_axis_1'
    options.x_axis = 'x_axis_1'
    options.chart = 'chart_1'
    options.renderer = 'bar'
    options.names = ["Age < 5","Age >= 5"]
    chart_width = $('.chart_container').width()-adjustX
    chart_height = $('.chart_container').width()-adjustY
    couch_view1 = "positiveCasesGT5"
    couch_view2 = "positiveCasesLT5"
    container = 'chart_container_1'
    startDate = moment(options.startDate).format('YYYY-MM-DD')
    endDate = moment(options.endDate).format('YYYY-MM-DD')
    Coconut.database.query "#{couch_view1}/#{couch_view1}",
      startkey: startDate
      endkey: endDate
      include_docs: true
    .then (result) =>
      data1ForGraph = _.pluck(result.rows, 'doc')
      Coconut.database.query "#{couch_view2}/#{couch_view2}",
        startkey: startDate
        endkey: endDate
        include_docs: true
      .then (result) =>
        data2ForGraph = _.pluck(result.rows, 'doc')
        if (data1ForGraph.length == 0 and data2ForGraph.length == 0) or (_.isEmpty(data1ForGraph[0]) and _.isEmpty(data2ForGraph[0]))
           $("div##{container}").html("<center><div style='margin-top: 5%'><h6>No records found for date range</h6></div></center>")
           #reject("No record for date range")
           $('#analysis-spinner').hide()
        else
          data1ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults)
          )
          data2ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults) 
          )
          composite = dc.compositeChart("#chart")
          ndx1 = crossfilter(data1ForGraph)
          ndx2 = crossfilter(data2ForGraph)
          
          dim1 = ndx1.dimension((d) ->
            return d.datePR
          )
          dim2 = ndx2.dimension((d) ->
            return d.datePR
          )
          grp1 = dim1.group()
          grp2 = dim2.group()
          
          composite
            .width($('.chart_container').width()-adjustX)
            .height($('.chart_container').height()-adjustY)
            .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
            .y(d3.scale.linear().domain([0,120]))
            .yAxisLabel("Number of Positive Cases")
            .elasticY(true)
            .legend(dc.legend().x($('.chart_container').width()-200).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
            .renderHorizontalGridLines(true)
            .shareTitle(false)
            .compose([
                dc.lineChart(composite)
                  .dimension(dim1)
                  .colors('red')
                  .group(grp1, "Age >= 5")
                  .dashStyle([2,2])
                  .xyTipsOn(true)
                  .renderDataPoints(true)
                  .title((d) ->
                    return d.key.toDateString() + ": " + d.value
                  ),
                dc.lineChart(composite)
                  .dimension(dim2)
                  .colors('blue')
                  .group(grp2, "Age < 5")
                  .dashStyle([5,5])
                  .xyTipsOn(true)
                  .renderDataPoints(true)
                  .title((d) ->
                    return d.key.toDateString() + ": " + d.value
                  )
            ])
            .brushOn(false)
            .render()

          window.onresize = () ->
            composite.legend().x($('.chart_container').width()-200);
            composite
              .width($('.chart_container').width()-adjustX)
              .height($('.chart_container').height()-adjustY)
              .rescale()
              .redraw();
                    
          $('#analysis-spinner').hide()
      .catch (error) ->
        console.error error
        $('#analysis-spinner').hide()
    .catch (error) ->
      console.error error
       
module.exports = PositiveCasesGraphView
