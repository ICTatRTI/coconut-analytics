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
    view = @
    Coconut.database.query "#{Coconut.config.design_doc_name}/positiveCases",
      startkey: startDate
      endkey: endDate
      include_docs: false
    .catch (error) ->
      console.error error
    .then (result) =>
      if result.rows.length == 0
        Coconut.router.reportViewOptions.endDate = endDate = moment().format('YYYY-MM-DD')
        Coconut.router.reportViewOptions.startDate = startDate = moment().dayOfYear(1).format('YYYY-MM-DD')
        Coconut.dateSelectorView.startDate = startDate
        Coconut.dateSelectorView.endDate = endDate
        Coconut.dateSelectorView.render()
        displayError()
        view.showStats(startDate, endDate)
        view.showGraphs(startDate, endDate)
      else
        @showStats(startDate, endDate)
        @showGraphs(startDate, endDate)

  showGraphs: (startDate, endDate) ->
    chart1 = dc.lineChart("#chart_1")
    composite1 = dc.compositeChart("#chart_2")
    composite2 = dc.compositeChart("#chart_3")
    composite3 = dc.compositeChart("#chart_4")
    
    adjustX = 15
    adjustY = 40
    startDate = moment(startDate).format('YYYY-MM-DD')
    endDate = moment(endDate).format('YYYY-MM-DD')
    
    # Incident Graph - Number of Cases
    Coconut.database.query "positiveCases/positiveCases",
      startkey: startDate
      endkey: endDate
      include_docs: true
    .then (result) =>
        data1ForGraph = _.pluck(result.rows, 'doc')
        if (data1ForGraph.length == 0 or _.isEmpty(data1ForGraph[0]))
           $(".chart_container").html HTMLHelpers.noRecordFound()
           $('#analysis-spinner').hide()
        else
          data1ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults)
          )
          
          ndx = crossfilter(data1ForGraph)
          dim = ndx.dimension((d) ->
            return d.datePR
          )
          grp = dim.group()

          chart1
            .width($('.chart_container').width()-adjustX)
            .height($('.chart_container').height()-adjustY)
            .margins({top: 20, right: 20, bottom: 30, left: 50})
            .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
            .y(d3.scale.linear().domain([0,120]))
            .yAxisLabel("Number of Incidents")
            .elasticY(true)
            .renderHorizontalGridLines(true)
            .dimension(dim)
            .colors('red')
            .group(grp)
            .xyTipsOn(true)
            .renderDataPoints(false)
            .title((d) ->
              return d.key.toDateString() + ": " + d.value
            )
            .brushOn(false)
              
          chart1.render()
          $('div#container_1 div.mdl-spinner').hide()
      .catch (error) ->
        console.error error
        $('div#container_1 div.mdl-spinner').hide()

    # PositiveCases
    Coconut.database.query "positiveCasesGT5/positiveCasesGT5",
      startkey: startDate
      endkey: endDate
      include_docs: true
    .then (result) =>
      data1ForGraph = _.pluck(result.rows, 'doc')
      Coconut.database.query "positiveCasesLT5/positiveCasesLT5",
        startkey: startDate
        endkey: endDate
        include_docs: true
      .then (result) =>
        data2ForGraph = _.pluck(result.rows, 'doc')
        if (data1ForGraph.length == 0 and data2ForGraph.length == 0) or (_.isEmpty(data1ForGraph[0]) and _.isEmpty(data2ForGraph[0]))
           $(".chart_container").html HTMLHelpers.noRecordFound()
           $('#analysis-spinner').hide()
        else
          data1ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults)
          )
          data2ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults) 
          )

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
          
          composite1
            .width($('.chart_container').width()-adjustX)
            .height($('.chart_container').height()-adjustY)
            .margins({top: 20, right: 20, bottom: 30, left: 50})
            .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
            .y(d3.scale.linear().domain([0,120]))
            .yAxisLabel("Number of Positive Cases")
            .elasticY(true)
            .legend(dc.legend().x($('#container_2').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
            .renderHorizontalGridLines(true)
            .shareTitle(false)
            .compose([
                dc.lineChart(composite1)
                  .dimension(dim1)
                  .colors('red')
                  .group(grp1, "Age >= 5")
                  .dashStyle([2,2])
                  .xyTipsOn(true)
                  .renderDataPoints(true)
                  .title((d) ->
                    return d.key.toDateString() + ": " + d.value
                  ),
                dc.lineChart(composite1)
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
                    
          $('div#container_2 div.mdl-spinner').hide()
      .catch (error) ->
        console.error error
        $('div#container_2 div.mdl-spinner').hide()
    .catch (error) ->
      console.error error
      $('div#container_2 div.mdl-spinner').hide()
      
    # Attendance Graph
    Coconut.database.query "positiveCasesByFacilityGTE5/positiveCasesByFacilityGTE5",
      startkey: startDate
      endkey: endDate
      include_docs: true
    .then (result) =>
      data1ForGraph = _.pluck(result.rows, 'doc')
      Coconut.database.query "positiveCasesByFacilityLT5/positiveCasesByFacilityLT5",
        startkey: startDate
        endkey: endDate
        include_docs: true
      .then (result) =>
        data2ForGraph = _.pluck(result.rows, 'doc')
        if (data1ForGraph.length == 0 and data2ForGraph.length == 0) or (_.isEmpty(data1ForGraph[0]) and _.isEmpty(data2ForGraph[0]))
           $(".chart_container}").html HTMLHelpers.noRecordFound()
           $('#analysis-spinner').hide()
        else
          data1ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults)
          )
          data2ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults) 
          )

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
          
          composite2
            .width($('.chart_container').width()-adjustX)
            .height($('.chart_container').height()-adjustY)
            .margins({top: 20, right: 20, bottom: 30, left: 50})
            .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
            .y(d3.scale.linear().domain([0,120]))
            .yAxisLabel("Number of Cases")
            .elasticY(true)
            .legend(dc.legend().x($('#container_3').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
            .renderHorizontalGridLines(true)
            .shareTitle(false)
            .compose([
                dc.lineChart(composite2)
                  .dimension(dim1)
                  .colors('red')
                  .group(grp1, "Age >= 5")
                  .dashStyle([2,2])
                  .xyTipsOn(true)
                  .renderDataPoints(false)
                  .title((d) ->
                    return d.key.toDateString() + ": " + d.value
                  ),
                dc.lineChart(composite2)
                  .dimension(dim2)
                  .colors('blue')
                  .group(grp2, "Age < 5")
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
      .catch (error) ->
        console.error error
        $('div#container_3 div.mdl-spinner').hide()
    .catch (error) ->
      console.error error

    # Example TestRate Graph
    Coconut.database.query "positiveCasesByFacilityGTE5/positiveCasesByFacilityGTE5",
      startkey: startDate
      endkey: endDate
      include_docs: true
    .then (result) =>
      data1ForGraph = _.pluck(result.rows, 'doc')
      Coconut.database.query "positiveCasesByFacilityLT5/positiveCasesByFacilityLT5",
        startkey: startDate
        endkey: endDate
        include_docs: true
      .then (result) =>
        data2ForGraph = _.pluck(result.rows, 'doc')
        if (data1ForGraph.length == 0 and data2ForGraph.length == 0) or (_.isEmpty(data1ForGraph[0]) and _.isEmpty(data2ForGraph[0]))
           $(".chart_container").html HTMLHelpers.noRecordFound()
           $('#analysis-spinner').hide()
        else
          data1ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults)
          )
          data2ForGraph.forEach((d) ->
            d.datePR = new Date(d.DateofPositiveResults) 
          )

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
          
          composite3
            .width($('.chart_container').width()-adjustX)
            .height($('.chart_container').height()-adjustY)
            .margins({top: 20, right: 20, bottom: 30, left: 50})
            .x(d3.time.scale().domain([new Date(startDate), new Date(endDate)]))
            .y(d3.scale.linear().domain([0,120]))
            .yAxisLabel("Proportion of OPD Cases Tested Positive")
            .elasticY(true)
            .legend(dc.legend().x($('#container_4').width()-120).y(20).itemHeight(20).gap(5).legendWidth(140).itemWidth(70))
            .renderHorizontalGridLines(true)
            .shareTitle(false)
            .compose([
                dc.lineChart(composite3)
                  .dimension(dim1)
                  .colors('red')
                  .group(grp1, "Test rate [5+]")
                  .dashStyle([2,2])
                  .xyTipsOn(true)
                  .renderDataPoints(false)
                  .title((d) ->
                    return d.key.toDateString() + ": " + d.value
                  ),
                dc.lineChart(composite3)
                  .dimension(dim2)
                  .colors('blue')
                  .group(grp2, "Test rate [< 5]")
                  .dashStyle([5,5])
                  .xyTipsOn(true)
                  .renderDataPoints(false)
                  .title((d) ->
                    return d.key.toDateString() + ": " + d.value
                  )
            ])
            .brushOn(false)
            .render()
                        
          $('div#container_4 div.mdl-spinner').hide()
      .catch (error) ->
        console.error error
        $('div#container_4 div.mdl-spinner').hide()
    .catch (error) ->
      console.error error

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
        
  showStats: (startDate, endDate) ->
    reports = new Reports()
    reports.getCases
      startDate: startDate
      endDate: endDate
      
      
      success: (cases) =>
        alertsCount = 0
        casesCount = 0
        issuesCount = 0
        _.each cases, (malariaCase) =>
          if moment(malariaCase.Facility?.DateofPositiveResults).isBefore(moment().subtract(2,'days'))
            if malariaCase["USSD Notification"]? &&  !malariaCase["USSD Notification"].complete?
              ++alertsCount
            if malariaCase["Case Notification"]? &&  !malariaCase["Case Notification"].complete?
              ++casesCount
            if malariaCase.Facility? &&  !malariaCase.Facility.complete?
              ++issuesCount

        Coconut.statistics.alerts = alertsCount
        Coconut.statistics.cases = casesCount
        Coconut.statistics.issues = issuesCount
        displayStatistics()
  
  displayStatistics = () ->
    $('#alertStat').html(Coconut.statistics.alerts) if Coconut.statistics.alerts?
    $('#caseStat').html(Coconut.statistics.cases) if Coconut.statistics.cases?
    $('#issueStat').html(Coconut.statistics.issues) if Coconut.statistics.issues?
    
  displayError = () ->
    $('div#noDataFound').show().delay(4000).fadeOut()  
    
module.exports = DashboardView
