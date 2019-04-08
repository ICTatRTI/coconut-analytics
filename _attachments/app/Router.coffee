_ = require 'underscore'

$ = jQuery = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
global.moment = require 'moment'
PouchDB = require 'pouchdb'

MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'
UsersView = require './views/UsersView'
SchoolsView = require './views/SchoolsView'
SystemSettingsView = require './views/SystemSettingsView'
LoginView = require './views/LoginView'
ChangePasswdView = require './views/ChangePasswdView'
User = require './models/User'
Dialog = require './views/Dialog'

DashboardView = require './views/DashboardView'
#AttendanceView = require './views/AttendanceView'
AggregatingAverageView = require './views/AggregatingAverageView'
EnrollmentView = require './views/EnrollmentView'
ExportView = require './views/ExportView'
NewLearnersView = require './views/NewLearnersView'
NewLearnerView = require './views/NewLearnerView'


# This allows us to create new instances of these dynamically based on the URL, for example:
# reports/Attendance will lead to:
# new reportViews[type]() or new reportView["Attendance"]()
#

reportViews = {
  "progress": require './views/ProgressView'
  "attendance": require './views/AggregatingAverageView'
  "enrollments": require './views/EnrollmentsView'
  "users": require './views/UsersReportView'
#  "SpotCheck": require './views/SpotCheckView'
}


class Router extends Backbone.Router
  # caches views
  views: {}
  reportViewOptions: {}

  initialize: (appView) ->
    @appView = appView
    
  # holds option pairs for more complex URLs like for reports
  noLogin = ["login", "logout", "reset_password"]
  execute: (callback, args, name) ->
    if noLogin.indexOf(name) is -1
      @userLoggedIn
        success:  =>
          #args.push(@parseQueryString(args.pop())) if args[0] isnt null
          callback.apply(this, args) if (callback)
        error: =>
          @loginFailed()
    else
      callback.apply(this, args) if callback

  routes:
    "": "dashboard"
    "dashboard": "dashboard"
    "attendance": "attendance"
    "performance": "performance"
    "enrollment/:enrollment_id": "enrollment"
    "export": "export"
    "login": "login"
    "logout": "logout"
    "reports": "reports"
    "reports/*options": "reports"  ##reports/type/Attendance/startDate/2016-01-01/endDate/2016-01-01
    "reset_password/:token": "reset_password"
    "reset_password": "reset_password"
    "change_password": "change_password"
    "admin/system_settings": "systemSettings"
    "admin/users": "users"
    "admin/schools": "schools"
    "admin/new_learner/:personId": "new_learner"
    "admin/new_learners/:region": "new_learners"
    "admin/new_learners": "new_learners"
    "*noMatch": "noMatch"

  noMatch: =>
    console.error "Invalid URL, no matching route: "
    $("#content").html "Page not found."

  dashboard: =>
    Coconut.router.reportViewOptions.aggregationLevel="Kakuma"
    @dashboardView = @dashboardView or new DashboardView()
    @dashboardView.setElement("#content")
    @dashboardView.render()

  attendance: =>
    @aggregatingAverageView = @aggregatingAverageView or new AggregatingAverageView()
    @aggregatingAverageView.setElement("#content")
    @aggregatingAverageView.title = "Attendance"
    @aggregatingAverageView.query = "attendanceByYearTermRegionSchoolClassStreamLearner"
    @aggregatingAverageView.render()

  performance: =>
    @aggregatingAverageView = @aggregatingAverageView or new AggregatingAverageView()
    @aggregatingAverageView.setElement("#content")
    @aggregatingAverageView.title = "Performance"
    @aggregatingAverageView.query = "performanceByYearTermRegionSchoolClassStreamLearner"
    @aggregatingAverageView.render()

  enrollment: (enrollmentId) =>
    @enrollmentView = @enrollmentView or new EnrollmentView()
    @enrollmentView.setElement("#content")
    @enrollmentView.enrollmentId = enrollmentId
    @enrollmentView.render()

  export: =>
    @exportView = @exportView or new ExportView()
    @exportView.setElement("#content")
    @exportView.render()

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
    @views[type] = new reportViews[type]() unless @views[type]
    @views[type].setElement "#content"
    #@views[type].render()
    @appView.showView(@views[type])
    @reportType = 'reports'


  notAdmin: ->
    if !(Coconut.currentUser)
      @loginFailed()
    else
      Dialog.confirm("You do not have admin privileges", "Warning",["Ok"]) if(Coconut.currentUser)

  users: () =>
    @adminLoggedIn
      success: =>
        @usersView = new UsersView() unless @usersView
        @usersView.render()
      error: =>
        @notAdmin()

  schools: () =>
    @adminLoggedIn
      success: =>
        @schoolsView = new SchoolsView() unless @schoolsView
        @schoolsView.render()
      error: =>
        @notAdmin()

  new_learners: (region) =>
    @adminLoggedIn
      success: =>
        @newLearnersView ?= new NewLearnersView()
        @newLearnersView.region = region
        @newLearnersView.setElement("#content")
        @newLearnersView.render()
      error: =>
        @notAdmin()

  new_learner: (personId) =>
    @adminLoggedIn
      success: =>
        @newLearnerView ?= new NewLearnerView()
        @newLearnerView.setElement("#content")
        @newLearnerView.personId = personId
        @newLearnerView.render()
      error: =>
        @notAdmin()

  systemSettings: () =>
    @adminLoggedIn
      success: =>
        @systemSettingsView = new SystemSettingsView unless @systemSettingsView
        @systemSettingsView.render()
      error: =>
        @notAdmin()
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

  setDefaultOptions: () ->
    return {
       type: "Attendance"
       startDate: ['2017','1','Kakuma']
       endDate: ['2017','1','Kakuma']
    }

module.exports = Router
