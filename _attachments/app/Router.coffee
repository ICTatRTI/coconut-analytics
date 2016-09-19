_ = require 'underscore'

$ = jQuery = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
global.moment = require 'moment'
PouchDB = require 'pouchdb'

DashboardView = require './views/DashboardView'
MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'
UsersView = require './views/UsersView'
DateSelectorView = require './views/DateSelectorView'
IssuesView = require './views/IssuesView'
IssueView = require './views/IssueView'
global.Case = require './models/Case'
CaseView = require './views/CaseView'
DataExportView = require './views/DataExportView'
MapView = require './views/MapView'
FacilityHierarchyView = require './views/FacilityHierarchyView'
RainfallStationView = require './views/RainfallStationView'
GeoHierarchyView = require './views/GeoHierarchyView'
SystemSettingsView = require './views/SystemSettingsView'
LoginView = require './views/LoginView'
ChangePasswordView = require './views/ChangePasswordView'
User = require './models/User'
Dialog = require './views/Dialog'
MessagingView = require './views/MessagingView'
global.HTMLHelpers = require './HTMLHelpers'

# This allows us to create new instances of these dynamically based on the URL, for example:
# /reports/Analysis will lead to:
# new reportViews[type]() or new reportView["Analysis"]()
#

#AnalysisView = require './views/AnalysisView'

reportViews = {
  "Analysis": require './views/AnalysisView'
  "Casefollowup": require './views/CaseFollowupView'
  "Compareweekly": require './views/CompareWeeklyView'
  "Epidemicthreshold": require './views/EpidemicThresholdView'
  "Systemerrors": require './views/SystemErrorsView'
  "Incidentsgraph": require './views/IncidentsGraphView'
  "Periodtrends": require './views/PeriodTrendsView'
  "Rainfallreport": require './views/RainfallReportView'
  "Usersreport": require './views/UsersReportView'
  "Weeklyreports": require './views/WeeklyReportsView'
  "Weeklysummary": require './views/WeeklySummaryView'
}

activityViews = {
  Issues: require './views/IssuesView'
  Messaging: require './views/MessagingView'
}

graphsViews = {
  IncidentsGraph: require './views/IncidentsGraphView'
  PositiveCasesGraph: require './views/PositiveCasesGraphView'
  YearlyTrends: require './views/YearlyTrendsView'
  AttendanceGraph: require './views/AttendanceGraphView'
  TestRateGraph: require './views/TestRateGraphView'
  TimeToNotify: require './views/TimeToNotifyGraphView'
  TimeToComplete: require './views/TimeToCompleteGraphView'
}
  
