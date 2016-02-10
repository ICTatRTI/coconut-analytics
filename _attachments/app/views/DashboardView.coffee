_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

DataTables = require 'datatables'

class DashboardView extends Backbone.View

  render: =>
    @$el.html "
      <h2>Dashboard</h2>
      Start Date: #{@startDate}
      End Date: #{@endDate}
    "

module.exports = DashboardView
