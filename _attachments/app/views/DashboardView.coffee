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
    HTMLHelpers.ChangeTitle("Dashboard")
    @$el.html "
        <style>
          .page-content {margin: 0}
          .chart {left: 0; padding: 5px}
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
                <div class='summary_icon'>
                  <div><i class='material-icons white'>notifications_active</i></div>
                  <div class='stats' id='alarmStat'></div>
                </div>
                <div class='stats_pct' id='alarmStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Alarms</div>
              </a>
            </div>
            <div class='stat_summary'>
              <a class='chip summary2'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>notifications_none</i></div>
                  <div class='stats' id='alertStat'></div>
                </div>
                <div class='stats_pct' id='alertStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Alerts</div>
              </a>
            </div>
            <div class='stat_summary'>
              <a class='chip summary3'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>person_pin</i></div>
                  <div class='stats' id='notifiedStat'></div>
                </div>
                <div class='stats_pct' id='notifiedStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Notified Cases</div>
              </a>
            </div>
            <div class='stat_summary'>
              <a class='chip summary4'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>person_pin</i></div>
                  <div class='stats' id='notfollowStat'></div>
                </div>
                <div class='stats_pct' id='notfollowStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Not Followed Up</div>
              </a>
            </div>
            <div class='stat_summary'>
              <a class='chip summary5'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>person_pin</i></div>
                  <div class='stats' id='hsattestStat'></div>
                </div>
                <div class='stats_pct' id='hsattestStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>HSAT Tested</div>
              </a>
            </div>
            <div class='stat_summary'>
              <a class='chip summary6'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>person_pin</i></div>
                  <div class='stats' id='hsatStat'></div>
                </div>
                <div class='stats_pct' id='hsatStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>HSAT Positive</div>
              </a>
            </div>
<!--            <div class='stat_summary'>
              <a class='chip summary7'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>person_pin</i></div>
                  <div class='stats' id='fsatStat'></div>
                </div>
                <div class='stats_pct' id='fsatStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>FSAT</div>
              </a>
            </div>
