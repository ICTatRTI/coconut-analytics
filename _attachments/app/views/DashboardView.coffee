_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'
moment = require 'moment'
Dialog = require './Dialog'
dc = require 'dc'
d3 = require 'd3'
crossfilter = require 'crossfilter'

class DashboardView extends Backbone.View
  el: "#content"

  events:
    "click div.chart_container": "zoomGraph"
  
  zoomGraph: (e) ->
    graphName = $(e.currentTarget).attr "data-graph-id"
    if graphName != undefined
      Coconut.router.navigate("#graphs/type/#{graphName}", {trigger: true})
        
  render: =>
    Coconut.statistics = Coconut.statistics || {}
    # $('#analysis-spinner').show()
    @$el.html "
        <style>
          .page-content {margin: 0}
          .chart {left: 0; padding: 0}
          .chart_container {width: 100%}
          
        </style>
        <div id='dateSelector'></div>
        <dialog id='dialog'>
          <div id='dialogContent'> </div>
        </dialog>
        <div id='dashboard-summary'>
          <div class='sub-header-color relative clear'>
            <div class='mdl-grid'>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary1'> 
                  <div class='stats' id='alertStat'><div style='font-size:12px'>Loading...</div></div>
                  <div class='stats-title'>ALERTS</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary2'> 
                  <div class='stats' id='caseStat'><div style='font-size:12px'>Loading...</div></div>
                  <div class='stats-title'>CASES</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary3'> 
                  <div class='stats' id='issueStat'><div style='font-size:12px'>Loading...</div></div>
                  <div class='stats-title'>ISSUES</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary4'>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary1'> </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary1'> </div>
              </div>
            </div>
          </div>
        </div>
        <div class='page-content'>
          <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--3-col-tablet mdl-cell--4-col-phone'>
                <div id='container_1' class='chart_container f-left' data-graph-id = 'IncidentsGraph'>
                   <div class='chart-title'>Number of Cases</div>
                   <div id='chart_1' class='chart'></div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                </div>
                
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--3-col-tablet mdl-cell--4-col-phone'> 
                <div id='container_2' class='chart_container f-left' data-graph-id = 'PositiveCasesGraph'>
                   <div class='chart-title'>Number of Positive Cases by Age Group</div>
                   <div id='chart_2' class='chart'></div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                </div>
            </div>
          </div>
          <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--3-col-tablet mdl-cell--4-col-phone'>
                <div id='container_3' class='chart_container f-left' data-graph-id = 'AttendanceGraph'>
                   <div class='chart-title'>Attendance Graph</div>                
                   <div id='chart_3' class='chart'></div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                </div>
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--3-col-tablet mdl-cell--4-col-phone'>
                <div id='container_4' class='chart_container f-left' data-graph-id = 'TestRateGraph'>
                  <div class='chart-title'>Test Rate Graph</div>              
                  <div id='chart_4' class='chart'></div>
                  <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                </div>
            </div>
          </div>
        </div>
    "
    $('.graph-spinner').show()
    
    displayStatistics()
    
    startDate = Coconut.router.reportViewOptions.startDate
    endDate = Coconut.router.reportViewOptions.endDate

    Coconut.database.query "caseCountIncludingSecondary",
      startkey: [startDate]
      endkey: [endDate]
      reduce: false
      include_docs: true
    .then (result) =>
        if (result.rows.length < 2 or _.isEmpty(result.rows[0]))
          Coconut.router.reportViewOptions.endDate = endDate = moment().format('YYYY-MM-DD')
          Coconut.router.reportViewOptions.startDate = startDate = moment().dayOfYear(1).format('YYYY-MM-DD')
          Coconut.dateSelectorView.startDate = startDate
          Coconut.dateSelectorView.endDate = endDate
          Coconut.dateSelectorView.render()
          displayError()
          Coconut.database.query "caseCountIncludingSecondary",
            startkey: [startDate]
            endkey: [endDate]
            reduce: false
            include_docs: true
          .then (result) =>
            dataForGraph = _.pluck(result.rows, 'doc')
            @showStats(dataForGraph)
            @showGraphs(dataForGraph,startDate,endDate)
        else
          dataForGraph = _.pluck(result.rows, 'doc')
          @showStats(dataForGraph)
          @showGraphs(dataForGraph,startDate,endDate)
    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

  showGraphs: (dataForGraph,startDate,endDate) ->
    chart1 = dc.lineChart("#chart_1")
    composite1 = dc.compositeChart("#chart_2")
    composite2 = dc.compositeChart("#chart_3")
    composite3 = dc.compositeChart("#chart_4")
    
    adjustX = 15
    adjustY = 40
    
    dataForGraph.forEach((d) ->
      d.dateICD = new Date(d['Index Case Diagnosis Date']+' ') # extra space at end cause it to use UTC format.
    )
    
    # Incident Graph - Number of Cases
    ndx = crossfilter(dataForGraph)
    dim = ndx.dimension((d) ->
      return d['Index Case Diagnosis Date Iso Week']
    )
    grp = dim.group()
    chart1
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

    chart1.render()

    $('div#container_1 div.mdl-spinner').hide()

    # PositiveCases Graph
    data2a = _.filter(dataForGraph, (d) ->
      return !d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
    )
    data2b = _.filter(dataForGraph, (d) ->
      return d['Is Index Case Under 5'] && d['Number Positive Cases Including Index'] >= 1
    )
    
    ndx2a = crossfilter(data2a)
    ndx2b= crossfilter(data2b)

    dim2a = ndx2a.dimension((d) ->
      return d.dateICD
    )
    dim2b = ndx2b.dimension((d) ->
      return d.dateICD
    )
    grpGTE5 = dim2a.group()
    grpLT5 = dim2b.group()
    
    composite1
      .width($('.chart_container').width()-adjustX)
      .height($('.chart_container').height()-adjustY)
      .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
      .y(d3.scale.linear().domain([0,120]))
      .yAxisLabel("Number of Positive Cases")
      .elasticY(true)
      .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
      .renderHorizontalGridLines(true)
      .shareTitle(false)
      .compose([
        dc.lineChart(composite1)
          .dimension(dim2a)
          .colors('red')
          .group(grpGTE5, "Age 5+")
          .dashStyle([2,2])
          .xyTipsOn(true)
          .renderDataPoints(true)
          .title((d) ->
            return d.key.toDateString() + ": " + d.value
          ),
        dc.lineChart(composite1)
          .dimension(dim2b)
          .colors('blue')
          .group(grpLT5, "Age < 5")
          .dashStyle([5,5])
          .xyTipsOn(true)
          .renderDataPoints(true)
          .title((d) ->
            return d.key.toDateString() + ": " + d.value
          )
      ])
      .brushOn(false)
      .render()
    
    $('div#container_2 div.mdl-spinner').hide()
    
    # Attendance Graph
    data3a = _.filter(dataForGraph, (d) ->
      return !d['Is Index Case Under 5']
    )
    data3b = _.filter(dataForGraph, (d) ->
      return d['Is Index Case Under 5']
    )

    ndx3a = crossfilter(data3a)
    ndx3b = crossfilter(data3b)
    
    dim3a = ndx3a.dimension((d) ->
      return d.dateICD 
    )
    dim3b = ndx3b.dimension((d) ->
      return d.dateICD
    )
    grpGTE5_2 = dim3a.group()
    grpLT5_2 = dim3b.group()
  
    composite2
      .width($('.chart_container').width()-adjustX)
      .height($('.chart_container').height()-adjustY)
      .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
      .y(d3.scale.linear().domain([0,120]))
      .yAxisLabel("Number of Cases")
      .elasticY(true)
      .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
      .renderHorizontalGridLines(true)
      .shareTitle(false)
      .compose([
        dc.lineChart(composite2)
          .dimension(dim3a)
          .colors('red')
          .group(grpGTE5_2, "Age >= 5")
          .dashStyle([2,2])
          .xyTipsOn(true)
          .renderDataPoints(false)
          .title((d) ->
            return d.key.toDateString() + ": " + d.value
          ),
        dc.lineChart(composite2)
          .dimension(dim3b)
          .colors('blue')
          .group(grpLT5_2, "Age < 5")
          .dashStyle([5,5])
          .xyTipsOn(true)
          .renderDataPoints(false)
          .title((d) ->
            return d.key.toDateString() + ": " + d.value
          )
        ])
      .brushOn(false)
      .render()
    
    $('div#container_3 div.mdl-spinner').hide()
      
    # TestRate Graph 
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

    composite3
      .width($('.chart_container').width()-adjustX)
      .height($('.chart_container').height()-adjustY)
      .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
      .y(d3.scale.linear().domain([0,120]))
      .yAxisLabel("Proportion of OPD Cases Tested Positive [%]")
      .elasticY(true)
      .legend(dc.legend().x($('.chart_container').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
      .renderHorizontalGridLines(true)
      .shareTitle(false)
      .compose([
          dc.lineChart(composite3)
            .dimension(dim4a)
            .colors('red')
            .group(grpGTE5_3, "Test rate [5+]")
            .valueAccessor((p) ->
              return p.value.pct
              )
            .dashStyle([2,2])
            .xyTipsOn(true)
            .renderDataPoints(false)
            .title((d) ->
              return d.key.toDateString() + ": " + d.value.pct*100 +"%"
            ),
          dc.lineChart(composite3)
            .dimension(dim4b)
            .colors('blue')
            .group(grpLT5_3, "Test rate [< 5]")
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

    $('div#container_4 div.mdl-spinner').hide()
          

    window.onresize = () ->
      chart_width = $('.chart_container').width()-adjustX
      chart_height = $('.chart_container').height()-adjustY
      
      chart1
        .width(chart_width)
        .height(chart_height)
        .rescale()
        .redraw()
        
      composite1
        .width(chart_width)
        .height(chart_height)
        .legend(dc.legend().x($('#container_2').width()-120))
        .rescale()
        .redraw()
        
      composite2
        .width(chart_width)
        .height(chart_height)
        .legend(dc.legend().x($('#container_3').width()-120))
        .rescale()
        .redraw()
        
      composite3
        .width(chart_width)
        .height(chart_height)
        .legend(dc.legend().x($('#container_4').width()-120))
        .rescale()
        .redraw()
  
  showStats: (data) ->
    data = _.filter(data, (d) ->
      return moment(d['Index Case Diagnosis Date']).isBefore(moment().subtract(2,'days'))
    )
    alertsCount = _.filter(data, (d) ->
      return d['Ussd Notification: Date']
    ).length
    casesCount = _.filter(data, (d) ->
      return d['Has Case Notification'] 
    ).length
    issuesCount = _.filter(data, (d) ->
      return d['Has Complete Facility']
    ).length
    
    Coconut.statistics.alerts = alertsCount
    Coconut.statistics.cases = casesCount
    Coconut.statistics.issues = issuesCount
    displayStatistics()
  
  
  displayStatistics = () ->
    $('#alertStat').html(Coconut.statistics.alerts) if Coconut.statistics.alerts?
    $('#caseStat').html(Coconut.statistics.cases) if Coconut.statistics.cases?
    $('#issueStat').html(Coconut.statistics.issues) if Coconut.statistics.issues?
    
  displayError = () ->
    $('div#noDataFound').show().delay(7000).fadeOut()  
    
module.exports = DashboardView
