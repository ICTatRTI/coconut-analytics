_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require( 'datatables.net' )()
Graphs = require '../models/Graphs'

class DashboardView extends Backbone.View
  el: "#content"

  render: =>
    $('#analysis-spinner').show()
    @$el.html "
        <div id='dateSelector'></div>
        <div id='dashboard-summary'>
          <div class='sub-header-color relative clear'>
            <div class='mdl-grid'>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                <div class='summary' id='summary1'> 
                  <div class='stats'>54</div>
                  <div class='stats-title'>ALERTS</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                <div class='summary' id='summary2'> 
                  <div class='stats'>76</div>
                  <div class='stats-title'>CASES</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                <div class='summary' id='summary3'> 
                  <div class='stats'>32</div>
                  <div class='stats-title'>ISSUES</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                <div class='summary' id='summary4'> 
                  <div class='stats'>10</div>
                  <div class='stats-title'>PILOT</div>
                </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                <div class='summary' id='summary1'> </div>
              </div>
              <div class='mdl-cell mdl-cell--2-col mdl-cell--4-col-tablet'>
                <div class='summary' id='summary1'> </div>
              </div>
            </div>
          </div>
        </div>
        <div class='mdl-grid'>
          <div class='mdl-cell mdl-cell--5-col mdl-cell--6-col-tablet'>
          </div>
          <div class='mdl-cell mdl-cell--7-col mdl-cell--9-col-tablet'>
            <div class='m-l-30'><h5>Incidents Graph</h5></div>
            <div id='container_1' class='chart_container'>
              <div id='y_axis_1' class='y_axis'></div>
              <div id='chart_1' class='chart'></div>
            </div>
          </div>
        </div>
    "
    #Coconut.router.showDateFilter(@startDate,@endDate)
    options = $.extend({},Coconut.router.reportViewOptions)
    options.container = 'container_1'
    options.y_axis = 'y_axis_1'
    options.chart = 'chart_1'
    options.chart_width = 435
    options.chart_height = 263
    
    Graphs.IncidentsGraph options, (err, response) ->
      if (err) then console.log(err)
    $('#analysis-spinner').hide()
      
module.exports = DashboardView
