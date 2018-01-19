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
ChangePasswordView = require './views/ChangePasswordView'
User = require './models/User'
Dialog = require './views/Dialog'

DashboardView = require './views/DashboardView'
ExportView = require './views/ExportView'

# This allows us to create new instances of these dynamically based on the URL, for example:
# reports/Analysis will lead to:
# new reportViews[type]() or new reportView["Analysis"]()
#


class Router extends Backbone.Router
  # caches views
  views: {}

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
    "export": "export"
    "login": "login"
    "logout": "logout"
    "reset_password/:token": "reset_password"
    "reset_password": "reset_password"
    "admin/system_settings": "systemSettings"
    "admin/users": "users"
    "admin/schools": "schools"
    "*noMatch": "noMatch"

  dashboard: =>
    @dashboardView = @dashboardView or new DashboardView()
    @dashboardView.setElement("#content")
    @dashboardView.render()

  export: =>
    @exportView = @exportView or new ExportView()
    @exportView.setElement("#content")
    @exportView.render()

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

module.exports = Router
