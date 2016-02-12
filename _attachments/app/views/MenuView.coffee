_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class MenuView extends Backbone.View
  events:
    "click a#dashboard": "showDashboard"
    "click a.report__link": "showReports"
    "click a.activity__link": "showActivity"
    "click a.drawer__link": "showLink"
    "click a.setting__link": "showSetting"
    "click a.admin__link": "showAdmin"
    "click a.graphs__link": "showGraph"
    "click a.drawer__subtitle": "toggleDropdownMenu"

  toggleDropdownMenu: (e) =>
    e.preventDefault
    $target = $(e.target)
    hidden = $target.next("div.dropdown").is(":hidden");
    $("div.dropdown").slideUp();
    if (!hidden)
      $target.next("div.dropdown").slideUp()
    else
      $target.next("div.dropdown").slideToggle()

  showDashboard: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    @setTitle(e, 'Dashboard')
	
  showReports: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    if classStr.indexOf('drawer_subtitle') is -1
      @setActiveLink(e)
    @setTitle(e, 'Reports')

  showLink: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    @setActiveLink(e)

  showSetting: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    @setActiveLink(e)
    @setTitle(e, 'Settings')	 

  showAdmin: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    @setActiveLink(e) 
    @setTitle(e, 'Admin')

  showActivity: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    @setActiveLink(e) 
    @setTitle(e, 'Activity')

  showGraph: (e) =>
    e.preventDefault
    reportname = e.currentTarget.id
    classStr = $(e.currentTarget).attr('class')
    @setActiveLink(e)
    @setTitle(e,'Graph')

  setTitle: (e, title) ->
    id = e.currentTarget.id
    subtitle = e.currentTarget.innerText
    if (subtitle == '' || id == 'dashboard')
      newtitle = title
    else
      newtitle = title + ": <span class='menu-subtitle'>" + subtitle + "</span>"
    $('#layout-title').html(newtitle)

  setActiveLink: (e) =>
    @removeActive()
    $(e.target).addClass("active")

  removeActive: =>
    $("a.mdl-navigation__link").removeClass("active")

  render: => 
    @$el.html "
      <header class='coconut-drawer-header'>
	  <div class='clear m-t-30'>
	    <div class='f-left m-l-20'><img src='images/CSLogo.png' id='cslogo_sm'></div>
	    <div class='mdl-layout-title' id='drawer-title'>Coconut<br />Surveillance</div>
	  </div>
	  </header>		  
	  <nav class='coconut_navigation mdl-navigation'>
		<a class='mdl-navigation__link drawer__subtitle' id='dashboard' href='/index.html#dashboard'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>dashboard</i>Dashboard</a>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='report-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>description</i>
		Reports</a>
		<div class='m-l-20 dropdown' id='drawer-reports'>

      #{
        links = {
          alerts: "Alerts"
          analysis: "Analysis"
          casefollowup: "Case Followup"
          compareweekly: "Compare Weekly"
          epidemicthreshold: "Epidemic Thresholds"
          incidentsgraph: "Incidents Graph"
          periodsummary: "Period Summary"
          pilotnotification: "Pilot Notifications"
          rainfallreport: "Rainfall Report"
          systemerrors: "System Errors"
          usersreport: "Users Report"
          weeklyreports: "Weekly Reports"
          weeklysummary: "Weekly Summary"
        }
        _(links).map (linkText, linkUrl) ->
          "<a class='mdl-navigation__link report__link' id = '#{linkUrl}' href='#reports/#{linkUrl}'>#{linkText}</a>"
        .join ""
      }
	  </div>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='activity-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>local_activity</i>
		Activities
	    </a>
		<div class='m-l-20 dropdown' id='drawer-activities'> 
			<a class='mdl-navigation__link  activity__link' id='issues' href='#'>Issues</a> 
			<a class='mdl-navigation__link activity__link' id='todos' href='#'>To Do</a> 
			<a class='mdl-navigation__link  activity__link' id='sms' href='#'>Send SMS to users</a> 
		</div>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='graphs-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>assessment</i>
		Graphs
	    </a>
		<div class='m-l-20 dropdown' id='drawer-graphs'>
      #{
           links2 = {
             graph_attendance: "Attendance"
             graph_positivity: "Positivity"
             graph_testrate: "Test Rate"
             positivity_with_rainfall: "Positivity with Rainfall"
             positivity_by_year: "Positivity cases by year"
           }
           _(links2).map (linkText, linkUrl) ->
             "<a class='mdl-navigation__link graph__link' id = '#{linkUrl}' href='#reports/#{linkUrl}'>#{linkText}</a>"
           .join ""
      }		   
		</div>
		<a class='mdl-navigation__link drawer__link' href='#reports/maps' id='maps' data-name='Maps'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>map</i>
		  <span class='link-title'>Maps</span>
	    </a>
		<a class='mdl-navigation__link drawer__link' href='#reports/export' id='export' data-name='Data Export'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>cloud_download</i>
		  <span class='link-title'>Data Export</span>
	    </a>		
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='setting-main'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>settings</i>
		Settings
	    </a>
		<div class='m-l-20 dropdown' id='drawer-settings'> 
	        <a class='mdl-navigation__link setting__link' id='setting_theme' href='#'>Color Theme</a>				
	        <a class='mdl-navigation__link setting__link' id='setting_general' href='#'>General</a>				   
	        <a class='mdl-navigation__link setting__link' id='setting_language' href='#'>Language</a>	
	        <a class='mdl-navigation__link setting__link' id='setting_misc' href='#'>Miscellaneous</a>
		</div>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='admin-main'>  
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
