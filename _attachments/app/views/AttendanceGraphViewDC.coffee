_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Reports = require '../models/Reports'
moment = require 'moment'
Graphs = require '../models/Graphs'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class AttendanceGraphViewDC extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>Attendance (DC Version)</div>
       <div id='chart_container_1' class='chart_container'>
         <div class='mdl-grid'>
           <div class='mdl-cell mdl-cell--11-col mdl-cell--7-col-tablet mdl-cell--3-col-phone'>
             <div id='chart'></div>
           </div>
         </div>
       </div>
    "
    
    $('#analysis-spinner').show()
    container = 'chart_container_1'
    options.y_axis = 'y_axis_1'
    options.x_axis = 'x_axis_1'
    options.chart = 'chart_1'
    options.renderer = 'bar'
    options.names = ["Age < 5","Age >= 5"]
    chart_width = $('.chart_container').width()
    chart_height = options.chart_height || 450
    couch_view1 = "positiveCasesByFacilityGTE5"
    couch_view2 = "positiveCasesByFacilityLT5"
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
          composite = dc.compositeChart("#chart")
          ndx1 = crossfilter(data1ForGraph)
          ndx2 = crossfilter(data2ForGraph)
          dim1 = ndx1.dimension((d) ->
            return new Date(d.DateofPositiveResults)
          )
          dim2 = ndx2.dimension((d) ->
            return new Date(d.DateofPositiveResults)
          )
          grp1 = dim1.group()
          grp2 = dim2.group()
          composite
            .width(0.9*chart_width)
            .height(480)
            .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
            .y(d3.scale.linear().domain([0,80]))
            .yAxisLabel("Number of Cases")
            .legend(dc.legend().x(0.7*chart_width).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
            .renderHorizontalGridLines(true)
#            .gap(65)
            .compose([
                dc.lineChart(composite)
                    .dimension(dim1)
                    .colors('red')
                    .group(grp1, "Age >= 5")
                    .dashStyle([2,2]),
                dc.lineChart(composite)
                    .dimension(dim2)
                    .colors('blue')
                    .group(grp2, "Age < 5")
                    .dashStyle([5,5])
            ])
            .brushOn(false)
            .render()
          $('#analysis-spinner').hide()
      .catch (error) ->
        console.error error
        $('#analysis-spinner').hide()
    .catch (error) ->
      console.error error
    #
    # Graphs.create options
    # .catch (err) ->
    #   console.error err
    # .then () ->
    #   $('#analysis-spinner').hide()
    
module.exports = AttendanceGraphViewDC
