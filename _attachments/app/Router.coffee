_ = require 'underscore'

$ = jQuery = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
PouchDB = require 'pouchdb'
Cookie = require 'js-cookie'

DashboardView = require './views/DashboardView'
UsersView = require './views/UsersView'
DateSelectorView = require './views/DateSelectorView'
IssuesView = require './views/IssuesView'
Case = require './models/Case'
CaseView = require './views/CaseView'
DataExportView = require './views/DataExportView'
MapView = require './views/MapView'
FacilityHierarchyView = require './views/FacilityHierarchyView'
RainfallStationView = require './views/RainfallStationView'
GeoHierarchyView = require './views/GeoHierarchyView'
EditDataView = require './views/EditDataView'

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
  "Periodtrends": require './views/PeriodtrendsView'
  "Rainfallreport": require './views/RainfallreportView'
  "Usersreport": require './views/UsersreportView'
  "Weeklyreports": require './views/WeeklyreportsView'
  "Weeklysummary": require './views/WeeklysummaryView'
}

activityViews = {
  "Issues": require './views/IssuesView'
}

class Router extends Backbone.Router
  # caches views
  views: {}

  # holds option pairs for more complex URLs like for reports
  reportViewOptions: {}
  activityViewOptions: {}
  
  routes:
    "admin/users": "users"
    "admin/facilities": "FacilityHierarchy"
    "admin/rainfall_station": "rainfallStation"
    "admin/geo_hierarchy": "geoHierarchy"
    "admin/edit_data/:document_type": "editData"
    "dashboard/:startDate/:endDate": "dashboard"
    "dashboard": "dashboard"
    "export": "dataExport"
    "maps": "maps"
    "maps/*options": "maps"
    "reports": "reports"
    "reports/*options": "reports"  ##reports/type/Analysis/startDate/2016-01-01/endDate/2016-01-01 ->
    "show/case/:caseID": "showCase"
    "show/case/:caseID/:docID": "showCase"
    "new/issue": "newIssue"
    "show/issue/:issueID": "showIssue"
    "activities": "activities"
    "activities/*options": "activities" 
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
    
    defaultOptions = @setDefaultOptions()

    # Set the default option if it isn't already set
    _(defaultOptions).each (defaultValue, option) =>
      @reportViewOptions[option] = @reportViewOptions[option] or defaultValue
    type = @reportViewOptions["type"]
    console.log("type: " + type)
    @views[type] = new reportViews[type]() unless @views[type]
    @views[type].setElement "#content"
    @views[type].render()
    @reportType = 'reports'
    @showDateFilter(@reportViewOptions.startDate, @reportViewOptions.endDate, @views[type], @reportType)


  # Needs to refactor later to keep it DRY
  activities: (options) =>
    @activityViewOptions =[]
    options = _(options?.split(/\//)).map (option) -> unescape(option)

    _.each options, (option,index) =>
      @activityViewOptions[option] = options[index+1] unless index % 2

    defaultOptions = @setDefaultOptions()

    _(defaultOptions).each (defaultValue, option) =>
      @activityViewOptions[option] = @activityViewOptions[option] or defaultValue

    type = @activityViewOptions["type"]
    @views[type] = new activityViews[type]() unless @views[type]
    @views[type].setElement "#content"
    @views[type].render()
    @reportType = 'activities'
    @showDateFilter(@activityViewOptions.startDate,@activityViewOptions.endDate, @views[type], @reportType)

  showCase: (caseID, docID) ->
#    @userLoggedIn
#      success: ->
        Coconut.caseView ?= new CaseView()
        Coconut.caseView.case = new Case
          caseID: caseID
        Coconut.caseView.case.fetch
          success: ->
            Coconut.caseView.render(docID)

  dashboard: (startDate,endDate) =>
    @dashboardView = new DashboardView() unless @dashboardView
    [startDate,endDate] = @setStartEndDateIfMissing(startDate,endDate)
    @.navigate "dashboard/#{startDate}/#{endDate}"

    # Set the element that the view will render
   # @dashboardView.setElement "#content"
    @dashboardView.startDate = startDate
    @dashboardView.endDate = endDate
    @dashboardView.render()

  dataExport: ->
    [startDate,endDate] = @setStartEndDateIfMissing(startDate,endDate)
    @dataExportView = new DataExportView unless @dataExportView
    @dataExportView.startDate = startDate
    @dataExportView.endDate = endDate
    @dataExportView.render()
    @reportType = 'export'
    @showDateFilter(@dataExportView.startDate,@dataExportView.endDate, @dataExportView, @reportType)

  maps: (options) ->

    options = _(options?.split(/\//)).map (option) -> unescape(option)
    # remove type option
    options.splice(0,2)
    _.each options, (option,index) =>
      @reportViewOptions[option] = options[index+1] unless index % 2
    
    defaultOptions = @setDefaultOptions()

    # Set the default option if it isn't already set
    _(defaultOptions).each (defaultValue, option) =>
      @reportViewOptions[option] = @reportViewOptions[option] or defaultValue

    @mapView = new MapView unless @mapView
    @mapView.render()
    @reportType = 'maps'
    @showDateFilter(@reportViewOptions.startDate, @reportViewOptions.endDate, @mapView, @reportType)

  FacilityHierarchy: =>
    @facilityHierarchyView = new FacilityHierarchyView unless @facilityHierarchyView
    @facilityHierarchyView.render()

  rainfallStation: =>
    @rainfallStationView = new RainfallStationView unless @rainfallStationView
    @rainfallStationView.render()

  geoHierarchy: =>
    @geoHierarchyView = new GeoHierarchyView unless @geoHierarchyView
    @geoHierarchyView.render()

  shehiasHighRisk: =>
    @shehiasHighRiskView = new ShehiasHighRiskView unless  @shehiasHighRiskView
     @shehiasHighRiskView.render()

  editData: (document_id) ->
#    @adminLoggedIn
#      success: ->
        console.log(document_id)
        Coconut.EditDataView = new EditDataView() unless Coconut.EditDataView
        Coconut.database.get document_id
        .catch (error) -> 
          Coconut.EditDataView.document = {
            _id: document_id
          }
          Coconut.EditDataView.render()
        .then (result) ->
          Coconut.EditDataView.document = result
          Coconut.EditDataView.render()

#      error: ->
#        alert("#{User.currentUser} is not an admin")

  users: () =>
    @usersView = new UsersView() unless @usersView
    @usersView.render()

  newIssue: (issueID) ->
#    @userLoggedIn
#      success: ->
        Coconut.issueView ?= new IssueView()
        Coconut.issueView.issue = null
        Coconut.issueView.render()

  showIssue: (issueID) ->
    @userLoggedIn
      success: ->
        Coconut.issueView ?= new IssueView()
        Coconut.database.get issueID
        .catch (error) -> console.error error
        .then (result) ->
          Coconut.issueView.issue = result
          Coconut.issueView.render()

  userLoggedIn: (callback) ->
    true
#    User.isAuthenticated
#      success: (user) ->
#        callback.success(user)
#      error: ->
#        Coconut.loginView.callback = callback
#        Coconut.loginView.render()

  setStartEndDateIfMissing: (startDate,endDate) =>
    startDate = startDate || moment().subtract("7","days").format("YYYY-MM-DD")
    endDate = endDate || moment().format("YYYY-MM-DD")
    [startDate, endDate]

  showDateFilter: (startDate, endDate, reportView, reportType) ->
    Coconut.dateSelectorView = new DateSelectorView() unless Coconut.dateSelectorView
    Coconut.dateSelectorView.setElement "#dateSelector"
    Coconut.dateSelectorView.startDate = startDate
    Coconut.dateSelectorView.endDate = endDate
    Coconut.dateSelectorView.reportView = reportView
    Coconut.dateSelectorView.reportType = reportType
    Coconut.dateSelectorView.render()

  setDefaultOptions: () ->
    return {
       type: "Analysis"
       startDate:  moment().subtract("7","days").format("YYYY-MM-DD")
       endDate: moment().format("YYYY-MM-DD")
       aggregationLevel: "District"
       mostSpecificLocationSelected: "ALL"
    }
	  
module.exports = Router
