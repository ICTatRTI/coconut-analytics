_ = require 'underscore'

$ = jQuery = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
global.moment = require 'moment'

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
Dhis2View = require './views/Dhis2View'
SystemSettingsView = require './views/SystemSettingsView'
LoginView = require './views/LoginView'
ChangePasswdView = require './views/ChangePasswdView'
User = require './models/User'
Dialog = require './views/Dialog'
MessagingView = require './views/MessagingView'
FindCaseView = require './views/FindCaseView'
Graphs = require './models/Graphs'
GraphView = require './views/GraphView'
IndividualsView = require './views/IndividualsView'
CasesView = require './views/CasesView'


# This allows us to create new instances of these dynamically based on the URL, for example:
# /reports/Analysis will lead to:
# new reportViews[type]() or new reportView["Analysis"]()
#

#AnalysisView = require './views/AnalysisView'

reportViews = {
  "Analysis": require './views/AnalysisView'
  "Casefollowup": require './views/CaseFollowupView'
  "Individualclassification": require './views/IndividualClassificationView'
  "Fociclassification": require './views/FociClassificationView'
  "Compareweekly": require './views/CompareWeeklyView'
  "Epidemicthreshold": require './views/EpidemicThresholdView'
  "Systemerrors": require './views/SystemErrorsView'
  "Incidentsgraph": require './views/IncidentsGraphView'
  "Periodtrends": require './views/PeriodTrendsView'
  "Rainfallreport": require './views/RainfallReportView'
  "Usersreport": require './views/UsersReportView'
  "WeeklyMeetingReport": require './views/WeeklyMeetingReportView'
  "WeeklyFacilityReports": require './views/WeeklyFacilityReportsView'
  "CleaningReports": require './views/CleaningReportsView'
  "Weeklysummary": require './views/WeeklySummaryView'
}

activityViews = {
  Issues: require './views/IssuesView'
  Messaging: require './views/MessagingView'
}

