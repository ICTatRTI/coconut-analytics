_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class TestRateGraphView extends Backbone.View
  el: "#content"

  render: =>
    options = $.extend({},Coconut.router.reportViewOptions)
    @$el.html "
       <div id='dateSelector'></div>
       <div class='chart-title'>T e s t &nbsp; R a t e</div>
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
          d['Age In Years'] = +d['Age In Years']
        )
        data1 = _.filter(dataForGraph, (d) ->
          return !d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
        )
        data2 = _.filter(dataForGraph, (d) ->
          return d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
        )
        total_cases1 = data1.length
        total_cases2 = data2.length

        composite = dc.compositeChart("#chart")
        ndx1 = crossfilter(data1)
        ndx2 = crossfilter(data2)
        
        dim1 = ndx1.dimension((d) ->
          return d.dateICD
        )
        dim2 = ndx2.dimension((d) ->
          return d.dateICD
        )
        
        grpGTE5 = dim1.group().reduce(
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
        
        grpLT5 = dim2.group().reduce(
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
          .width($('.chart_container').width()-adjustX)
          .height($('.chart_container').height()-adjustY)
          .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
          .y(d3.scale.linear())
          .yAxisLabel("Proportion of OPD Cases Tested Positive [%]")
          .elasticY(true)
          .legend(dc.legend().x($('.chart_container').width()-200).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
          .renderHorizontalGridLines(true)
          .shareTitle(false)
          .compose([
              dc.lineChart(composite)
                .dimension(dim1)
                .colors('red')
                .group(grpGTE5, "Test rate [5+]")
                .valueAccessor((p) ->
                  return p.value.pct
                  )
                .dashStyle([2,2])
                .xyTipsOn(true)
                .renderDataPoints(false)
                .title((d) ->
                  return d.key.toDateString() + ": " + d.value.pct*100 +"%"
                ),
              dc.lineChart(composite)
                .dimension(dim2)
                .colors('blue')
                .group(grpLT5, "Test rate [< 5]")
                .valueAccessor((p) ->
                  return p.value.pct
                  )
                .dashStyle([5,5])
                .xyTipsOn(true)
                .renderDataPoints(false)
                .title((d) ->
                  return d.key.toDateString() + ": " + d.value.pct*100 +"%"
                )
          ])
          .brushOn(false)
          .render()

        window.onresize = () ->
          HTMLHelpers.resizeChartContainer()
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
  
module.exports = TestRateGraphView
