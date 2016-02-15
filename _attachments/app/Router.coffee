_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Moment = require 'moment'
PouchDB = require 'pouchdb'
Cookie = require 'js-cookie'

DashboardView = require './views/DashboardView'
UsersView = require './views/UsersView'

class Router extends Backbone.Router
  routes:
    "dashboard/:startDate/:endDate": "dashboard"
    "dashboard": "dashboard"
    "admin/users": "users"

  dashboard: (startDate,endDate) =>
    @dashboardView = new DashboardView() unless @dashboardView
    unless startDate and endDate
      # set a default date if none is passed in
      startDate = startDate or Moment().subtract("7","days").format("YYYY-MM-DD")
      endDate = endDate or Moment().format("YYYY-MM-DD")
      # Update the URL without re-executing the route
      @.navigate "dashboard/#{startDate}/#{endDate}"

    # Set the element that the view will render
    @dashboardView.setElement "#content"
    @dashboardView.startDate = startDate
    @dashboardView.endDate = endDate
    @dashboardView.render()

  users: () =>
    @usersView = new UsersView() unless @usersView
    @usersView.render()

module.exports = Router
