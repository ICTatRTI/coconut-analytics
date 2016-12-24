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
  .domain(['green','orange','yellow','red','grey','blue','purple'])
  .range(['#2ca02c','#ff9900','#ffff00', '#dc3912', '#808080', '#1f77b4','#9467bd'])

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

 Graphs.timeToNotify = (dataGraph, chart, container, options) ->
     dataForGraph = _.filter(dataGraph, (d) ->
        return ((d.key[1].match( /Between Positive Result And Notification From Facility/) and d.value is 1) or (d.key[1] is "Has Notification" and d.value is 0))
     )

     legendLabel = ["Within 24 hrs","24 to 48 hrs","48 to 72 hrs", "72+ hrs",  "No notification"]
     dataForGraph.forEach((d) ->
       switch d.key[1]
         when "Less Than One Day Between Positive Result And Notification From Facility" then return d.series = legendLabel[0]
         when "One To Two Days Between Positive Result And Notification From Facility" then return d.series = legendLabel[1]
         when "Two To Three Days Between Positive Result And Notification From Facility" then return d.series = legendLabel[2]
         when "More Than Three Days Between Positive Result And Notification From Facility" then return d.series = legendLabel[3]
         when "Has Notification" then return d.series = legendLabel[4]
     )
     
     ndx = crossfilter(dataForGraph)
     dateDimension = ndx.dimension((d) ->
       moment(d.key[0])
     )

     sumGroup = dateDimension.group().reduce((p,v) ->
       p.total = (p.total || 0) + 1
       p[v.series] = (p[v.series] || 0) + 1
       return p
     ,(p,v) ->
       p.total = (p.total || 0) - 1
       p[v.series] = (p[v.series] || 0) - 1
       return p
     ,() ->
       #initalize to zero to ensure the same number of stacks on each bar. Otherwise bar will not show. 
       return {"Within 24 hrs":0, "24 to 48 hrs":0, "48 to 72 hrs":0, "72+ hrs":0, "No notification":0}
     )
     
     if (options.pct100)
       sumGroup.all().forEach((d) ->
          d.value['Within 24 hrs'] = +(((d.value['Within 24 hrs'] / d.value['total']) *100).toFixed(2))
          d.value['24 to 48 hrs'] = +(((d.value['24 to 48 hrs'] / d.value['total']) *100).toFixed(2))
          d.value['48 to 72 hrs'] = +(((d.value['48 to 72 hrs'] / d.value['total']) *100).toFixed(2))
          d.value['72+ hrs'] = +(((d.value['72+ hrs'] / d.value['total']) *100).toFixed(2))
          d.value['No notification'] = +(((d.value['No notification'] / d.value['total']) *100).toFixed(2))
       )
     
     yAxis_label =  if(options.pct100) then "Proportion of Malaria Cases %" else "Number of Cases"
       
     @sel_stack = (i) ->
       return (d) ->
           return d.value[i]
     
     chart
       .width($('.chart_container').width() - options.adjustX)
       .height($('.chart_container').height() - options.adjustY)
       .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
       .y(d3.scale.linear().domain([0,100]))
       .yAxisLabel(yAxis_label)
       .elasticY(true)
       .xUnits(d3.time.days)
       .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
       .brushOn(false)
       .clipPadding(20)
       .renderLabel(false)
       .dimension(dateDimension)
       .group(sumGroup,legendLabel[0], @sel_stack(legendLabel[0]))
       .centerBar(true)
       .gap(1)
       .title((d) ->
         return (d.key).format("MMM-DD") + ' : ' + d.value[this.layer]
         )
       .ordinalColors(['#2ca02c','#ff9900','#ffff00', '#dc3912', '#808080', '#1f77b4','#9467bd'])
     dc.override(chart, 'legendables', () ->
       items = chart._legendables()
       return items.reverse()
     )
     chart.stack(sumGroup, legendLabel[i-1], @sel_stack(legendLabel[i-1])) for i in [2..5]
     chart.render()
     Graphs.axis_adjust(chart, container)

 Graphs.timeToComplete = (dataGraph, chart, container, options) ->
   dataChart = _.filter(dataGraph, (d) ->
     return ((d.key[1].match( /Between Positive Result And Complete Household/) and d.value is 1) or (d.key[1] is "Followed Up" and d.value is 0))
   )

   legendLabel = ["Within 24 hrs","24 to 48 hrs","48 to 72 hrs", "72+ hrs", "Not followed up"]
   dataChart.forEach((d) ->
     switch d.key[1]
       when "Less Than One Day Between Positive Result And Complete Household" then return d.series = legendLabel[0]
       when "One To Two Days Between Positive Result And Complete Household" then return d.series = legendLabel[1]
       when "Two To Three Days Between Positive Result And Complete Household" then return d.series = legendLabel[2]
       when "More Than Three Days Between Positive Result And Complete Household" then return d.series = legendLabel[3]
       when "Followed Up" then return d.series = legendLabel[4]
   )

   ndx = crossfilter(dataChart)
   dateDimension = ndx.dimension((d) ->
     moment(d.key[0])
   )

   sumGroup = dateDimension.group().reduce((p,v) ->
     p.total = (p.total || 0) + 1
     p[v.series] = (p[v.series] || 0) + 1
     return p
   ,(p,v) ->
     p.total = (p.total || 0) - 1
     p[v.series] = (p[v.series] || 0) - 1
     return p
   ,(p,v) ->
     #initalize to zero to ensure the same number of stacks on each bar. Otherwise bar will not show.
     return {'Not followed up': 0, 'Within 24 hrs': 0, '72+ hrs': 0, '24 to 48 hrs': 0, '48 to 72 hrs': 0}
   )

   if (options.pct100)
     sumGroup.all().forEach((d) ->
       d.value['Within 24 hrs'] = +(((d.value['Within 24 hrs'] / d.value['total']) *100).toFixed(2))
       d.value['24 to 48 hrs'] = +(((d.value['24 to 48 hrs'] / d.value['total']) *100).toFixed(2))
       d.value['48 to 72 hrs'] = +(((d.value['48 to 72 hrs'] / d.value['total']) *100).toFixed(2))
       d.value['72+ hrs'] = +(((d.value['72+ hrs'] / d.value['total']) *100).toFixed(2))
       d.value['Not followed up'] = +(((d.value['Not followed up'] / d.value['total']) *100).toFixed(2))
     )
   
   yAxis_label =  if(options.pct100) then "Proportion of Malaria Cases %" else "Number of Cases"
   
   @sel_stack = (i) ->
     return (d) ->
         return d.value[i]
   
   chart
     .width($('.chart_container').width() - options.adjustX)
     .height($('.chart_container').height() - options.adjustY)
     .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
     .y(d3.scale.linear())
     .yAxisLabel(yAxis_label)
     .elasticY(true)
     .xUnits(d3.time.days)
     .legend(dc.legend().x($('.chart_container').width()-150).y(0).gap(5).legendWidth(140))
     .brushOn(false)
     .clipPadding(20)
     .renderLabel(false)
     .dimension(dateDimension)
     .group(sumGroup,legendLabel[0], @sel_stack(legendLabel[0]))
     .centerBar(true)
     .gap(1)
     .title((d) ->
       return (d.key).format("MMM-DD") + ' : ' + d.value[this.layer]
       )
      .ordinalColors(['#2ca02c','#ff9900','#ffff00', '#dc3912', '#808080', '#1f77b4','#9467bd']) 
   dc.override(chart, 'legendables', () ->
     items = chart._legendables()
     return items.reverse()
   )
   chart.stack(sumGroup, legendLabel[i-1], @sel_stack(legendLabel[i-1])) for i in [2..5]
   chart.render()
   Graphs.axis_adjust(chart, container)
   
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
