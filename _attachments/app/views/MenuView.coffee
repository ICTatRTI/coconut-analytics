_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
User = require '../models/User'

class MenuView extends Backbone.View
  el: ".coconut-drawer"
  
  events:
    "click a.mdl-navigation__link": "changeStatus"
    "click span.drawer__subtitle": "toggleDropdownMenu"

  toggleDropdownMenu: (e) =>
    e.preventDefault
    $target = $(e.target)
    hidden = $target.next("div.dropdown").is(":hidden")
    $("div.dropdown").slideUp()
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
        title = title + ": " + subtitle
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
        <a class='mdl-navigation__link drawer__subtitle' id='dashboard' data-title='Dashboard' data-category='menuLink' href='#dashboard'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>dashboard</i>Dashboard</a>
        <span class='mdl-navigation__link drawer__subtitle' id='report-main' data-title='Reports' data-category='menuHeader'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>description</i>
        Reports</span>
        <div class='m-l-20 dropdown' id='drawer-reports'>
        #{
          reportLinks = {
            Analysis: "Analysis"
            Casefollowup: "Case Followup Status"
            Compareweekly: "Compare Weekly Facility Reports with Case Followups"
            Epidemicthreshold: "Epidemic Thresholds"
            Systemerrors: "Errors Detected by System"
            Incidentsgraph: "Incidents Graph - cases by week"
            Periodtrends: "Period Trends compared to previous 3 weeks"
            Rainfallreport: "Rainfall Submission"
            Usersreport: "Users Report - how fast are followups occuring"
            Weeklyreports: "Weekly Facility Reports"
            Weeklysummary: "Weekly Trends compared to previous 3 weeks"
          }
          _(reportLinks).map (linkText, linkUrl) ->
            "<a class='mdl-navigation__link report__link' id = '#{linkUrl}' href='#reports/type/#{linkUrl}' data-title='Reports'>#{linkText}</a>"
          .join ""
        }
        </div>
        <span class='mdl-navigation__link drawer__subtitle' id='activity-main' data-title='Activities' data-category='menuHeader'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>local_activity</i>
            Activities
        </span>
        <div class='m-l-20 dropdown' id='drawer-activities'>
        #{
             activityLinks = {
               Issues: "Issues"
               Todos: "To Do"
               Sms: "Send SMS to users"
             }
             _(activityLinks).map (linkText, linkUrl) ->
               "<a class='mdl-navigation__link activity__link' id = '#{linkUrl}' href='#activities/type/#{linkUrl}' data-title='Activities'>#{linkText}</a>"
             .join ""
        }
        </div>
        <span class='mdl-navigation__link drawer__subtitle' id='graphs-main' data-title='Graphs' data-category='menuHeader'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>assessment</i>
            Graphs
        </span>
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
        <a class='mdl-navigation__link drawer__link' href='#maps' id='maps' data-title='Maps' data-category='menuLink'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>map</i>
            <span class='link-title'>Maps</span>
        </a>
        <a class='mdl-navigation__link drawer__link' href='#export' id='export' data-title='Data Export' data-category='menuLink'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>cloud_download</i>
            <span class='link-title'>Data Export</span>
        </a>		
        <span class='mdl-navigation__link drawer__subtitle' id='setting-main' data-title='Settings' data-category='menuHeader'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>settings</i>
            Settings
        </span>
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
        <span class='mdl-navigation__link drawer__subtitle' id='admin-main' data-title='Admin' data-category='menuHeader'>  
          <i class='mdl-color-text--blue-grey-400 material-icons'>build</i>
           Admin
        </span>
        <div class='m-l-20 dropdown' id='drawer-admin'>
        #{
          adminLinks = {
            facilities: "Facilities"
            rainfall_station: "Rainfall Station"
            geo_hierarchy: "Regions, Districts & Shehias"
            "edit_data/shehias_received_irs": "Shehias received IRS"
            "edit_data/shehias_high_risk": "Shehias high risk"
            users: "Users"
          }
          _(adminLinks).map (linkText, linkUrl) ->
            "<a class='mdl-navigation__link admin__link' id = '#{linkUrl}' href='#admin/#{linkUrl}' data-title='Admin'>#{linkText}</a>"
          .join ""
        }
        </div>	
      </nav>
    "
    Coconut.router.userLoggedIn
      success: =>
        if Coconut.currentUser.isAdmin() then $("#admin-main").show() else $("#admin-main").hide()

module.exports = MenuView