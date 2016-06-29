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
  
  graph1: (e) ->
    Coconut.router.navigate("#graphs/type/IncidentsGraph", {trigger: true})
    
  render: =>
    $('#analysis-spinner').show()
    @$el.html "
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
            <div class='mdl-cell mdl-cell--6-col mdl-cell--8-col-tablet'>
              <div id='chart_box_1' class='ui-widget-content draggable'>
                <div class='chart-title'>Incidence Graph - cases by week</div>
                <div id='container_1' class='chart_container f-left'>
                  <div id='y_axis_1' class='y_axis'></div>
                  <div id='chart_1' class='chart'></div>
                </div>
              </div>
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--8-col-tablet'>
              <div id='chart_box_2' class='ui-widget-content draggable'>
                <div class='chart-title'>Line Graph</div>
                <div id='container_2' class='chart_container f-left'>
                  <div id='y_axis_2' class='y_axis'></div>
                  <div id='chart_2' class='chart'></div>
                </div>
              </div>
            </div>
          </div>
          <div class='mdl-grid'>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--8-col-tablet'>
              <div id='chart_box_3' class='ui-widget-content draggable'>
                <div class='chart-title'>Bar Graph</div>
                <div id='container_3' class='chart_container f-left'>
                  <div id='y_axis_3' class='y_axis'></div>
                  <div id='chart_3' class='chart'></div>
                </div>
              </div>
            </div>
            <div class='mdl-cell mdl-cell--6-col mdl-cell--8-col-tablet'>
              <div id='chart_box_4' class='ui-widget-content draggable'>
                <div class='chart-title'>ScatterPlot Graph</div>
                <div id='container_4' class='chart_container f-left'>
                  <div id='y_axis_4' class='y_axis'></div>
                  <div id='chart_4' class='chart'></div>
                </div>
              </div>
            </div>
          </div>
        </div>
    "
    #$("#chart_box_1, #chart_box_2, #chart_box_3, #chart_box_4").draggable()
    
    options = $.extend({},Coconut.router.reportViewOptions)
    options.chart_width = 430
    options.chart_height = 260
    options.container = 'container_1'
    options.y_axis = 'y_axis_1'
    options.chart = 'chart_1'
    
    Graphs.IncidentsGraph options, (err, response) ->
      if (err) then console.log(err)
    
    options.container = 'container_2'
    options.y_axis = 'y_axis_2'
    options.chart = 'chart_2'
    Graphs.YearlyTrends options, (err2, response2) ->
      if (err2) then console.log(err2)
    
    options.container = 'container_3'
    options.y_axis = 'y_axis_3'
    options.chart = 'chart_3'
    Graphs.BarChart options, (err3, response3) ->
      if (err3) then console.log(err3)
      
    options.container = 'container_4'
    options.y_axis = 'y_axis_4'
    options.chart = 'chart_4'
    Graphs.ScatterPlot options, (err4, response4) ->
      if (err4) then console.log(err4)
      $('#analysis-spinner').hide()
      
module.exports = DashboardView
