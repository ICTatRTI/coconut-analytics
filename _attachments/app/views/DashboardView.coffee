_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Reports = require '../models/Reports'
Graphs = require '../models/Graphs'
moment = require 'moment'
Dialog = require './Dialog'

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
            <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--4-col-phone'>
                <div class='chart-title'>Number of Cases</div>
                <div id='container_1' class='chart_container f-left' data-graph-id = 'IncidentsGraph'>
                  <div class='mdl-grid'>
                    <div class='mdl-cell mdl-cell--11-col mdl-cell--7-col-tablet mdl-cell--3-col-phone'>
                      <div id='y_axis_1' class='y_axis'></div>
                      <div id='chart_1' class='chart'></div>
                      <div class='graph-spinner mdl-spinner mdl-js-spinner is-active'></div>
                    </div>
                    <div class='mdl-cell mdl-cell--1-col mdl-cell--1-col-tablet mdl-cell--1-col-phone'>
                      <div id='legend' class='legend'></div>
                    </div>
                  </div>
                </div>
                
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--4-col-phone'> 
                <div class='chart-title'>Number of Positive Cases by Age Group</div>
                <div id='container_2' class='chart_container f-left' data-graph-id = 'PositiveCasesGraph'>
                  <div class='mdl-grid'>
                    <div class='mdl-cell mdl-cell--11-col mdl-cell--7-col-tablet mdl-cell--3-col-phone'>
                      <div id='y_axis_2' class='y_axis'></div>
                      <div id='chart_2' class='chart'></div>
                      <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                    </div>
                    <div class='mdl-cell mdl-cell--1-col mdl-cell--1-col-tablet mdl-cell--1-col-phone'> 
                      <div id='legend2' class='legend'></div>
                    </div>
                  </div>
                </div>
            </div>
          </div>
          <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--4-col-phone'>
                <div class='chart-title'>Bar Graph</div>
                <div id='container_3' class='chart_container f-left'>
                  <div class='mdl-grid'>
                    <div class='mdl-cell mdl-cell--10-col mdl-cell--7-col-tablet mdl-cell--3-col-phone'> 
                        <div id='y_axis_3' class='y_axis'></div>
                        <div id='chart_3' class='chart'></div>
                        <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                    </div>
                    <div class='mdl-cell mdl-cell--1-col mdl-cell--1-col-tablet mdl-cell--1-col-phone'> 
                        <div id='legend3' class='legend'></div>
                    </div>
                  </div>
                </div>
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--4-col-phone'>
                <div class='chart-title'>ScatterPlot Graph</div>
                <div id='container_4' class='chart_container f-left'>
                  <div class='mdl-grid'>
                    <div class='mdl-cell mdl-cell--10-col mdl-cell--7-col-tablet mdl-cell--3-col-phone''> 
                      <div id='y_axis_4' class='y_axis'></div>
                      <div id='chart_4' class='chart'></div>
                      <div class='mdl-spinner mdl-js-spinner is-active graph-spinner'></div>
                    </div>
                    <div class='mdl-cell mdl-cell--1-col mdl-cell--1-col-tablet mdl-cell--1-col-phone'>
                      <div id='legend4' class='legend'></div>
                    </div>
                  </div>
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
        displayError
          success: ->
            Coconut.router.reportViewOptions.endDate = endDate = moment().format('YYYY-MM-DD')
            Coconut.router.reportViewOptions.startDate = startDate = moment().dayOfYear(1).format('YYYY-MM-DD')
            Coconut.dateSelectorView.startDate = startDate
            Coconut.dateSelectorView.endDate = endDate
            Coconut.dateSelectorView.render()
            view.showStats(startDate, endDate)
            view.showGraphs(startDate, endDate)
        
      else
        @showStats(startDate, endDate)
        @showGraphs(startDate, endDate)

  showGraphs: (startDate, endDate) ->
    @chart_height = 260
    # Incident Graph
    Graphs.IncidentsGraph
      chart_height: @chart_height
      startDate: startDate
      endDate: endDate
      container: 'container_1'
      y_axis: 'y_axis_1'
      chart: 'chart_1'
      legend: 'legend'
    .catch (error) ->
      console.error error
    .then (response) ->
      $('div#container_1 div.mdl-spinner').hide()

    # PositiveCases
    Graphs.PositiveCasesGraph
      chart_height: @chart_height
      startDate: startDate
      endDate: endDate
      container: 'container_2'
      y_axis: 'y_axis_2'
      chart: 'chart_2'
      legend: "legend2"
    .catch (error) ->
      console.error error
    .then (response) ->
      $('div#container_2 div.mdl-spinner').hide()

    # Example Bar Graph
    Graphs.BarChart
      chart_height: @chart_height
      startDate: startDate
      endDate: endDate
      container: 'container_3'
      y_axis: 'y_axis_3'
      chart: 'chart_3'
      legend: "legend3"
    .catch (error) ->
      console.error error
    .then (response) ->
      $('div#container_3 div.mdl-spinner').hide()

    # Example ScatterPlot Graph
    Graphs.ScatterPlotChart
      chart_height: @chart_height
      startDate: startDate
      endDate: endDate
      container: 'container_4'
      y_axis: 'y_axis_4'
      chart: 'chart_4'
      legend: "legend4"
    .catch (error) ->
      console.error error
    .then (response) ->
      $('div#container_4 div.mdl-spinner').hide()

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
    
  displayError = (options) ->
    $('div#noDataFound').show()
    setTimeout ->
      $('div#noDataFound').fadeOut()
      options.success(true)
    , 4000
    
    
  filterByDate = (options) ->
    return new Promise (resolve,reject) -> 
      cases = _.filter options.rows, (row) ->
        return moment(row.key).isBetween(options.startDate, options.endDate)
      resolve(cases)    
    
module.exports = DashboardView
