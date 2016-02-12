_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

class MenuView extends Backbone.View
  events:
    "click a.mdl-navigation__link": "changeStatus"
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

  changeStatus: (e) =>
    id = e.currentTarget.id
    category = e.currentTarget.dataset.category
    title = e.currentTarget.dataset.title
    if (category != 'menuHeader')
      if (category != 'menuLink')
        subtitle = e.currentTarget.innerHTML
        title = title + ": <span class='menu-subtitle'>" + subtitle + "</span>"
      $('#layout-title').html(title)
    @setActiveLink(e)

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
		<a class='mdl-navigation__link drawer__subtitle' id='dashboard' data-title='Dashboard' data-category='menuLink' href='/index.html#dashboard'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>dashboard</i>Dashboard</a>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='report-main' data-title='Reports' data-category='menuHeader'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>description</i>
		Reports</a>
		<div class='m-l-20 dropdown' id='drawer-reports'>

      #{
        reportLinks = {
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
        _(reportLinks).map (linkText, linkUrl) ->
          "<a class='mdl-navigation__link report__link' id = '#{linkUrl}' href='#reports/#{linkUrl}' data-title='Reports'>#{linkText}</a>"
        .join ""
      }
	  </div>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='activity-main' data-title='Activities' data-category='menuHeader'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>local_activity</i>
		Activities
	    </a>
		<div class='m-l-20 dropdown' id='drawer-activities'>
        #{
             activityLinks = {
               issues: "Issues"
               todos: "To Do"
               sms: "Send SMS to users"
             }
             _(activityLinks).map (linkText, linkUrl) ->
               "<a class='mdl-navigation__link activity__link' id = '#{linkUrl}' href='#activities/#{linkUrl}' data-title='Activities'>#{linkText}</a>"
             .join ""
        }
		</div>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='graphs-main' data-title='Graphs' data-category='menuHeader'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>assessment</i>
		Graphs
	    </a>
		<div class='m-l-20 dropdown' id='drawer-graphs'>
      #{
           graphLinks = {
             graph_attendance: "Attendance"
             graph_positivity: "Positivity"
             graph_testrate: "Test Rate"
             positivity_with_rainfall: "Positivity with Rainfall"
             positivity_by_year: "Positivity cases by year"
           }
           _(graphLinks).map (linkText, linkUrl) ->
             "<a class='mdl-navigation__link graph__link' id = '#{linkUrl}' href='#graphs/#{linkUrl}' data-title='Graphs'>#{linkText}</a>"
           .join ""
      }		   
		</div>
		<a class='mdl-navigation__link drawer__link' href='#reports/maps' id='maps' data-title='Maps' data-category='menuLink'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>map</i>
		  <span class='link-title'>Maps</span>
	    </a>
		<a class='mdl-navigation__link drawer__link' href='#reports/export' id='export' data-title='Data Export' data-category='menuLink'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>cloud_download</i>
		  <span class='link-title'>Data Export</span>
	    </a>		
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='setting-main' data-title='Settings' data-category='menuHeader'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>settings</i>
		Settings
	    </a>
		<div class='m-l-20 dropdown' id='drawer-settings'>
        #{
             settingLinks = {
               setting_theme: "Color Theme"
               setting_general: "General"
               setting_language: "Language"
               setting_misc: "Miscellaneous"
             }
             _(settingLinks).map (linkText, linkUrl) ->
               "<a class='mdl-navigation__link setting__link' id = '#{linkUrl}' href='#settings/#{linkUrl}' data-title='Settings'>#{linkText}</a>"
             .join ""
        }
		</div>
		<a class='mdl-navigation__link drawer__subtitle' href='#' id='admin-main' data-title='Admin' data-category='menuHeader'>  
		  <i class='mdl-color-text--blue-grey-400 material-icons'>build</i>
		Admin
	    </a>
		<div class='m-l-20 dropdown' id='drawer-admin'>
        #{
             adminLinks = {
               facilities: "Facilities"
               questions: "Question Sets"
               rainfall_station: "Rainfall Station"
               regions_districts_shehias: "Regions, Districts & Shehias"
               shehias_irs: "Shehias received IRS"
               high_risk: "Shehias high risk"
               users: "Users"
             }
             _(adminLinks).map (linkText, linkUrl) ->
               "<a class='mdl-navigation__link admin__link' id = '#{linkUrl}' href='#admin/#{linkUrl}' data-title='Admin'>#{linkText}</a>"
             .join ""
        }				   			
        </div>	
     </nav>
   "
module.exports = MenuView
