_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class MenuView extends Backbone.View

  render: =>
    @$el.html "
	  <div class='clear m-t-30'>
	    <div class='f-left m-l-20'><img src='img/CSLogo.png' id='cslogo_sm'></div>
	    <div class='mdl-layout-title' id='drawer-title'>Coconut<br />Surveillance</div>
	  </div>		  
	  <nav class='mdl-navigation'>
		<a class='mdl-navigation__link report__link drawer__subtitle' id='dashboard' href='/index.html#dashboard'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>dashboard</i>
		  Dashboard</a>
		<a class='mdl-navigation__link report__link drawer__subtitle' href='#' id='report-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>description</i>
		Reports</a>
		<div class='m-l-20 dropdown' id='drawer-reports'>
	    <a class='mdl-navigation__link report__link' id = 'alerts' href='#reports/alerts'>
			Alerts</a>
	    <a class='mdl-navigation__link report__link' id = 'analysis' href='#reports/analysis'>
			Analysis</a>    
	    <a class='mdl-navigation__link report__link m-b-20' id = 'casefollowup' href='#reports/casefollowup'>
			Case Follow Up</a>
		<a class='mdl-navigation__link report__link' id = 'compareweekly' href='#reports/compareweekly'>
			Compare Weekly with Cases Followup</a>
		<a class='mdl-navigation__link report__link' id = 'epidemicthreshold' href='#reports/epidemicthresholds'>
			Epidemic Thresholds</a>		
		<a class='mdl-navigation__link report__link' id = 'incidentsgraph' href='#reports/incidentsgraph'>
			Incidents Graph</a>	
		<a class='mdl-navigation__link report__link' id = 'periodsummary' href='#reports/periodsummary'>
			Period Summary</a>
		<a class='mdl-navigation__link report__link' id = 'pilotnotification' href='#reports/pilotnotifications'>
			Pilot Notifications</a>
		<a class='mdl-navigation__link report__link' id = 'rainfallreport' href='#reports/rainfallreport'>
			Rainfall Report</a>	
		<a class='mdl-navigation__link report__link' id = 'systemerrors' href='#reports/systemerrors'>
			System Errors</a>
		<a class='mdl-navigation__link report__link' id = 'usersreport' href='#reports/usersreport'>
			Users Report</a>
		<a class='mdl-navigation__link report__link' id = 'weeklyreports' href='#reports/weeklyreports'>
			Weekly Reports</a>		
		<a class='mdl-navigation__link report__link' id = 'weeklysummary' href='#reports/weeklysummary'>
			Weekly Summary</a>	
	   </div>
		<a class='mdl-navigation__link report__link drawer__subtitle' href='#' id='activity-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>local_activity</i>
		Activities
	    </a>
		<div class='m-l-20 dropdown' id='drawer-activities'> 
			<a class='mdl-navigation__link  activity__link' id='issues' href='#'>Issues</a> 
			<a class='mdl-navigation__link activity__link' id='todos' href='#'>To Do</a> 
			<a class='mdl-navigation__link  activity__link' id='sms' href='#'>Send SMS to users</a> 
		</div>
		<a class='mdl-navigation__link report__link drawer__subtitle' href='#' id='graphs-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>assessment</i>
		Graphs
	    </a>
		<div class='m-l-20 dropdown' id='drawer-graphs'> 
			<a class='mdl-navigation__link graphs__link' id='graph_attendance' href='#'>Attendance</a> 
			<a class='mdl-navigation__link graphs__link' id='graph_testrate' href='#'>Test Rate</a> 
			<a class='mdl-navigation__link graphs__link' id='graph_positivity' href='#'>Positivity</a> 
			<a class='mdl-navigation__link graphs__link' id='positivity_with_rainfall' href='#'>Positivity with Rainfall</a> 
			<a class='mdl-navigation__link graphs__link' id='positivity_by_year' href='#'>Positivity cases by year</a> 
		</div>
		<a class='mdl-navigation__link drawer__link' href='#reports/maps' id='maps' data-name='Maps'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>map</i>
		  <span class='link-title'>Maps</span>
	    </a>
		<a class='mdl-navigation__link drawer__link' href='#reports/export' id='export' data-name='Data Export'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>cloud_download</i>
		  <span class='link-title'>Data Export</span>
	    </a>		
		<a class='mdl-navigation__link report__link drawer__subtitle' href='#' id='setting-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>settings</i>
		Settings
	    </a>
		<div class='m-l-20 dropdown' id='drawer-settings'> 
	        <a class='mdl-navigation__link setting__link' id='setting_theme' href='#'>Color Theme</a>				
	        <a class='mdl-navigation__link setting__link' id='setting_general' href='#'>General</a>				   
	        <a class='mdl-navigation__link setting__link' id='setting_language' href='#'>Language</a>	
	        <a class='mdl-navigation__link setting__link' id='setting_misc' href='#'>Miscellaneous</a>
		</div>
		<a class='mdl-navigation__link report__link drawer__subtitle' href='#' id='admin-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>build</i>
		Admin
	    </a>
		<div class='m-l-20 dropdown' id='drawer-admin'> 				   
			<a class='mdl-navigation__link admin__link' id='facilities' href='#'>Facilities</a>
			 <a class='mdl-navigation__link admin__link' id='questions' href='#'>Question Sets</a>	
			<a class='mdl-navigation__link admin__link' id='rainfall-station' href='#'>Rainfall Station</a>
			<a class='mdl-navigation__link admin__link' id='regions-districts-shehias' href='#'>Regions, Districts & Shehias </a>	
			<a class='mdl-navigation__link admin__link' id='shehias-irs' href='#'>Shehias received IRS</a>
			<a class='mdl-navigation__link admin__link' id='high-risk' href='#'>Shehias high risk</a>
	        <a class='mdl-navigation__link admin__link' id='users' href='#'>Users</a>				
		</div>	
	  </nav>
    "

module.exports = MenuView
