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
# colorScale2 = d3.scale.ordinal()
#   .domain(['banana','cherry','blueberry'])
#   .range(['#eeff00','#ff0022','#2200ff'])

Graphs.chartResize = (chart, container, options) ->
  width = $(".#{container}").width() - options.adjustX
  height = $(".#{container}").height() - options.adjustY
  chart
    .width(width)
    .height(height)
    .rescale()
    .redraw()
  
Graphs.compositeResize = (composite, container, options) ->
  width = $(".#{container}").width() - options.adjustX
  height = $(".#{container}").height() - options.adjustY
  composite
    .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
    .y(d3.scale.linear().domain([0,120]))
    .width(width)
    .height(height)
    .legend(dc.legend().x($(".#{container}").width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
    .rescale()
    .redraw()
  
Graphs.incidents = (dataForGraph, chart, options) ->

  ndx = crossfilter(dataForGraph)
  dim = ndx.dimension((d) ->
    return d['Index Case Diagnosis Date Iso Week']
  )

  grp = dim.group()
 
  chart
    .width($('.chart_container').width()-options.adjustX)
    .height($('.chart_container').height()-options.adjustY)
    .x(d3.scale.linear())
    .y(d3.scale.linear())
    .yAxisLabel("Number of Cases")
    .xAxisLabel("Weeks")
    .elasticY(true)
    .renderHorizontalGridLines(true)
    .renderArea(true)
    .dimension(dim)
    .colors(colorScale(3))
    .group(grp)
    .xyTipsOn(true)
    .xUnits(d3.time.weeks)
    .elasticX(true)
    .renderDataPoints(false)
    .title((d) ->
      return 'Week: '+ d.key + ": " + d.value
    )
    .brushOn(false)
    .render()
  
Graphs.positiveCases = (dataForGraph, composite, options) ->
  
  data1 = _.filter(dataForGraph, (d) ->
    return !d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
  )
  data2 = _.filter(dataForGraph, (d) ->
    return d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
  )

  ndx1 = crossfilter(data1)
  ndx2 = crossfilter(data2)

  dim1 = ndx1.dimension((d) ->
    return d.dateICD
  )
  dim2 = ndx2.dimension((d) ->
    return d.dateICD
  )
  grpGTE5 = dim1.group()
  grpLT5 = dim2.group()

  composite
    .width($('.chart_container').width()-options.adjustX)
    .height($('.chart_container').height()-options.adjustY)
    .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
    .y(d3.scale.linear().domain([0,120]))
    .yAxisLabel("Number of Positive Cases")
    .elasticY(true)
    .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
    .renderHorizontalGridLines(true)
    .shareTitle(false)
    .compose([
      dc.lineChart(composite)
        .dimension(dim1)
        .colors(colorScale(0))
        .group(grpGTE5, "Age 5+")
        .xyTipsOn(true)
        .renderDataPoints(false)
        .title((d) ->
          return d.key.toDateString() + ": " + d.value
        ),
      dc.lineChart(composite)
        .dimension(dim2)
        .colors(colorScale(1))
        .group(grpLT5, "Age < 5")
        .xyTipsOn(true)
        .renderDataPoints(false)
        .title((d) ->
          return d.key.toDateString() + ": " + d.value
        )
    ])
    .brushOn(false)
    .render()
  

Graphs.attendance = (dataForGraph, composite2, options) ->
    data3a = _.filter(dataForGraph, (d) ->
      return d.key[3] is 'All OPD >= 5'
    )

    data3b = _.filter(dataForGraph, (d) ->
      return d.key[3] is 'All OPD < 5'
    )
    
    ndx3a = crossfilter(data3a)
    ndx3b = crossfilter(data3b)
    
    dim3a = ndx3a.dimension((d) ->
      return d.dateWeek
    )

    dim3b = ndx3b.dimension((d) ->
      return d.dateWeek
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
#      .x(d3.scale.linear())
      .y(d3.scale.linear())
      .yAxisLabel("Number of OPD Cases")
      .elasticX(true)
      .elasticY(true)
      .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
      .renderHorizontalGridLines(true)
      .shareTitle(false)
#      .xUnits(d3.time.weeks)
      .xUnits(d3.time.week)
      .compose([
        dc.lineChart(composite2)
          .dimension(dim3a)
          .colors(colorScale(0))
          .group(grp1, "Age >= 5")
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
 
 
 Graphs.testRate = (dataForGraph, composite, options) ->
     data4a = _.filter(dataForGraph, (d) ->
       return !d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
     )
     data4b = _.filter(dataForGraph, (d) ->
       return d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
     )
     total_cases1 = data4a.length
     total_cases2 = data4b.length

     ndx4a = crossfilter(data4a)
     ndx4b = crossfilter(data4b)
  
     dim4a = ndx4a.dimension((d) ->
       return d.dateICD
     )
     dim4b = ndx4b.dimension((d) ->
       return d.dateICD
     )
    
     grpGTE5_3 = dim4a.group().reduce(
       (p,v) ->
         ++p.count
         p.pct = (p.count / total_cases1).toFixed(2)
         return p
       , (p,v) ->
         --p.count
         p.pct = (p.count / total_cases1).toFixed(2)
         return p
       , () ->
         return {count:0, pct: 0}
     )
  
     grpLT5_3 = dim4b.group().reduce(
       (p,v) ->
         ++p.count
         p.pct = (p.count / total_cases2).toFixed(2)
         return p
       , (p,v) ->
         --p.count
         p.pct = (p.count / total_cases2).toFixed(2)
         return p
       , () ->
         return {count:0, pct: 0}
     )

     composite
       .width($('.chart_container').width() - options.adjustX)
       .height($('.chart_container').height() - options.adjustY)
       .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
       .y(d3.scale.linear())
       .xUnits(d3.time.days)
       .yAxisLabel("Proportion of OPD Cases Tested Positive [%]")
       .elasticY(true)
       .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
       .renderHorizontalGridLines(true)
       .shareTitle(false)
       .compose([
           dc.lineChart(composite)
             .dimension(dim4a)
             .colors(colorScale(0))
             .group(grpGTE5_3, "Test rate [5+]")
             .valueAccessor((p) ->
               return p.value.pct
               )
             .xyTipsOn(true)
             .renderDataPoints(false)
             .title((d) ->
               return 'Week: '+ moment(d.key).isoWeek() + ": " + Math.round(d.value.pct*100) + '%'
              ),
           dc.lineChart(composite)
             .dimension(dim4b)
             .colors(colorScale(1))
             .group(grpLT5_3, "Test rate [< 5]")
             .valueAccessor((p) ->
               return p.value.pct
               )
             .xyTipsOn(true)
             .renderDataPoints(false)
             .title((d) ->
               return 'Week: '+ moment(d.key).isoWeek() + ": " + Math.round(d.value.pct*100) + '%'
             )
       ])
       .brushOn(false)
       .render()

 Graphs.timeToNotify = (dataForGraph, composite, options) ->
     data1 = _.filter(dataForGraph, (d) ->
       return !d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
     )
     data2 = _.filter(dataForGraph, (d) ->
       return d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
     )

     ndx1 = crossfilter(data1)
     ndx2 = crossfilter(data2)

     dim1 = ndx1.dimension((d) ->
       return d.dateICD
     )
     dim2 = ndx2.dimension((d) ->
       return d.dateICD
     )
     grpGTE5 = dim1.group()
     grpLT5 = dim2.group()
       
     composite
       .width($('.chart_container').width() - options.adjustX)
       .height($('.chart_container').height() - options.adjustY)
       .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
       .y(d3.scale.linear())
       .yAxisLabel("Number of Cases")
       .elasticY(true)
       .xUnits(d3.time.days)
       .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
       .renderHorizontalGridLines(true)
       .shareTitle(false)
       .compose([
         dc.barChart(composite)
           .dimension(dim2)
           .group(grpLT5, "25 to 72 hrs")
           .colors(colorScale(2))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return d.key.toDateString() + ": " + d.value
           ),
         dc.barChart(composite)
           .dimension(dim1)
           .group(grpGTE5, "Within 24 hrs")
           .colors(colorScale(3))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return d.key.toDateString() + ": " + d.value
           )
       ])
       .brushOn(false)
       .render()

 Graphs.timeToComplete = (dataForGraph, composite, options) ->

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
   
    ndx1 = crossfilter(data1)
    ndx2 = crossfilter(data2)
    ndx3 = crossfilter(data3)
    ndx4 = crossfilter(data4)
    
    dim1 = ndx1.dimension((d) ->
      return  d.dateICD
    )

    dim2 = ndx2.dimension((d) ->
      return  d.dateICD
    )

    dim3 = ndx3.dimension((d) ->
      return  d.dateICD
    )
    dim4 = ndx4.dimension((d) ->
      return  d.dateICD
    )
    grp1 = dim1.group()
    grp2 = dim2.group()
    grp3 = dim3.group()
    grp4 = dim4.group()

    composite
       .width($('.chart_container').width() - options.adjustX)
       .height($('.chart_container').height() - options.adjustY)
       .x(d3.time.scale().domain([new Date(options.startDate), new Date(options.endDate)]))
       .y(d3.scale.linear())
       .yAxisLabel("Number of Cases")
       .elasticY(true)
       .elasticX(true)
       .xUnits(d3.time.days)
       .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
       .renderHorizontalGridLines(true)
       .shareTitle(false)
       .compose([
         dc.barChart(composite)
           .dimension(dim4)
           .group(grp4, "More than 72 hrs")
           .colors(colorScale(0))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ moment(d.key).isoWeek() + ": " + d.value
            ),
         dc.barChart(composite)
           .dimension(dim3)
           .group(grp3, "48 to 72 hrs")
           .colors(colorScale(1))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ moment(d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim2)
           .group(grp2, "24 to 48 hrs")
           .colors(colorScale(2))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ moment(d.key).isoWeek() + ": " + d.value
             ),
         dc.barChart(composite)
           .dimension(dim1)
           .group(grp1, "Within 24 hrs")
           .colors(colorScale(3))
           .centerBar(true)
           .gap(1)
           .title((d) ->
             return 'Week: '+ moment(d.key).isoWeek() + ": " + d.value
             )
       ])
       .brushOn(false)
       .render()

 Graphs.positivityCases = (dataForGraph, composite, options) ->
  
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
     return d.dateICD
   )
   dim2 = ndx2.dimension((d) ->
     return d.dateICD
   )
   dim3 = ndx3.dimension((d) ->
     return d.dateICD
   )
   grp1 = dim1.group()

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
     .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
     .renderHorizontalGridLines(true)
     .shareTitle(false)
     .compose([
       dc.lineChart(composite)
         .dimension(dim1)
         .colors(colorScale(0))
         .group(grp1, "Cases Has Notifcation")
         .xyTipsOn(true)
         .renderDataPoints(false)
         .title((d) ->
           return d.key.toDateString() + ": " + d.value
         )
       dc.lineChart(composite)
         .dimension(dim2)
         .colors(colorScale(1))
         .group(grp2, "Positive Hse Member")
         .xyTipsOn(true)
         .renderDataPoints(false)
         .title((d) ->
           return d.key.toDateString() + ": " + d.value
         )
       dc.lineChart(composite)
         .dimension(dim3)
         .colors(colorScale(2))
         .group(grp3, "Tested Hse Member")
         .xyTipsOn(true)
         .renderDataPoints(false)
         .title((d) ->
           return d.key.toDateString() + ": " + d.value
         )
     ])
     .brushOn(false)
     .render()
    
module.exports = Graphs