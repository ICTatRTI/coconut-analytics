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
           <div class='mdl-cell mdl-cell--1-col mdl-cell--1-col-tablet mdl-cell--1-col-phone'>   
             <div id='legend' class='legend'></div>
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
    chart_width = 0.8 * $('.chart_container').width()
    chart_height = options.chart_height || 450
    couch_view = "positiveCasesByFacility"
    container = 'chart_container_1'
    startDate = moment(options.startDate).format('YYYY-MM-DD')
    endDate = moment(options.endDate).format('YYYY-MM-DD')
    Coconut.database.query "#{couch_view}/#{couch_view}",
      startkey: startDate
      endkey: endDate
      include_docs: true
    .then (result) =>
      dataForGraph = _.pluck(result.rows, 'doc')
      if dataForGraph.length == 0 or _.isEmpty(dataForGraph[0])
         $("div##{container}").html("<center><div style='margin-top: 5%'><h6>No records found for date range</h6></div></center>")
         #reject("No record for date range")
      else
        chart = dc.barChart("#chart")
        dataForGraph.forEach((x) ->
           x.Age = +x.Age
        )
        ndx = crossfilter(dataForGraph)
        ageDimension  = ndx.dimension( (d) ->
                          return d.Age
        )
        ageSumGroup  = ageDimension.group()
        monthDimension  = ndx.dimension( (d) -> 
                         return new Date(new Date(d.DateofPositiveResults))
                        )
        monthGroup = monthDimension.group()
        
        chart
          .width(768)
          .height(480)
          .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
#          .y(d3.scale.linear().domain([0,100]))
          .brushOn(false)
          .yAxisLabel("Number of cases")
#          .xAxisLabel("This is the X Axis!")
          .dimension(ageDimension)
          .group(monthGroup)
          .on('renderlet', (chart) -> 
              chart.selectAll('rect').on("click", (d) -> 
                console.log("click!", d)
              )
          )
        chart.render()
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
