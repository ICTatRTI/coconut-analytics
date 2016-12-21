_ = require 'underscore'
moment = require 'moment'

dc = require 'dc'
d3 = require 'd3'
d3-scale = require 'd3-scale'
crossfilter = require 'crossfilter'

class Graphs
colorScale = d3.scale.category10()
colorScale.domain([0,1,2,3,4,5,6,7,8,9])
# Example to set customizecolors
colorScale2 = d3.scale.ordinal()
  .domain(['green','orange','yellow','red','blue','purple', 'grey'])
  .range(['#2ca02c','#ff9900','#ffff00', '#dc3912','#1f77b4','#9467bd', '#808080'])

Graphs.chartResize = (chart, container, options) ->
  width = $(".#{container}").width() - options.adjustX
  height = $(".#{container}").height() - options.adjustY
  chart
    .width(width)
    .height(height)
    .rescale()
    .redraw()

Graphs.axis_adjust = (chart, container) ->
  #this adjust the y-axis title to prevent title overlapping on ticks
  #unless there is data for date range, there will not be a chart inside container, and hence a null.
  newHeight = chart.height()+10
  unless d3.select("##{container} g.x.axis")[0][0] is null
    xAxis = d3.transform(d3.select("##{container} g.x.axis").attr("transform"))
    xAxis_x = xAxis.translate[0]
    xAxis_y = xAxis.translate[1]
    yAxis = d3.transform(d3.select("##{container} g.y.axis").attr("transform"))
    yAxis_x = yAxis.translate[0]
    yAxis_y = yAxis.translate[1]
    chart.select('.x.axis').attr("transform","translate(55,#{xAxis_y})")
    chart.select('.y.axis').attr("transform","translate(55,#{yAxis_y})")
    chart.selectAll('.chart-body').attr("transform","translate(55,#{yAxis_y})")
    chart.select('svg').attr('height', newHeight)
    chart.selectAll('g.x text')
      .attr('transform', 'translate(-10,10) rotate(315)')

Graphs.compositeResize = (composite, container, options) ->
  width = $(".#{container}").width() - options.adjustX
  height = $(".#{container}").height() - options.adjustY
  composite
    .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
    .y(d3.scale.linear().domain([0,120]))
    .width(width)
    .height(height)
    .legend(dc.legend().x($(".#{container}").width()-150).y(20).gap(5).legendWidth(140))
    .rescale()
    .redraw()
    .on('renderlet',(chart) =>
      Graphs.axis_adjust(chart, container)
    )
  
Graphs.incidents = (dataForGraph1, dataForGraph2, composite, container, options,callback) ->
  ndx1 = crossfilter(dataForGraph1)
  ndx2 = crossfilter(dataForGraph2)
  dim1 = ndx1.dimension((d) ->
    return moment(d.key[0]).isoWeek()
  )
  dim2 = ndx2.dimension((d) ->
    return moment(d.key[0]).isoWeek()
  )

  grp1 = dim1.group()
  grp2 = dim2.group()
  
  composite
    .width($('.chart_container').width()-options.adjustX)
    .height($('.chart_container').height()-options.adjustY)
    .x(d3.scale.linear())
    .y(d3.scale.linear().domain([0,120]))
    .xUnits(d3.time.weeks)
    .yAxisLabel("Number of Cases")
    .xAxisLabel("Weeks")
    .elasticY(true)
    .elasticX(true)
    .shareTitle(false)
    .renderHorizontalGridLines(true)
    .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
    .on('renderlet',(chart) =>
      Graphs.axis_adjust(chart, container)
      chart.selectAll('g.x text')
        .attr('transform', 'translate(0,0) rotate(0)')
    )
    .compose([
      dc.lineChart(composite)
        .dimension(dim2)
        .colors(colorScale(1))
        .group(grp2, "Last Year")
        .xyTipsOn(true)
        .renderArea(true)        
        .renderDataPoints(false)
        .title((d) ->
          return 'Week: ' +d.key + ": " + d.value
        ),
      dc.lineChart(composite)
        .dimension(dim1)
        .colors(colorScale(0))
        .group(grp1, "Current")
        .xyTipsOn(true)
        .renderArea(true)
        .renderDataPoints(false)
        .title((d) ->
          return 'Week: ' +d.key + ": " + d.value
        )

    ])
    .brushOn(false)
    .render()
    
  callback(true)
  