class Router extends Backbone.Router
  # caches views
  views: {}
  
  # holds option pairs for more complex URLs like for reports
  reportViewOptions: {}
  activityViewOptions: {}
  dateSelectorOptions: {}
  
  routes:
    "": "dashboard"
    "login": "login"
    "logout": "logout"
    "reset_password/:token": "reset_password"
    "reset_password": "reset_password"
    "admin/system_settings": "systemSettings"
    "admin/users": "users"
    "admin/facilities": "FacilityHierarchy"
    "admin/rainfall_station": "rainfallStation"
    "admin/geo_hierarchy": "geoHierarchy"
    "dashboard/:startDate/:endDate": "dashboard"
    "dashboard": "dashboard"
    "export": "dataExport"
    "export/*options": "dataExport"
    "maps": "maps"
    "maps/*options": "maps"
    "graphs/*options": "graphs"
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

  login: ->
    Coconut.loginView = new LoginView() if !Coconut.loginView
    Coconut.loginView.render()
    @listenTo(Coconut.loginView, "success", ->
      Coconut.router.navigate("#dashboard", {trigger: true})
    )
    
  logout: ->
    User.logout()
    $("span#username").html ""
    @login()

  loginFailed: ->
    Coconut.router.navigate("#login", {trigger: true})

  reset_password: (token) ->
    $("#login-backgrd").show()
    if token
      #TODO: Need to search for document with the specified token.
      #check if token exist.
      # User.checkToken
      #if found()
        #username should come from the doc with the specified token. Temporarily set to 'test'
        username = 'test'
        Coconut.ChangePasswordView = new ChangePasswordView() if !Coconut.ChangePasswordView
        Coconut.ChangePasswordView.render(username)
        @listenTo(Coconut.ChangePasswordView, "success", ->
          Dialog.createDialogWrap()
          Dialog.confirm("Password reset successful...", "Success",["Ok"])
          dialog.addEventListener 'close', ->
            Coconut.router.navigate("#login", {trigger: true})
        )
    else  
       Dialog.createDialogWrap()
       Dialog.confirm("Invalid Token or Token expired.", "Error",["Ok"])
       dialog.addEventListener 'close', ->
         Coconut.router.navigate("#login", {trigger: true})
       
  notAdmin: ->
    if !(Coconut.currentUser)
      @loginFailed()
    else
      Dialog.confirm("You do not have admin privileges", "Warning",["Ok"]) if(Coconut.currentUser)
    
  reports: (options) =>
    @userLoggedIn
      success:  =>
        # Allows us to get name/value pairs from URL
        options = _(options?.split(/\//)).map (option) -> unescape(option)

        _.each options, (option,index) =>
          @reportViewOptions[option] = options[index+1] unless index % 2
    
        defaultOptions = @setDefaultOptions()

        # Set the default option if it isn't already set
        _(defaultOptions).each (defaultValue, option) =>
          @reportViewOptions[option] = @reportViewOptions[option] or defaultValue
        type = @reportViewOptions["type"]
        @views[type] = new reportViews[type]() unless @views[type]
        @views[type].setElement "#content"
        @views[type].render()
        @reportType = 'reports'
        @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @views[type], @reportType)
      error: =>
        @loginFailed()

  # Needs to refactor later to keep it DRY
  activities: (options) =>
    @userLoggedIn
      success:  =>
        options = _(options?.split(/\//)).map (option) -> unescape(option)

        _.each options, (option,index) =>
          @reportViewOptions[option] = options[index+1] unless index % 2

        defaultOptions = @setDefaultOptions()

        _(defaultOptions).each (defaultValue, option) =>
          @reportViewOptions[option] = @reportViewOptions[option] or defaultValue

        type = @reportViewOptions["type"]
        @views[type] = new activityViews[type]() unless @views[type]
        @views[type].setElement "#content"
        @views[type].render()
        @reportType = 'activities'
        @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @views[type], @reportType)
      error: =>
        @loginFailed()
        
  graphs: (options) =>
    @userLoggedIn
      success:  =>
        options = _(options?.split(/\//)).map (option) -> unescape(option)

        _.each options, (option,index) =>
          @reportViewOptions[option] = options[index+1] unless index % 2

        defaultOptions = @setDefaultOptions()

        _(defaultOptions).each (defaultValue, option) =>
          @reportViewOptions[option] = @reportViewOptions[option] or defaultValue

        type = @reportViewOptions["type"]
        @views[type] = new graphsViews[type]() unless @views[type]
        @views[type].setElement "#content"
        @views[type].render()
        @reportType = 'graphs'
        @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @views[type], @reportType)
      error: =>
        @loginFailed()
        
        
  showCase: (caseID, docID) ->
    @userLoggedIn
      success: ->
        Coconut.caseView ?= new CaseView()
        Coconut.caseView.case = new Case
          caseID: caseID
        Coconut.caseView.case.fetch
          success: ->
            Coconut.caseView.render(docID)
          error: (error) ->
            alert "Could not display case: #{error}"

  dashboard: (startDate,endDate) =>
    @userLoggedIn
      success:  =>
        @showDashboard(startDate,endDate)
      error: =>
        @loginFailed()
  

  showDashboard: (startDate,endDate) =>
    Coconut.dashboardView = new DashboardView() unless Coconut.dashboardView
    [startDate,endDate] = @setStartEndDateIfMissing()
    @.navigate "#dashboard/#{startDate}/#{endDate}"
    Coconut.router.reportViewOptions['startDate'] = startDate
    Coconut.router.reportViewOptions['endDate'] = endDate
    @reportType = 'dashboard'
    Coconut.dashboardView.render()
    @showDateFilter(startDate, endDate, Coconut.dashboardView, @reportType)
    
    
  dataExport: ->
    @userLoggedIn
      success:  =>
        [startDate,endDate] = @setStartEndDateIfMissing()
        @dataExportView = new DataExportView unless @dataExportView
        @dataExportView.startDate = startDate
        @dataExportView.endDate = endDate
        @dataExportView.render()
        @reportType = 'export'
        @showDateFilter(@dataExportView.startDate,@dataExportView.endDate, @dataExportView, @reportType)
      error: =>
        @loginFailed()

  maps: (options) ->
    @userLoggedIn
      success:  =>
        options = _(options?.split(/\//)).map (option) -> unescape(option)
        # remove type option
        options.splice(0,2)
        _.each options, (option,index) =>
          @reportViewOptions[option] = options[index+1] unless index % 2
    
        defaultOptions = @setDefaultOptions()

        # Set the default option if it isn't already set
        _(defaultOptions).each (defaultValue, option) =>
          @reportViewOptions[option] = @reportViewOptions[option] or defaultValue
        type = @reportViewOptions["type"]
        @mapView = new MapView unless @mapView
        @mapView.render()
        @reportType = 'maps'
        @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @mapView, @reportType)
      error: =>
        @loginFailed()

  FacilityHierarchy: =>
    @adminLoggedIn
      success: ->
        @facilityHierarchyView = new FacilityHierarchyView unless @facilityHierarchyView
        @facilityHierarchyView.render()
      error: =>
        @notAdmin()
        

  rainfallStation: =>
    @adminLoggedIn
      success: ->
        @rainfallStationView = new RainfallStationView unless @rainfallStationView
        @rainfallStationView.render()
      error: =>
        @notAdmin()

  geoHierarchy: =>
    @adminLoggedIn
      success: ->
        @geoHierarchyView = new GeoHierarchyView unless @geoHierarchyView
        @geoHierarchyView.render()
      error: =>
        @notAdmin()

  shehiasHighRisk: =>
    @adminLoggedIn
      success: ->
        @shehiasHighRiskView = new ShehiasHighRiskView unless  @shehiasHighRiskView
        @shehiasHighRiskView.render()
      error: =>
        @notAdmin()

  users: () =>
    @adminLoggedIn
      success: ->
        @usersView = new UsersView() unless @usersView
        @usersView.render()
      error: =>
        @notAdmin()

  systemSettings: () =>
    @adminLoggedIn
      success: ->
        @systemSettingsView = new SystemSettingsView unless @systemSettingsView
        @systemSettingsView.render()
      error: =>
        @notAdmin()

  newIssue: (issueID) ->
    @userLoggedIn
      success: ->
        Coconut.issueView ?= new IssueView()
        Coconut.issueView.issue = null
        Coconut.issueView.render()

  showIssue: (issueID) ->
    @userLoggedIn
      success: ->
        Coconut.issueView ?= new IssueView()
        Coconut.database.get issueID
        .catch (error) -> 
          console.error error
        .then (result) ->
          if(result)
            Coconut.issueView.issue = result
            Coconut.issueView.render()
          else
            Dialog.createDialogWrap()
            Dialog.confirm("Issue not found: <br />#{issueID}", "Database Error",["Ok"])

  userLoggedIn: (callback) =>
    User.isAuthenticated
      success: (user) =>
        if Coconut.currentUser.isAdmin() then $("#admin-main").show() else $("#admin-main").hide()
        callback.success(user)
      error: (error) ->
        callback.error()

  adminLoggedIn: (callback) ->
    @userLoggedIn
      success: (user) ->
        if user.isAdmin()
          callback.success(user)
        else
          $("#drawer-admin, #admin-main").hide()
          $("#content").html "
             <dialog id='dialog'>
               <div id='dialogContent'> </div>
             </dialog>
          "
          Dialog.confirm("You do not have admin privileges", "Warning",["Ok"])
      error: ->
        callback.error()

  setStartEndDateIfMissing: (startDate,endDate) =>
    startDate = Coconut.router.reportViewOptions.startDate || moment().subtract("7","days").format("YYYY-MM-DD")
    endDate = Coconut.router.reportViewOptions.endDate || moment().format("YYYY-MM-DD")
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
