_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Graphs = require '../models/Graphs'
require('jquery-ui/draggable')

class DashboardView extends Backbone.View
  el: "#content"

  events:
    "click #container_1": "graph1"
    "click #container_2": "graph2"
  
  graph1: (e) ->
    Coconut.router.navigate("#graphs/type/IncidentsGraph", {trigger: true})

  graph2: (e) ->
    Coconut.router.navigate("#graphs/type/PositiveCasesGraph", {trigger: true})
        
  render: =>
    $('#analysis-spinner').show()
    @$el.html "
        <style>.page-content {margin: 0} </style>
        <div id='dateSelector'></div>
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
                <div id='container_1' class='chart_container f-left'>
                  <div class='mdl-grid'>
                    <div class='mdl-cell mdl-cell--11-col mdl-cell--7-col-tablet mdl-cell--3-col-phone'>
                      <div id='y_axis_1' class='y_axis'></div>
                      <div id='chart_1' class='chart'></div>
                    </div>
                    <div class='mdl-cell mdl-cell--1-col mdl-cell--1-col-tablet mdl-cell--1-col-phone'>
                      <div id='legend' class='legend'></div>
                    </div>
                  </div>
                </div>
                
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--4-col-tablet mdl-cell--4-col-phone'> 
                <div class='chart-title'>Number of Positive Cases</div>
                <div id='container_2' class='chart_container f-left'>
                  <div class='mdl-grid'>
                    <div class='mdl-cell mdl-cell--11-col mdl-cell--7-col-tablet mdl-cell--3-col-phone'>
                      <div id='y_axis_2' class='y_axis'></div>
                      <div id='chart_2' class='chart'></div>
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
    #$("#chart_box_1, #chart_box_2, #chart_box_3, #chart_box_4").draggable()
    
    options = $.extend({},Coconut.router.reportViewOptions)
    options.chart_height = 260
    options.startDate = '2015-01-01'
    options.endDate = '2015-12-31'
    # Incident Graph
    options.container = 'container_1'
    options.y_axis = 'y_axis_1'
    options.chart = 'chart_1'
    options.legend = "legend"
    Graphs.IncidentsGraph options, (err, response) ->
      if (err)
        console.log(err)
        $('#analysis-spinner').hide()
      else
        # #PositiveCases
        options.container = 'container_2'
        options.y_axis = 'y_axis_2'
        options.chart = 'chart_2'
        options.legend = "legend2"
        Graphs.PositiveCasesGraph options, (err2, response2) ->
          if (err2)
            console.log(err2)
            $('#analysis-spinner').hide()
          else
            # Example Graph
            options.container = 'container_3'
            options.y_axis = 'y_axis_3'
            options.chart = 'chart_3'
            options.legend = "legend3"
            Graphs.BarChart options, (err3, response3) ->
              if (err3) 
                console.log(err3)
                $('#analysis-spinner').hide()
              else
                options.container = 'container_4'
                options.y_axis = 'y_axis_4'
                options.chart = 'chart_4'
                options.legend = "legend4"
                Graphs.ScatterPlotChart options, (err4, response4) ->
                  if (err4) 
                    console.log(err4)
                  
                  $('#analysis-spinner').hide()
   
module.exports = DashboardView
