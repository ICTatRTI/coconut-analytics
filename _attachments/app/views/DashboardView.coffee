_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'

class DashboardView extends Backbone.View
  el: "#content"

  render: =>

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
    "
    Coconut.router.showDateFilter(@startDate,@endDate)

module.exports = DashboardView
