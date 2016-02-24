_ = require 'underscore'
$ = jQuery = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Moment = require 'moment'
PouchDB = require 'pouchdb'
Cookie = require 'js-cookie'

DashboardView = require './views/DashboardView'
UsersView = require './views/UsersView'
DateSelectorView = require './views/DateSelectorView'

# This allows us to create new instances of these dynamically based on the URL, for example:
# /reports/Analysis will lead to:
# new reportViews[type]() or new reportView["Analysis"]()
#

#AnalysisView = require './views/AnalysisView'

reportViews = {
  "Analysis": require './views/AnalysisView'
  "Casefollowup": require './views/CaseFollowupView'
  "Compareweekly": require './views/CompareweeklyView'
  "Epidemicthreshold": require './views/EpidemicthresholdView'
  "Systemerrors": require './views/SystemerrorsView'
  "Incidentsgraph": require './views/IncidentsgraphView'
  "Periodsummary": require './views/PeriodsummaryView'
  "Pilotnotification": require './views/PilotnotificationView'
  "Rainfallreport": require './views/RainfallreportView'
  "Usersreport": require './views/UsersreportView'
  "Weeklyreports": require './views/WeeklyreportsView'
  "Weeklysummary": require './views/WeeklysummaryView'
}

class Router extends Backbone.Router
  # caches views
  views: {}

  # holds option pairs for more complex URLs like for reports
  reportViewOptions: {}

  routes:
    "dashboard/:startDate/:endDate": "dashboard"
    "dashboard": "dashboard"
    "admin/users": "users"
    "reports": "reports"
    "reports/*options": "reports"  ##reports/type/Analysis/startDate/2016-01-01/endDate/2016-01-01 ->
    "*noMatch": "noMatch"

  noMatch: =>
    console.error "Invalid URL, no matching route: "
    $("#content").html "Page not found."

  reports: (options) =>
    @reportViewOptions = []
    # Allows us to get name/value pairs from URL
    options = _(options?.split(/\//)).map (option) -> unescape(option)

    _.each options, (option,index) =>
      @reportViewOptions[option] = options[index+1] unless index % 2
    
    defaultOptions = {
      type: "Analysis"
      startDate:  Moment().subtract("7","days").format("YYYY-MM-DD")
      endDate: Moment().format("YYYY-MM-DD")
      aggregationLevel: "District"
      mostSpecificLocationSelected: "ALL"
    }

    # Set the default option if it isn't already set
    _(defaultOptions).each (defaultValue, option) =>
      @reportViewOptions[option] = @reportViewOptions[option] or defaultValue
	
    type = @reportViewOptions["type"]

    @views[type] = new reportViews[type]() unless @views[type]
    @views[type].setElement "#content"
    @views[type].render()
    @showDateFilter(@reportViewOptions.startDate,@reportViewOptions.endDate)
	
  dashboard: (startDate,endDate) =>
    @dashboardView = new DashboardView() unless @dashboardView
    [startDate,endDate] = @setStartEndDateIfMissing(startDate,endDate)
    @.navigate "dashboard/#{startDate}/#{endDate}"

    # Set the element that the view will render
   # @dashboardView.setElement "#content"
    @dashboardView.startDate = startDate
    @dashboardView.endDate = endDate
    @dashboardView.render()

  users: () =>
    @usersView = new UsersView() unless @usersView
    @usersView.render()

  setStartEndDateIfMissing: (startDate,endDate) =>
    startDate = startDate || Moment().subtract("7","days").format("YYYY-MM-DD")
    endDate = endDate || Moment().format("YYYY-MM-DD")
    [startDate, endDate]

  showDateFilter: (startDate, endDate) ->
    Coconut.dateSelectorView = new DateSelectorView() unless Coconut.dateSelectorView
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.startDate = startDate
    Coconut.dateSelectorView.endDate = endDate
    Coconut.dateSelectorView.render()
	
module.exports = Router
