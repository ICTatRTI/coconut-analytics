_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

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
                  <div class='stats'>54</div>
                  <div class='stats-title'>ALERTS</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary2'> 
                  <div class='stats'>76</div>
                  <div class='stats-title'>CASES</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary3'> 
                  <div class='stats'>32</div>
                  <div class='stats-title'>ISSUES</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--2-col-tablet'>
                <div class='summary' id='summary4'> 
                  <div class='stats'>10</div>
                  <div class='stats-title'>PILOT</div>
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
                <div class='chart-title'>Incidence Graph - cases by week</div>
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
                <div class='chart-title'>Number of Positive Cases</div>
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
    
    startDate = moment(Coconut.router.reportViewOptions.startDate).format('YYYY-MM-DD')
    endDate = moment(Coconut.router.reportViewOptions.endDate).format('YYYY-MM-DD')
    Coconut.database.query "#{Coconut.config.design_doc_name}/positiveCases",
      startkey: startDate
      endkey: endDate
      include_docs: false
    .catch (error) ->
      console.error error
    .then (result) =>      
      if result.rows.length == 0
        Coconut.database.query "#{Coconut.config.design_doc_name}/positiveCasesByDates",
          include_docs: false
        .catch (error) ->
          console.error error
        .then (results) =>
          #sort to get the latest positive case date as the end date and startDate be a month before that.
          results.rows.sort (a,b) ->
            if a.key < b.key
              return 1
            if a.key > b.key
              return -1
            if a.key = b.key
              return 0 
          Coconut.router.reportViewOptions.endDate = endDate = results.rows[0].key.substr(0,10)
          Coconut.router.reportViewOptions.startDate = startDate = moment(endDate).subtract(1, 'month').format('YYYY-MM-DD')

          Coconut.dateSelectorView.startDate = startDate
          Coconut.dateSelectorView.endDate = endDate
          Coconut.dateSelectorView.render()
          @showGraphs(startDate, endDate)
      else
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
      console.log("ScatterPlot failed")
      console.error error
    .then (response) ->
      console.log("ScatterPlot success")
      $('div#container_4 div.mdl-spinner').hide()

module.exports = DashboardView
