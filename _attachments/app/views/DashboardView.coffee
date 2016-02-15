_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'

DateSelectorView = require './DateSelectorView'

class DashboardView extends Backbone.View

  events: 
    "click button#dateFilter": "showForm"
  
  showForm: (e) =>
    e.preventDefault
    $("div#filters-section").slideToggle()

  render: =>

    @$el.html "
	  <div id='date-range'>
		<span id='filters-drop' class='drop-pointer'>
		     <button class='mdl-button mdl-js-button mdl-button--icon' id='dateFilter'> 
				<i class='material-icons'>event</i> 
			 </button> 
		</span>
		<span id='date-period'>#{@startDate} to #{@endDate}</span>
  	    <div id='filters-section' class='hide'>
		  <hr />
          <div id='dateSelector'></div>
		  <hr />
  	    </div>
	  </div>
    "

    Coconut.dateSelectorView = new DateSelectorView() unless Coconut.dateSelectorView
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.startDate = @startDate
    Coconut.dateSelectorView.endDate = @endDate
    Coconut.dateSelectorView.render()

module.exports = DashboardView