class Router extends Backbone.Router
  # caches views
  views: {}

  # holds option pairs for more complex URLs like for reports
  reportViewOptions: {}
  activityViewOptions: {}
  dateSelectorOptions: {}
  noLogin = ["login", "logout", "reset_password"]
  execute: (callback, args, name) ->
    if noLogin.indexOf(name) is -1
      @userLoggedIn
        success:  =>
          args.push(@parseQueryString(args.pop())) if args[0] isnt null
          callback.apply(this, args) if (callback)
        error: =>
          @loginFailed()
    else
      callback.apply(this, args) if callback

  routes:
    "": "dashboard"
    "login": "login"
    "logout": "logout"
    "reset_password/:token": "reset_password"
    "reset_password": "reset_password"
    "change_password": "change_password"
    "admin/dhis2": "dhis2"
    "admin/system_settings": "systemSettings"
    "admin/users": "users"
    "admin/facilities": "FacilityHierarchy"
    "admin/rainfall_station": "rainfallStation"
    "admin/geo_hierarchy": "geoHierarchy"
    "dashboard": "dashboard"
    "dashboard/*options": "dashboard"
    "export": "dataExport"
    "export/*options": "dataExport"
    "maps": "maps"
    "maps/*options": "maps"
    "graph/*options": "graph"
    "individuals": "individuals"
    "individuals/*options": "individuals"
    "cases": "cases"
    "cases/*options": "cases"
    "reports": "reports"
    "reports/*options": "reports"  ##reports/type/Analysis/startDate/2016-01-01/endDate/2016-01-01 ->
    "find/case": "findCase"
    "find/case/:caseID": "findCase"
    "show/case/:caseID": "showCase"
    "show/cases/:caseID": "showCase"
    "show/case/:caseID/:docID": "showCase"
    "delete/result/:resultId": "deleteResult"
    "new/issue": "newIssue"
    "show/issue/:issueID": "showIssue"
    "activities": "activities"
    "activities/*options": "activities"
    "*noMatch": "noMatch"

  findCase: (caseId) =>
    Coconut.findCaseView or= new FindCaseView()
    Coconut.findCaseView.setElement $("#content")
    Coconut.findCaseView.caseId = caseId
    Coconut.findCaseView.render()

  deleteResult: (resultId) =>
    if confirm "Are you sure you want to delete #{resultId}"
      Coconut.databaste.get(resultId)
      .catch (error) => alert error
      .then (result) =>
        Coconut.destroy(result)
        .catch (error) => alert error
        .then =>
          alert("#{resultId} deleted")
          Coconut.router.navigate("#", {trigger:true})

  initialize: (appView) ->
    @appView = appView


  noMatch: =>
    console.error "Invalid URL, no matching route: "
    $("#content").html "Page not found."

  login: ->
    Coconut.loginView = new LoginView() if !Coconut.loginView
    Coconut.loginView.render()
    @listenTo(Coconut.loginView, "success", ->
      HTMLHelpers.showBackground('show')
      Coconut.router.navigate("#dashboard", {trigger: true})
    )

  logout: ->
    User.logout()
    $("span#username").html ""
    @login()

  loginFailed: ->
    Coconut.router.navigate("#login", {trigger: true})

  change_password: ->
    Coconut.changePasswdView = new ChangePasswdView() if !Coconut.changePasswdView
    Coconut.changePasswdView.render()
    @listenTo(Coconut.changePasswdView, "success", ->
      Dialog.createDialogWrap()
      Dialog.confirm("Password has been updated...", 'Password Reset',['Ok'])
      dialog.addEventListener 'close', ->
        Coconut.router.navigate("#dashboard", {trigger: true})
    )

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
    # Allows us to get name/value pairs from URL
    options = _(options?.split(/\//)).map (option) -> unescape(option)

    _.each options, (option,index) =>
      @reportViewOptions[option] = options[index+1] unless index % 2

    defaultOptions = @setDefaultOptions()

    # Set the default option if it isn't already set
    _(defaultOptions).each (defaultValue, option) =>
      @reportViewOptions[option] = @reportViewOptions[option] or defaultValue
    type = @reportViewOptions["type"]
    document.title = 'Coconut Surveillance - Reports - #{type}'
    @views[type] = new reportViews[type]() unless @views[type]
    @views[type].setElement "#content"
    #@views[type].render()
    @appView.showView(@views[type])
    @reportType = 'reports'
    @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @views[type], @reportType)


  # Needs to refactor later to keep it DRY
  activities: (options) =>
    options = _(options?.split(/\//)).map (option) -> unescape(option)

    _.each options, (option,index) =>
      @reportViewOptions[option] = options[index+1] unless index % 2

    defaultOptions = @setDefaultOptions()

    _(defaultOptions).each (defaultValue, option) =>
      @reportViewOptions[option] = @reportViewOptions[option] or defaultValue

    type = @reportViewOptions["type"]
    @views[type] = new activityViews[type]() unless @views[type]
    #@views[type].render()
    @appView.showView(@views[type])
    @reportType = 'activities'
    @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @views[type], @reportType)

  graph: (optionString) ->
    document.title = 'Coconut Surveillance - Graph'
    Coconut.graphView or= new GraphView()
    Coconut.graphView.options = @parseOptionsString(optionString)
    Coconut.graphView.render()

  individuals: (optionString) ->
    document.title = 'Coconut Surveillance - Individuals'
    Coconut.individualsView or= new IndividualsView()
    Coconut.individualsView.options = @parseOptionsString(optionString)
    Coconut.individualsView.render()

  cases: (optionString) ->
    document.title = 'Coconut Surveillance - Cases'
    Coconut.casesView or= new CasesView()
    Coconut.casesView.options = @parseOptionsString(optionString)
    Coconut.casesView.render()

  showCase: (caseID, docID) ->
    document.title = "Coconut Surveillance - Case #{caseID}"
    Coconut.caseView ?= new CaseView()
    Coconut.caseView.case = new Case
      caseID: caseID
    Coconut.caseView.case.fetch
      success: ->
        Coconut.caseView.render(docID)
      error: (error) ->
        alert "Could not display case: #{error}"

  dashboard: (options) =>
    document.title = 'Coconut Surveillance - Dashboard'
    Coconut.dashboardView or= new DashboardView()
    options = @parseOptionsString(options)

    Coconut.dashboardView.startDate = options?.startDate or Coconut.dashboardView.startDate or @defaultStartDate()
    Coconut.dashboardView.endDate = options?.endDate or Coconut.dashboardView.endDate or @defaultEndDate()
    Coconut.dashboardView.administrativeLevel = options?.administrativeLevel or Coconut.dashboardView.administrativeLevel or "NATIONAL"
    # Just maps different terms to the ones used by dashboard
    Coconut.dashboardView.administrativeLevel = {
      "FACILITY": "HEALTH FACILITIES"
      "DISTRICT": "DISTRICTS"
      "SHEHIA": "SHEHIAS"
    }[Coconut.dashboardView.administrativeLevel.toUpperCase()] or Coconut.dashboardView.administrativeLevel
    Coconut.dashboardView.administrativeName = options?.administrativeName or Coconut.dashboardView.administrativeName or "ZANZIBAR"

    console.log Coconut.dashboardView

    Coconut.dashboardView.render()

  dataExport: =>
    [startDate,endDate] = @setStartEndDateIfMissing()
    @dataExportView = new DataExportView unless @dataExportView
    @dataExportView.startDate = startDate
    @dataExportView.endDate = endDate
    #@dataExportView.render()
    @appView.showView(@dataExportView)
    @reportType = 'export'
    @showDateFilter(@dataExportView.startDate,@dataExportView.endDate, @dataExportView, @reportType)


  maps: (options) =>
    document.title = 'Coconut Surveillance - Maps'
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

    @mapView.setElement "#content"
    #@mapView.render()
    @appView.showView(@mapView)
    @reportType = 'maps'

    dateSelectorView = new DateSelectorView()
    dateSelectorView.setElement('#date-selector')
    dateSelectorView.reportType = 'maps'
    dateSelectorView.render()
    @showDateFilter(Coconut.router.reportViewOptions.startDate, Coconut.router.reportViewOptions.endDate, @mapView, @reportType)

    HTMLHelpers.ChangeTitle("Maps")

  FacilityHierarchy: =>
    @adminLoggedIn
      success: =>
        @facilityHierarchyView = new FacilityHierarchyView unless @facilityHierarchyView
        #@facilityHierarchyView.render()
        @appView.showView(@facilityHierarchyView)
      error: =>
        @notAdmin()


  rainfallStation: =>
    @adminLoggedIn
      success: =>
        @rainfallStationView = new RainfallStationView unless @rainfallStationView
        #@rainfallStationView.render()
        @appView.showView(@rainfallStationView)
      error: =>
        @notAdmin()

  geoHierarchy: =>
    @adminLoggedIn
      success: =>
        @geoHierarchyView = new GeoHierarchyView unless @geoHierarchyView
        #@geoHierarchyView.render()
        @appView.showView(@geoHierarchyView)
      error: =>
        @notAdmin()

  shehiasHighRisk: =>
    @adminLoggedIn
      success: =>
        @shehiasHighRiskView = new ShehiasHighRiskView unless  @shehiasHighRiskView
        #@shehiasHighRiskView.render()
        @appView.showView(@shehiasHighRiskView)
      error: =>
        @notAdmin()

  users: () =>
    @adminLoggedIn
      success: =>
        @usersView = new UsersView() unless @usersView
        #@usersView.render()
        @appView.showView(@usersView)
      error: =>
        @notAdmin()

  dhis2: () =>
    @adminLoggedIn
      success: =>
        @dhis2View = new Dhis2View() unless @dhis2View
        #@dhis2View.render()
        @appView.showView(@dhis2View)
      error: =>
        @notAdmin()

  systemSettings: () =>
    @adminLoggedIn
      success: =>
        @systemSettingsView = new SystemSettingsView unless @systemSettingsView
        #@systemSettingsView.render()
        @appView.showView(@systemSettingsView)
      error: =>
        @notAdmin()

  newIssue: (issueID) =>
    Coconut.issueView ?= new IssueView()
    Coconut.issueView.issue = null
    #Coconut.issueView.render()
    @appView.showView(Coconut.issueView)

  showIssue: (issueID) =>
    Coconut.issueView ?= new IssueView()
    Coconut.database.get issueID
    .catch (error) ->
      console.error error
    .then (result) =>
      if(result)
        Coconut.issueView.issue = result
        #Coconut.issueView.render()
        @appView.showView(Coconut.issueView)
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
      success: (user) =>
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
      error: =>
        callback.error()

  defaultStartDate: =>
    moment().subtract(1,'week').startOf('isoWeek').format("YYYY-MM-DD")

  defaultEndDate: =>
    moment().subtract(1,'week').endOf('isoWeek').format("YYYY-MM-DD")

  setStartEndDateIfMissing: (startDate,endDate) =>
    startDate = Coconut.router.reportViewOptions.startDate || @defaultStartDate()
    endDate = Coconut.router.reportViewOptions.endDate || @defaultEndDate()
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
       startDate:  @defaultStartDate()
       endDate: @defaultEndDate()
       aggregationLevel: "District"
       mostSpecificLocationSelected: "ALL"
    }

  parseOptionsString: (optionString) ->
    # Split the string, unescape it, then loop it and put it in a hash
    options = {}
    optionsArray = _(optionString?.split(/\//)).map (option) -> unescape(option)
    for option, index in optionsArray
      options[option] = optionsArray[index+1] unless index % 2

    return options

  parseQueryString: (queryString)->
    params = {}
    if(queryString)
      _.each(
        _.map(decodeURI(queryString).split(/&/g),(el,i) ->
          aux = el.split('=')
          o = {}
          if(aux.length >= 1)
            val = undefined
            if(aux.length == 2)
              val = aux[1]
            o[aux[0]] = val
          return o
        ),
        (o) ->
          _.extend(params,o)
      )
    return params


module.exports = Router
