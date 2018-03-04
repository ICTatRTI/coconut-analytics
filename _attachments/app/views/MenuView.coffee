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
    "click header.coconut-drawer-header": "goHome"

  goHome: (e) ->
    Coconut.router.navigate("#dashboard", {trigger: true})

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
    $(".mdl-layout__drawer").removeClass("is-visible")
    $(".mdl-layout__obfuscator").removeClass("is-visible")
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
          <div class='f-left m-l-20'><img src=\"#{Coconut.logoUrl}\" id='wusclogo_sm'></div>
          <div class='mdl-layout-title' id='drawer-title'>#{Coconut.config.appName}</div>
        </div>
      </header>
      <div id='container'>
      <nav class='coconut_navigation mdl-navigation'>
        <a class='mdl-navigation__link drawer__subtitle' id='dashboard' data-title='Dashboard' data-category='menuLink' href='#dashboard'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-view-dashboard mdi-24px'></i>Dashboard</a>
        <span class='mdl-navigation__link drawer__subtitle' id='report-main' data-title='Reports' data-category='menuHeader'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-file-document mdi-24px'></i>
        Reports</span>
        <div class='m-l-20 dropdown' id='drawer-reports'>
          #{
          reportLinks = {
            attendance: "Attendance Summary"
            spotchecks: "Spot Checks Status"
            followups: "Follow up Reports"
            weeklyreports: "Weekly School Reports"
          }
          _(reportLinks).map (linkText, linkUrl) ->
            "<a class='mdl-navigation__link report__link' id = '#{linkUrl}' href='#reports/type/#{linkUrl}' data-title='Reports'>#{linkText}</a>"
          .join ""
          }
        </div>
        <span class='mdl-navigation__link drawer__subtitle' id='activity-main' data-title='Activities' data-category='menuHeader'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-ticket mdi-24px'></i>
            Activities
        </span>
        <div class='m-l-20 dropdown' id='drawer-activities'>
        #{
             activityLinks = {
               Issues: "Issues"
               FutureFeature: "Future Features"
             }
             _(activityLinks).map (linkText, linkUrl) ->
               "<a class='mdl-navigation__link activity__link' id = '#{linkUrl}' href='#activities/type/#{linkUrl}' data-title='Activities'>#{linkText}</a>"
             .join ""
        }
        </div>
        <span class='mdl-navigation__link drawer__subtitle' id='graphs-main' data-title='Graphs' data-category='menuHeader'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-file-chart mdi-24px'></i>
            Graphs
        </span>
        <div class='m-l-20 dropdown' id='drawer-graphs'>
          #{
           graphLinks = {
             IncidentsGraph: "Sample Graph 1"
             PositiveCasesGraph: "Sample Graph 2"
             AttendanceGraph: "Sample Graph 3"
             TestRateGraph: "Sample Graph4"
           }
           _(graphLinks).map (linkText, linkUrl) ->
             "<a class='mdl-navigation__link graph__link' id = '#{linkUrl}' href='#graphs/type/#{linkUrl}' data-title='Graphs'>#{linkText}</a>"
           .join ""
          }
        </div>
        <a class='mdl-navigation__link drawer__link' href='#maps' id='maps' data-title='Maps' data-category='menuLink'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-map mdi-24px'></i>
            <span class='link-title'>Maps</span>
        </a>
        <a class='mdl-navigation__link drawer__link' href='#export' id='export' data-title='Data Export' data-category='menuLink'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-file-export mdi-24px'></i>
            <span class='link-title'>Data Export</span>
        </a>
<!--
        <span class='mdl-navigation__link drawer__subtitle' id='setting-main' data-title='Settings' data-category='menuHeader'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-settings mdi-24px'>settings</i>
            User Settings
        </span>
        <div class='m-l-20 dropdown' id='drawer-settings'>
          #{
             settingLinks = {
               setting_theme: "User Profile"
               setting_general: "General"
             }
             _(settingLinks).map (linkText, linkUrl) ->
               "<a class='mdl-navigation__link setting__link' id = '#{linkUrl}' href='#settings/#{linkUrl}' data-title='Settings'>#{linkText}</a>"
             .join ""
           }
        </div>
-->
        <span class='mdl-navigation__link drawer__subtitle' id='admin-main' data-title='Admin' data-category='menuHeader'>
          <i class='mdl-color-text--blue-grey-400 mdi mdi-wrench mdi-24px'></i>
           Admin
        </span>
        <div class='m-l-20 dropdown' id='drawer-admin'>
        #{
          adminLinks = {
            #dhis2: "DHIS2"
            #facilities: "Facilities"
            #rainfall_station: "Rainfall Station"
            #geo_hierarchy: "Regions, Districts & Shehias"
            #shehias_received_irs: "Shehias Received IRS"
            schools: "Schools"
            system_settings: "System Settings"
            users: "Users"
          }
          _(adminLinks).map (linkText, linkUrl) ->
            "<a class='mdl-navigation__link admin__link' id = '#{linkUrl}' href='#admin/#{linkUrl}' data-title='Admin'>#{linkText}</a>"
          .join ""
        }
        </div>
      </nav>
    </div>
    "

module.exports = MenuView