Graphs.positiveCases = (dataForGraph, composite, container, options) ->
  
  data1 = _.filter(dataForGraph, (d) ->
    return d.key[1] is "Over 5" and d.value is 1
  )

  data2 = _.filter(dataForGraph, (d) ->
    return d.key[1] is "Under 5" and d.value is 1
  )

  ndx1 = crossfilter(data1)
  ndx2 = crossfilter(data2)

  dim1 = ndx1.dimension((d) ->
    return moment(d.key[0])
  )
  dim2 = ndx2.dimension((d) ->
    return moment(d.key[0])
  )
  grpGTE5 = dim1.group().reduceSum((d) ->
      return d.value
     )
  grpLT5 = dim2.group().reduceSum((d) ->
      return d.value
     )

  composite
    .width($('.chart_container').width()-options.adjustX)
    .height($('.chart_container').height()-options.adjustY)
    .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
    .y(d3.scale.linear().domain([0,120]))
    .yAxisLabel("Number of Cases")
    .elasticY(true)
    .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
    .renderHorizontalGridLines(true)
    .shareTitle(false)
    .renderlet((chart) ->
      Graphs.axis_adjust(chart, container)
      
    )
    .compose([
      dc.lineChart(composite)
        .dimension(dim1)
        .colors(colorScale(0))
        .group(grpGTE5, "Age 5+")
        .xyTipsOn(true)
        .renderDataPoints(false)
        .title((d) ->
          return d.key.format("YYYY-MM-DD") + ": " + d.value
        ),
      dc.lineChart(composite)
        .dimension(dim2)
        .colors(colorScale(1))
        .group(grpLT5, "Age < 5")
        .xyTipsOn(true)
        .renderDataPoints(false)
        .title((d) ->
          return d.key.format("YYYY-MM-DD") + ": " + d.value
        )
    ])
    .brushOn(false)
    .render()
  