-->
            <div class='stat_summary'>
              <a class='chip summary8'>
                <div class='summary_icon'>
                  <div><i class='material-icons white'>person_pin</i></div>
                  <div class='stats' id='importedStat'></div>
                </div>
                <div class='stats_pct' id='importedStatPct'><div class='loading'>Loading...</div></div>
                <div class='stats-title'>Imported</div>
              </a>
            </div>
          </div>
        </div>
        <div class='page-content'>
          <div class='mdl-grid'>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_1' class='chart_container f-left' data-graph-id = 'PositiveCasesGraph'>
                   <div class='chart-title'>Number of Positive Cases by Age Group</div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                   <div id='chart_1' class='chart'></div>
                </div>
            </div>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_2' class='chart_container f-left' data-graph-id = 'IncidentsGraph'>
                   <div class='chart-title'>Number of Positive Cases: Current vs Last Year</div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                   <div id='chart_2' class='chart'></div>
                </div>
            </div>
          </div>
          <div class='mdl-grid'>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_3' class='chart_container f-left' data-graph-id = 'AttendanceGraph'>
                   <div class='chart-title'>Attendance</div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                   <div id='chart_3' class='chart'></div>
                </div>
            </div>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_4' class='chart_container f-left' data-graph-id = 'TestRateGraph'>
                  <div class='chart-title'>Test Rate</div>
                  <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                  <div id='chart_4' class='chart'></div>
                </div>
            </div>
          </div>
          <div class='mdl-grid'>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_6' class='chart_container f-left' data-graph-id = 'TimeToNotify'>
                  <div class='chart-title'>Time To Notify (#{Coconut.config.case_notification} hours)</div>
                  <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                  <div id='chart_6' class='chart'></div>
                </div>
            </div>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_5' class='chart_container f-left' data-graph-id = 'TimeToComplete'>
                   <div class='chart-title'>Time To Follow-up (#{Coconut.config.case_followup} hours)</div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                   <div id='chart_5' class='chart'></div>
                </div>
            </div>
          </div>
        </div>
          <div class='mdl-grid'>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                <div id='container_7' class='chart_container f-left' data-graph-id = 'PositivityGraph'>
                   <div class='chart-title'>Number of Persons Tested and Number Positive</div>
                   <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                   <div id='chart_7' class='chart'></div>
                </div>
            </div>
            <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
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

    Coconut.database.query "caseCounter",
      startkey: [startDate]
      endkey: [endDate]
      reduce: false
      include_docs: false
    .then (result) =>
        if (result.rows.length < 2 or _.isEmpty(result.rows[0]))
          #No result for date range, and so using default date for the current year
          Coconut.router.reportViewOptions.endDate = endDate = moment().format('YYYY-MM-DD')
          Coconut.router.reportViewOptions.startDate = startDate = moment().dayOfYear(1).format('YYYY-MM-DD')
          Coconut.dateSelectorView.startDate = startDate
          Coconut.dateSelectorView.endDate = endDate
          Coconut.dateSelectorView.render()
          displayError()
          options = $.extend({},Coconut.router.reportViewOptions)
          Coconut.database.query "caseCounter",
            startkey: [startDate]
            endkey: [endDate]
            reduce: false
            include_docs: false
          .then (result) =>
            dataForGraph = result.rows
            showStats()
            @showGraphs(dataForGraph,options)
        else
          dataForGraph = result.rows
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

    composite0 = dc.compositeChart("#chart_1")
    composite1 = dc.compositeChart("#chart_2")
    composite2 = dc.compositeChart("#chart_3")
    composite3 = dc.compositeChart("#chart_4")
    chart4 = dc.barChart("#chart_5")
    chart5 = dc.barChart("#chart_6")
    composite6 = dc.compositeChart("#chart_7")

    # Incident Graph - Number of Cases for current and last year
    startDate = moment().year()+'-01-01'
    endDate = moment().year()+'-12-31'
    lastYearStart = moment(startDate).subtract(1,'year').year()+'-01-01'
    lastYearEnd = moment(endDate).subtract(1,'year').year()+'-12-31'

    Coconut.database.query "caseCounter",
      startkey: [lastYearStart]
      endkey: [endDate]
      reduce: false
      include_docs: false
    .then (result) =>
      data = result.rows
      dataForGraph1 = _.filter(data, (d) ->
        return d.key[1] is "Number Positive Cases Including Index" and d.key[0] >= startDate
      )
      dataForGraph2 = _.filter(data, (d) ->
        return d.key[1] is "Number Positive Cases Including Index" and d.key[0] < startDate
      )
      Graphs.incidents(dataForGraph1, dataForGraph2, composite1, 'container_2', options,() ->
        $('div#container_2 div.mdl-spinner').hide()
      )
    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

    # PositiveCases Graph
    Graphs.positiveCases(dataForGraph, composite0, 'container_1', options)
    $('div#container_1 div.mdl-spinner').hide()

    # TimeToComplete Graph
    options.pct100 = false   #Do not show the Percentage chart
    Graphs.timeToComplete(dataForGraph, chart4, 'container_5', options)
    $('div#container_5 div.mdl-spinner').hide()

    #TimeToNotify Graph
    options.pct100 = false   #Do not show the Percentage chart
    Graphs.timeToNotify(dataForGraph, chart5, 'container_6', options)
    $('div#container_6 div.mdl-spinner').hide()

    #Positivity Graph
    Graphs.positivityCases(dataForGraph, composite6, 'container_7', options)
    $('div#container_7 div.mdl-spinner').hide()

    # Graphs using weeklyDataCounter query
    startYear = moment(options.startDate).isoWeekYear().toString()
    startWeek = ("00" + moment(options.startDate).isoWeek().toString()).slice(-2)
    endYear = moment(options.endDate).isoWeekYear().toString()
    endWeek = ("00" + moment(options.endDate).isoWeek().toString()).slice(-2)

    Coconut.database.query "weeklyDataCounter",
      start_key: [startYear, startWeek]
      end_key: [endYear,endWeek,{}]
      reduce: true
      include_docs: false
      group: true
    .then (result) =>
      dataForGraph = result.rows
      dataForGraph.forEach((d) ->
         d.dateWeek = moment(d.key[0] + "-" + d.key[1], "GGGG-WW")
      )
       # Attendance Graph
      Graphs.attendance(dataForGraph, composite2, 'container_3', options)
      $('div#container_3 div.mdl-spinner').hide()

      #TestRate Graph
      Graphs.testRate(dataForGraph, composite3, 'container_4', options)
      $('div#container_4 div.mdl-spinner').hide()
    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

    window.onresize = () ->
      adjustButtonSize()
      new_height = 0.45 *  $(".chart_container").width()
      $(".chart_container").css('height',new_height)
      $(".chart_container").height(0.44 * $(".chart_container").width())

      Graphs.compositeResize(composite0, 'chart_container', options)
      Graphs.compositeResize(composite1, 'chart_container', options)
      Graphs.compositeResize(composite2, 'chart_container', options)
      Graphs.compositeResize(composite3, 'chart_container', options)
      Graphs.chartResize(chart4, 'chart_container', options)
      Graphs.chartResize(chart5, 'chart_container', options)
      Graphs.compositeResize(composite6, 'chart_container', options)


  showStats = () ->
    Coconut.statistics.alerts = 0
    Coconut.statistics.alarms = 0
    Coconut.statistics.notified = 0
    Coconut.statistics.notfollowed = 0
    Coconut.statistics.hsat = 0
    Coconut.statistics.hsattested = 0
    Coconut.statistics.fsat = 0
    Coconut.statistics.imported = 0

    alertAlarmCounter()

    #Grouped by ISO Year Week
    # groupCaseCounterResult "GGGG-WW",
    #   success: (result) ->
    #     console.log("Grouped by ISO Year Week")
    #     console.log(result)

    #Grouped by Year
    groupCaseCounterResult "YYYY",
      success: (result) ->
        _.each(result, (d) ->
          Coconut.statistics.notified += d["Has Notification"]
          Coconut.statistics.notfollowed += (d["Has Notification"] - d["Followed Up"])
          Coconut.statistics.imported += d["Number Index And Household Cases Suspected To Be Imported"]
          Coconut.statistics.hsat += d["Number Household Members Tested Positive"]
          Coconut.statistics.fsat += d["Number Positive Cases From Mass Screen"] if d["Number Positive Cases From Mass Screen"]?
          Coconut.statistics.hsattested += d["Number Household Members Tested"]
        )
        Coconut.statistics.notfollowed_pct = getPercentage(Coconut.statistics.notfollowed, Coconut.statistics.notified)
        Coconut.statistics.imported_pct = getPercentage(Coconut.statistics.imported, Coconut.statistics.notified)
        Coconut.statistics.hsat_pct = getPercentage(Coconut.statistics.hsat, Coconut.statistics.hsattested)
        displayStatistics()

  adjustButtonSize = () ->
    noButtons = 8
    summaryWidth = $('#dashboard-summary').width()
    buttonWidth = (summaryWidth - 14)/noButtons
    $('.chip').width(buttonWidth-2)

  displayStatistics = () ->
    $('#alertStatPct').html('')
    $('#alarmStatPct').html('')
    if Coconut.statistics.notified?
      $('#notifiedStat').html(Coconut.statistics.notified)
      $('#notifiedStatPct').html('')
    if Coconut.statistics.notfollowed?
      $('#notfollowStat').html(Coconut.statistics.notfollowed)
      $('#notfollowStatPct').html(Coconut.statistics.notfollowed_pct)
    if Coconut.statistics.hsat?
       $('#hsatStat').html(Coconut.statistics.hsat)
       $('#hsatStatPct').html(Coconut.statistics.hsat_pct)
    if Coconut.statistics.hsattested?
       $('#hsattestStat').html(Coconut.statistics.hsattested)
       $('#hsattestStatPct').html('')
#    $('#fsatStat').html(Coconut.statistics.fsat) if Coconut.statistics.fsat?
    $('#importedStat').html(Coconut.statistics.imported)
    $('#importedStatPct').html(Coconut.statistics.imported_pct) if Coconut.statistics.imported?

  getPercentage = (numerator,denominator) ->
    return ' (' + ((numerator/ denominator) * 100).toFixed(1) + '% )'

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

  alertAlarmCounter = () ->
   options = $.extend({},Coconut.router.reportViewOptions)
   Coconut.database.query "alertAlarmCounter",
     startkey: [options.startDate,{}]
     endkey: [options.endDate,{}]
     reduce: true
     group: true
   .then (result) ->
     _(result.rows).each (result) ->
       Coconut.statistics.alerts += result.value if result.key[1] is "Alert"
       Coconut.statistics.alarms += result.value if result.key[1] is "Alarm"

     $('#alertStat').html(Coconut.statistics.alerts) if Coconut.statistics.alerts?
     $('#alarmStat').html(Coconut.statistics.alarms) if Coconut.statistics.alarms?

module.exports = DashboardView
