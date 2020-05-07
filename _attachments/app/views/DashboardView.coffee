_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

moment = require 'moment'
global.Graphs = require '../models/Graphs'

camelize = require "underscore.string/camelize"


class DashboardView extends Backbone.View
  el: "#content"

  events:
    "click .moreInfo": "toggle"

  toggle: (event) =>
    @$(event.target).closest("div").next().toggle()

  render: =>

    options = $.extend({},Coconut.router.reportViewOptions)
    @startDate = options.startDate
    @endDate = options.endDate

    Coconut.statistics = Coconut.statistics || {}
    # $('#analysis-spinner').show()
    HTMLHelpers.ChangeTitle("Dashboard")
    @$el.html "
        <style>
          .page-content {margin: 0}
          .chart {left: 0; padding: 5px}
          .chart_container {width: 100%}

        </style>
        <div id='dateSelector' style='display:inline-block'></div>
        <div id='dateDescription' style='display:inline-block;vertical-align:top;margin-top:10px'></div>
        <dialog id='dialog'>
          <div id='dialogContent'> </div>
        </dialog>
        <div>
          <div class='moreInfo'>
            <i class='mdi mdi-play mdi-24px'></i>
            Indicators
          </div>
          <div style='display:none'>
            Alerts and Alarms show the epidemic thresholds, which are automatically checked every night.<br/>





          </div>
        </div>
        <div id='dashboard-summary'>
          <div class='sub-header-color relative clear'>
            #{
                (for chipData,index in [
                  class: "alertStat"
                  title: "Alerts"
                  icon: "mdi-bell-ring-outline"
                ,
                  class: "alarmStat"
                  title: "Alarms"
                  icon: "mdi-bell-ring"
                ,
                  class: "notFollowedUp"
                  title: "Not Followed Up"
                  icon: "mdi-account-location"
                ]
                  "
                    <div class='stat_summary'>
                      <a class='chip summary#{index+1}'>
                        <div class='summary_icon'>
                          <div><i class='mdi #{chipData.icon} mdi-24px white'></i></div>
                          <div class='stats' id='#{chipData.class}'></div>
                        </div>
                        <div class='stats-title'>#{chipData.title}</div>
                      </a>
                    </div>
                  "
                ).join("")
            }
          </div>
        </div>
        <div class='page-content'>
          <div class='mdl-grid'>
          #{
            (for title, graph of Graphs.definitions
              "
                <div class='chart mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--2-col-phone'>
                  <div id='container_#{index+1}' class='chart_container f-left'>
                    <div class='moreInfo'>
                      <i class='mdi mdi-play mdi-24px'></i>
                      #{title}
                    </div>
                    <div style='display:none'>
                      #{graph.description} 
                    <a href='#graphs/#{camelize(title)}/#{@startDate}/#{@endDate}'>
                     Large version with more details
                    </a>
                      
                    </a>
                    </div>
                    <a href='#graphs/#{camelize(title)}/#{@startDate}/#{@endDate}'>
                      <div>
                        <canvas id='#{camelize(title)}'></canvas>
                      </div>
                    </a>
                  </div>
                </div>
                #{
                  if index+1%2 is 0 # 2 graphs per row
                    "</div><div class='mdl-grid'>"
                  else
                    ""
                }
              "
            ).join("")
          }
        </div>
    "
    adjustButtonSize()


    @showGraphs()

  showGraphs: =>

    momentStartDate = moment(@startDate)
    momentEndDate = moment(@endDate)

    data = await Graphs.definitions["Positive Individuals by Year"].dataQuery
      startDate: momentStartDate
      endDate: momentEndDate

    Graphs.render("Positive Individuals by Year", data)

    # Always have at least 4 weeks of data, and start at beginning of week so it's comparable data
    if momentEndDate.diff(momentStartDate, 'weeks') < 4
      momentStartDate = momentEndDate.clone().subtract(4, 'weeks').startOf("isoWeek")
      @$("#dateDescription").html "
        Start date shifted to #{momentStartDate.format('YYYY-MM-DD')} (week #{momentStartDate.isoWeek()}) to improve context
      "
    else
      @$("#dateDescription").html()

    @showOpdGraphs(momentStartDate, momentEndDate)
    @showCaseCounterGraphsAndIndicators(momentStartDate, momentEndDate)
    @renderAlertAlarmIndicators(momentStartDate, momentEndDate)

  showOpdGraphs: (momentStartDate, momentEndDate)=>
    # Get data 4 weeks before start date
    Coconut.database.query "weeklyDataCounter",
      start_key: momentStartDate.format("GGGG-WW").split(/-/)
      end_key: momentEndDate.format("GGGG-WW").split(/-/)
      reduce: true
      include_docs: false
      group: true
    .then (result) =>
      Graphs.render("OPD Visits By Age", result.rows)
      Graphs.render("OPD Testing and Positivity Rate", result.rows)
    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

  showCaseCounterGraphsAndIndicators: (momentStartDate, momentEndDate) =>

    data = await Coconut.reportingDatabase.query "caseCounter",
      startkey: [momentStartDate.format('YYYY-MM-DD')]
      endkey: [momentEndDate.format('YYYY-MM-DD'),{}]
      reduce: true
      group_level: 2 # Group District and Shehia
      include_docs: false
    .then (result) =>
      Promise.resolve(result.rows)
    .catch (error) ->
      console.error error
      $('div.mdl-spinner').hide()

    for graph in [
      "Positive Individuals by Age"
      "Positive Individual Classifications"
      "Hours from Positive Test at Facility to Notification"
      "Hours From Positive Test To Complete Follow-up"
      "Household Testing and Positivity Rate"
    ]
      Graphs.render(graph, data)

    @renderNotFollowedUpIndicator(data)

  renderNotFollowedUpIndicator: (dataByDate) =>
    notFollowedUp = 0
    hasNotification = 0
    for data in dataByDate
      if data.key[1] is "Followed Up"
        notFollowedUp -= data.value
      if data.key[1] is "Has Notification"
        notFollowedUp += data.value
        hasNotification += data.value

    percentNotFollowedUp = Math.round(notFollowedUp/hasNotification*100)
    @$('#notFollowedUp').html "#{notFollowedUp} <small>(#{percentNotFollowedUp}%)</small>"

  renderAlertAlarmIndicators: (startDate, endDate) =>
    alerts = 0
    alarms = 0
    Coconut.database.query "alertAlarmCounter",
      startkey: [startDate,{}]
      endkey: [endDate,{}]
      reduce: true
      group: true
    .then (result) =>
      for result in result.rows
        alerts += result.value if result.key[1] is "Alert"
        alarms += result.value if result.key[1] is "Alarm"

      @$('#alertStat').html(alerts)
      @$('#alarmStat').html(alarms)


  adjustButtonSize = () ->
    noButtons = 8
    summaryWidth = $('#dashboard-summary').width()
    buttonWidth = (summaryWidth - 14)/noButtons
    $('.chip').width(buttonWidth-2)

module.exports = DashboardView