Graphs.attendance = (dataForGraph, composite2, container, options) ->
    data3a = _.filter(dataForGraph, (d) ->
      return d.key[3] is 'All OPD >= 5'
    )

    data3b = _.filter(dataForGraph, (d) ->
      return d.key[3] is 'All OPD < 5'
    )
    
    ndx3a = crossfilter(data3a)
    ndx3b = crossfilter(data3b)
    
    dim3a = ndx3a.dimension((d) ->
      return moment(d.key[0] + "-" + d.key[1], "GGGG-WW")
    )

    dim3b = ndx3b.dimension((d) ->
      return moment(d.key[0] + "-" + d.key[1], "GGGG-WW")
    )

    grp1 = dim3a.group().reduceSum((d) ->
      return d.value
     )

    grp2 = dim3b.group().reduceSum((d) ->
      return d.value
     )
    
    composite2
      .width($('.chart_container').width()-options.adjustX)
      .height($('.chart_container').height()-options.adjustY)
      .x(d3.time.scale())
      .y(d3.scale.linear())
      .yAxisLabel("Number of OPD Cases")
      .elasticX(true)
      .elasticY(true)
      .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
      .renderHorizontalGridLines(true)
      .shareTitle(false)
      .xUnits(d3.time.week)
      .renderlet((chart) ->
        Graphs.axis_adjust(chart, container)
       )
      .compose([
        dc.lineChart(composite2)
          .dimension(dim3a)
          .colors(colorScale(0))
          .group(grp1, "Age 5+")
          .xyTipsOn(true)
          .renderDataPoints(false)
          .title((d) ->
            return 'Week: '+ (d.key).isoWeek() + ": " + d.value
           ),
        dc.lineChart(composite2)
          .dimension(dim3b)
          .colors(colorScale(1))
          .group(grp2, "Age < 5")
          .xyTipsOn(true)
          .renderDataPoints(false)
          .title((d) ->
            return 'Week: '+ (d.key).isoWeek()+ ": " + d.value
           )
        ])
      .brushOn(false)
      .render()
 
 Graphs.testRate = (dataForGraph, composite, container, options) ->

    groupedByDate = {}
    _(dataForGraph).each (v, index) ->
      groupedByDate[v.key[0]+v.key[1]] = {} unless groupedByDate[v.key[0]+v.key[1]]
      groupedByDate[v.key[0]+v.key[1]][v.key[3]] = v.value
      groupedByDate[v.key[0]+v.key[1]]['dateWeek'] = v.dateWeek

    _(groupedByDate).each (indicatorAndValue, date) ->
      groupedByDate[date]["Test Rate < 5"] = Math.round(((groupedByDate[date]["Mal NEG < 5"] + groupedByDate[date]["Mal POS < 5"]) / groupedByDate[date]["All OPD < 5"])*100)
      groupedByDate[date]["Test Rate >= 5"] = Math.round(((groupedByDate[date]["Mal NEG >= 5"] + groupedByDate[date]["Mal POS >= 5"]) / groupedByDate[date]["All OPD >= 5"])*100)

    # convert to array
    graphData = _.map(groupedByDate, (value, index) ->
       return value
    )
     
    ndx = crossfilter(graphData)
    dim = ndx.dimension((d) ->
      return d.dateWeek
    )

    grpGTE5_3 = dim.group().reduceSum((d) ->
      return d['Test Rate >= 5']
    )

    grpLT5_3 = dim.group().reduceSum((d) ->
      return d['Test Rate < 5']
    )

    composite
     .width($('.chart_container').width() - options.adjustX)
     .height($('.chart_container').height() - options.adjustY)
     .x(d3.time.scale())
     .y(d3.scale.linear())
     .xUnits(d3.time.week)
     .yAxisLabel("Proportion of OPD Cases Tested Positive [%]")
     .elasticY(true)
     .elasticX(true)
     .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
     .renderHorizontalGridLines(true)
     .shareTitle(false)
     .renderlet((chart) ->
       Graphs.axis_adjust(chart, container)
     )
     .compose([
         dc.lineChart(composite)  
           .dimension(dim)
           .colors(colorScale(0))
           .group(grpGTE5_3, "Test rate [5+]")
           .xyTipsOn(true)
           .renderDataPoints(false)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value + '%'
            ),
         dc.lineChart(composite)
           .dimension(dim)
           .colors(colorScale(1))
           .group(grpLT5_3, "Test rate [< 5]")
           .xyTipsOn(true)
           .renderDataPoints(false)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value + '%'
           )
     ])
     .brushOn(false)
     .render()

 Graphs.timeToNotify = (dataForGraph, composite, container, options) ->
     data1 = _.filter(dataForGraph, (d) ->
       return (d.key[1] is "Less Than One Day Between Positive Result And Notification From Facility" and d.value is 1)
     )
     data2 = _.filter(dataForGraph, (d) ->
       return (d.key[1] is "One To Two Days Between Positive Result And Notification From Facility" and d.value is 1)
     )
     data3 = _.filter(dataForGraph, (d) ->
       return (d.key[1] is  "Two To Three Days Between Positive Result And Notification From Facility" and d.value is 1)
     )
     data4 = _.filter(dataForGraph, (d) ->
       return (d.key[1] is "More Than Three Days Between Positive Result And Notification From Facility" and d.value is 1)
     )
     data5 = _.filter(dataForGraph, (d) ->
       return (d.key[1] is "Has Notification" and d.value is 0)
     )
     
     ndx1 = crossfilter(data1)
     ndx2 = crossfilter(data2)
     ndx3 = crossfilter(data3)
     ndx4 = crossfilter(data4)
     ndx5 = crossfilter(data5)

     dim1 = ndx1.dimension((d) ->
       return moment(d.key[0])
     )
     dim2 = ndx2.dimension((d) ->
       return moment(d.key[0])
     )
     dim3 = ndx3.dimension((d) ->
       return moment(d.key[0])
     )
     dim4 = ndx4.dimension((d) ->
       return moment(d.key[0])
     )
     dim5 = ndx5.dimension((d) ->
       return moment(d.key[0])
     )
     grp1 = dim1.group()
     grp2 = dim2.group()
     grp3 = dim3.group()
     grp4 = dim4.group()
     grp5 = dim5.group()

     composite
       .width($('.chart_container').width() - options.adjustX)
       .height($('.chart_container').height() - options.adjustY)
       .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
       .y(d3.scale.linear())
       .yAxisLabel("Number of Cases")
       .elasticY(true)
       .xUnits(d3.time.days)
       .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
       .renderHorizontalGridLines(true)
       .shareTitle(false)
       .renderlet((chart) ->
         Graphs.axis_adjust(chart, container)
       )
       .compose([
         dc.barChart(composite)
           .dimension(dim5)
           .group(grp5, "No notification")
           .colors(colorScale2('grey'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim4)
           .group(grp4, "72+ hrs")
           .colors(colorScale2('red'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
            ),
         dc.barChart(composite)
           .dimension(dim3)
           .group(grp3, "48 to 72 hrs")
           .colors(colorScale2('orange'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim2)
           .group(grp2, "24 to 48 hrs")
           .colors(colorScale2('yellow'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim1)
           .group(grp1, "Within 24 hrs")
           .colors(colorScale2('green'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             )
       ])
       .brushOn(false)
       .render()

 Graphs.timeToComplete = (dataForGraph, composite, container, options) ->

    data1 = _.filter(dataForGraph, (d) ->
      return (d.key[1] is "Less Than One Day Between Positive Result And Complete Household" and d.value is 1)
    )
    data2 = _.filter(dataForGraph, (d) ->
      return (d.key[1] is "One To Two Days Between Positive Result And Complete Household" and d.value is 1)
    )
    data3 = _.filter(dataForGraph, (d) ->
      return (d.key[1] is  "Two To Three Days Between Positive Result And Complete Household" and d.value is 1)
    )
    data4 = _.filter(dataForGraph, (d) ->
      return (d.key[1] is "More Than Three Days Between Positive Result And Complete Household" and d.value is 1)
    )
    data5 = _.filter(dataForGraph, (d) ->
      return (d.key[1] is "Followed Up" and d.value is 0)
    )
   
    ndx1 = crossfilter(data1)
    ndx2 = crossfilter(data2)
    ndx3 = crossfilter(data3)
    ndx4 = crossfilter(data4)
    ndx5 = crossfilter(data5)
    
    dim1 = ndx1.dimension((d) ->
      return  moment(d.key[0])
    )

    dim2 = ndx2.dimension((d) ->
      return  moment(d.key[0])
    )

    dim3 = ndx3.dimension((d) ->
      return  moment(d.key[0])
    )
    dim4 = ndx4.dimension((d) ->
      return  moment(d.key[0])
    )
    dim5 = ndx5.dimension((d) ->
      return  moment(d.key[0])
    )
    grp1 = dim1.group()
    grp2 = dim2.group()
    grp3 = dim3.group()
    grp4 = dim4.group()
    grp5 = dim5.group()
    
    composite
       .width($('.chart_container').width() - options.adjustX)
       .height($('.chart_container').height() - options.adjustY)
       .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
       .y(d3.scale.linear())
       .yAxisLabel("Number of Cases")
       .elasticY(true)
       .elasticX(true)
       .xUnits(d3.time.days)
       .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
       .renderHorizontalGridLines(true)
       .shareTitle(false)
       .renderlet((chart) ->
         Graphs.axis_adjust(chart, container)
       )
       .compose([
         dc.barChart(composite)
           .dimension(dim5)
           .group(grp5, "Not followed up")
           .colors(colorScale2('grey'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
            ),
         dc.barChart(composite)
           .dimension(dim4)
           .group(grp4, "72+ hrs")
           .colors(colorScale2('red'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
            ),
         dc.barChart(composite)
           .dimension(dim3)
           .group(grp3, "48 to 72 hrs")
           .colors(colorScale2('orange'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim2)
           .group(grp2, "24 to 48 hrs")
           .colors(colorScale2('yellow'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim1)
           .group(grp1, "Within 24 hrs")
           .colors(colorScale2('green'))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ (d.key).isoWeek() + ": " + d.value
             )
       ])
       .brushOn(false)
       .render()

 Graphs.positivityCases = (dataForGraph, composite, container, options) ->
  
   data1 = _.filter(dataForGraph, (d) ->
     return (d.key[1] is "Has Notification" and d.value is 1)
   )

   data2 = _.filter(dataForGraph, (d) ->
     return (d.key[1] is "Number Household Members Tested Positive" and d.value > 0)
   )
   data3 = _.filter(dataForGraph, (d) ->
     return (d.key[1] is "Number Household Members Tested" and d.value > 0)
   )
   
   ndx1 = crossfilter(data1)
   ndx2 = crossfilter(data2)
   ndx3 = crossfilter(data3)

   dim1 = ndx1.dimension((d) ->
     return moment(d.key[0])
   )
   dim2 = ndx2.dimension((d) ->
     return moment(d.key[0])
   )
   dim3 = ndx3.dimension((d) ->
     return moment(d.key[0])
   )
   grp1 = dim1.group().reduceSum((d) ->
       return d.value
   )
   grp2 = dim2.group().reduceSum((d) ->
       return d.value
     )
   grp3 = dim3.group().reduceSum((d) ->
       return d.value
     )

   composite
     .width($('.chart_container').width()-options.adjustX)
     .height($('.chart_container').height()-options.adjustY)
     .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
     .y(d3.scale.linear())
     .yAxisLabel("Number of Cases")
     .elasticY(true)
     .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
     .renderHorizontalGridLines(true)
     .shareTitle(false)
     .renderlet((chart) ->
       Graphs.axis_adjust(chart, container)
     )
     .compose([
       dc.lineChart(composite)
         .dimension(dim1)
         .colors(colorScale(0))
         .group(grp1, "Cases Has Notifcation")
         .xyTipsOn(true)
         .renderDataPoints(false)
         .title((d) ->
           return (d.key).format("YYYY-MM-DD") + ": " + d.value
         )
       dc.lineChart(composite)
         .dimension(dim2)
         .colors(colorScale(1))
         .group(grp2, "Positive Hse Member")
         .xyTipsOn(true)
         .renderDataPoints(false)
         .title((d) ->
           return (d.key).format("YYYY-MM-DD") + ": " + d.value
         )
       dc.lineChart(composite)
         .dimension(dim3)
         .colors(colorScale(2))
         .group(grp3, "Tested Hse Member")
         .xyTipsOn(true)
         .renderDataPoints(false)
         .title((d) ->
           return (d.key).format("YYYY-MM-DD") + ": " + d.value
         )
     ])
     .brushOn(false)
     .render()
    
module.exports = Graphs
