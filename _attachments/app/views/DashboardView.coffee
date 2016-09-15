_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'
moment = require 'moment'
Dialog = require './Dialog'
Graphs = require '../models/Graphs'
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
            <div class='stat_summary'> 
              <a class='chip summary1'>
                <div class='summary_icon'><i class='material-icons white'>notifications_none</i></div>
                <div class='stats' id='alertStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Alerts</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary2'>
                <div class='summary_icon'><i class='material-icons white'>notifications_active</i></div>
                <div class='stats' id='alarmStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Alarms</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary3'>
                <div class='summary_icon'><i class='material-icons white'>person_pin</i></div>
                <div class='stats' id='notifiedStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Notified Cases</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary4'>
                <div class='summary_icon'><i class='material-icons white'>person_pin</i></div>
                <div class='stats' id='notfollowStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Not Followed Up</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary5'>
                <div class='summary_icon'><i class='material-icons white'>person_pin</i></div>
                <div class='stats' id='hsatStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>HSAT</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary6'>
                <div class='summary_icon'><i class='material-icons white'>person_pin</i></div>
                <div class='stats' id='hsattestStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>HSAT Tested</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary7'>
                <div class='summary_icon'><i class='material-icons white'>person_pin</i></div>
                <div class='stats' id='fsatStat'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>FSAT</div>
              </a>
            </div>
            <div class='stat_summary'> 
              <a class='chip summary8'>
                <div class='summary_icon'><i class='material-icons white'>person_pin</i></div>
                <div class='stats' id='importedStat'>0</div>
                <div class='stats-title'>Imported</div>
              </a>
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
    adjustButtonSize()
    
    $('.graph-spinner').show()
    displayStatistics()
        
    options = $.extend({},Coconut.router.reportViewOptions)
    startDate = options.startDate
    endDate = options.endDate


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
          options = $.extend({},Coconut.router.reportViewOptions)
          Coconut.database.query "caseCountIncludingSecondary",
            startkey: [startDate]
            endkey: [endDate]
            reduce: false
            include_docs: true
          .then (result) =>
            dataForGraph = _.pluck(result.rows, 'doc')
            console.log(dataForGraph)
            showStats()    
            @showGraphs(dataForGraph,options)
        else
          dataForGraph = _.pluck(result.rows, 'doc')
          console.log(dataForGraph)
          showStats()    
          @showGraphs(dataForGraph,options)
    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

  showGraphs: (dataForGraph,options) ->
    startDate = options.startDate
    endDate = options.endDate
    
    options.adjustX = 15
    options.adjustY = 40
    
    dataForGraph.forEach((d) ->
      d.dateICD = new Date(d['Index Case Diagnosis Date']+' ') # extra space at end cause it to use UTC format.
    )
    chart1 = dc.lineChart("#chart_1")
    composite1 = dc.compositeChart("#chart_2")
    composite2 = dc.compositeChart("#chart_3")
    composite3 = dc.compositeChart("#chart_4")
    
    # Incident Graph - Number of Cases
    Graphs.incidents(dataForGraph, chart1, options)
    $('div#container_1 div.mdl-spinner').hide()
    
    # PositiveCases Graph
    Graphs.positiveCases(dataForGraph, composite1, options)
    $('div#container_2 div.mdl-spinner').hide()

    # Attendance Graph
    Graphs.attendance(dataForGraph, composite2, options)
    $('div#container_3 div.mdl-spinner').hide()

    # TestRate Graph 
    Graphs.testRate(dataForGraph, composite3, options)
    $('div#container_4 div.mdl-spinner').hide()
          

    window.onresize = () ->
      adjustButtonSize()
      new_height = 0.45 *  $(".chart_container").width()
#      $(".chart_container").css('height',new_height)
      #$(".chart_container").height(0.44 * $(".chart_container").width())
      Graphs.chartResize(chart1, 'chart_container', options)
      Graphs.compositeResize(composite1, 'chart_container', options)
      Graphs.compositeResize(composite2, 'chart_container', options)
      Graphs.compositeResize(composite3, 'chart_container', options)

    
  showStats = () ->
    Coconut.statistics.alerts = 0
    Coconut.statistics.cases = 0
    Coconut.statistics.notified = 0
    Coconut.statistics.notfollowed = 0
    Coconut.statistics.hsat = 0
    Coconut.statistics.hsattested = 0
    Coconut.statistics.fsat = 0
    Coconut.statistics.imported = 0

    #Grouped by ISO Year Week
    groupCaseCounterResult "GGGG-WW",
      success: (result) ->
        console.log("Grouped by ISO Year Week")
        console.log(result)

    #Grouped by Year
    groupCaseCounterResult "YYYY",
      success: (result) ->
        _.each(result, (d) ->
          Coconut.statistics.notified += d["Has Notification"]
          Coconut.statistics.notfollowed += (d["Has Notification"] - d["Followed Up"])
          Coconut.statistics.imported += d["Number Index Cases Suspected To Be Imported"]
          Coconut.statistics.hsat += d["Number Of Positive Cases At Index Household"]
          Coconut.statistics.fsat += d["Number Positive Cases From Mass Screen"] if d["Number Positive Cases From Mass Screen"]?
          Coconut.statistics.hsattested += d["Number Household Members Tested"]
        )
        displayStatistics()
  
  
  adjustButtonSize = () ->
    noButtons = 8
    summaryWidth = $('#dashboard-summary').width()
    buttonWidth = (summaryWidth - 14)/noButtons
    $('.chip').width(buttonWidth-2)
  
  displayStatistics = () ->
    $('#alertStat').html(Coconut.statistics.alerts) if Coconut.statistics.alerts?
    $('#alarmStat').html(Coconut.statistics.cases) if Coconut.statistics.cases?
    $('#notifiedStat').html(Coconut.statistics.notified) if Coconut.statistics.notified?
    $('#notfollowStat').html(Coconut.statistics.notfollowed) if Coconut.statistics.notfollowed?
    $('#hsatStat').html(Coconut.statistics.hsat) if Coconut.statistics.hsat?
    $('#hsattestStat').html(Coconut.statistics.hsattested) if Coconut.statistics.hsattested?
    $('#fsatStat').html(Coconut.statistics.fsat) if Coconut.statistics.fsat?
    $('#importedStat').html(Coconut.statistics.imported) if Coconut.statistics.imported?
    
  displayError = () ->
    $('div#noDataFound').show().delay(5000).fadeOut()  
  
  
  # This function takes a date format to group with
  # So if you want to aggregate based on week, year, month
  # Pass in the format using the moment.js format http://momentjs.com/docs/#/displaying/format/
  groupCaseCounterResult = (dateFormatForGrouping, options) ->
    startDate = Coconut.router.reportViewOptions.startDate
    endDate = Coconut.router.reportViewOptions.endDate
    Coconut.database.query "caseCounter",
      group: true
      startkey: [startDate]
      endkey: [endDate,{}]
    .then (result) ->
      groupedResult = {}
      _(result.rows).each (result) ->
        dateForGrouping = moment(result.key[0]).format(dateFormatForGrouping)
        indicatorName = result.key[1]
        groupedResult[dateForGrouping] = {} unless groupedResult[dateForGrouping]
        groupedResult[dateForGrouping][indicatorName] = 0 unless groupedResult[dateForGrouping][indicatorName]
        groupedResult[dateForGrouping][indicatorName] += result.value
      options.success(groupedResult)
      
    .catch (error) ->
      console.error error
      
module.exports = DashboardView
